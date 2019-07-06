# config
MAKEFLAGS += --warn-undefined-variables
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := all
.DELETE_ON_ERROR:
.SUFFIXES:
.SECONDARY:

# Run the build:
# make TERMS=<term-file> T=<threshold> clean

# robot with minimize
ROBOT_MIN := java -Xmx8G -jar util/robot/robot_min.jar
ROBOT := java -Xmx8G -jar util/robot/robot.jar

OBO = http:\/\/purl\.obolibrary\.org\/obo\/

# Seed set of classes for extracting from ChEBI
TERMS := $(or $(TERMS),epitopes.txt)
# Threshold for minimizing
T := $(or $(T),10)

# Set of NCBITaxon terms
NCBITAXON_TERMS = build/ncbitaxon-terms.txt
# Map of epitopes to organisms 
EPITOPE_ORGS = epitope_organisms.csv

# Important directories
QRS = util/queries
RES = build/results
SCRP = ./util/scripts

# Pull annotations from ChEBI and merge them in

# -------------------- OVERVIEW -------------------- #

# 1 Retrieve the ChEBI module
# 2 Remove unnecessary entities
# 3 Add 'other' nodes
# 4 Create the compound hierarchy
# 5 Compile components and rehome 'other' entities
# 6 Add counts to labels
# 7 Validate
# 8 Clean up and convert to OWL

all: chebi-minimal.owl

clean: chebi-minimal.owl
	@rm -rf build && \
	echo "Build complete!"

.PHONY: build
build:
	@echo "Starting build..." && \
	mkdir -p build && mkdir -p build/results

# -------------------- STEP 1: Get the module -------------------- #

.PRECIOUS: build/chebi.owl
build/chebi.owl:
	@echo "Retreiving ChEBI" && \
	curl -Lk http://purl.obolibrary.org/obo/chebi.owl > $@

.INTERMEDIATE: build/annotations.ttl
build/annotations.ttl: build/chebi.owl
	$(ROBOT) filter --input $< --select "annotation-properties annotations" --output $@

CURATED_UPDATES := $(foreach U,$(shell find $(QRS)/curated -name \*.ru -print), --update $(U))

# Extract our subset from ChEBI
# Annotate labels of important terms with >>
# Perform manually-curated clean-up of roles
.INTERMEDIATE: build/chebi-module.ttl
build/chebi-module.ttl: build/chebi.owl $(TERMS) | build
	@echo "Extracting $(word 2,$^) from $<" && \
	$(ROBOT) extract --input $< --term-file $(word 2,$^)\
	 --method BOT query --update $(QRS)/add-label-prefix.ru \
	remove --term CHEBI:53000 --output $@

# Use a template to add in new nodes
.INTERMEDIATE: build/chebi-curated.ttl
build/chebi-curated.ttl: build/chebi-module.ttl src/curated.csv
	$(ROBOT) template --input $< --merge-before --template $(word 2,$^) --output $@

# Run updates to remove and replace roles
.INTERMEDIATE: build/chebi-updated.ttl
build/chebi-updated.ttl: build/chebi-curated.ttl
	@echo "Running manually-curated updates on $<" && \
	$(ROBOT) query --input $< --update $(QRS)/add-roles-to-children.ru\
	 --update $(QRS)/curated/remove-roles.ru\
	 --update $(QRS)/curated/replace-drug-roles.ru\
	 --update $(QRS)/curated/replace-app-roles.ru\
	 --update $(QRS)/add-children-roles.ru  --output $@

# Remove manually-curated nodes
.INTERMEDIATE: build/chebi-removed.ttl
build/chebi-removed.ttl: build/chebi-updated.ttl
	@echo "Removing extra nodes from $<" && \
	$(ROBOT) remove --input $< --term-file src/manual-remove.txt \
	remove --term-file src/manual-remove-descendants.txt --select "descendants" \
	remove --term-file src/manual-remove-plus-descendants.txt\
	 --select "self descendants" --output $@

# Separate the roles into own file (with role logic)
# Remove logic for any non-roles without >>
.INTERMEDIATE: build/chebi-roles.ttl
build/chebi-roles.ttl: build/chebi-removed.ttl
	@echo "Separating role hierarchy into $@" && \
	$(ROBOT) filter --input $< --term CHEBI:50906\
	 --select "self descendants annotations" --trim false \
	query --update $(QRS)/trim-roles.ru --output $@

# Keep chemical entities in their own file
.INTERMEDIATE: build/chebi-chemicals.ttl
build/chebi-chemicals.ttl: build/chebi-removed.ttl
	@echo "Separating chemical entity hierarchy into $@" && \
	$(ROBOT_MIN) remove --input $< --term CHEBI:50906\
	 --select "self descendants" --output $@

# ------------------- STEP 2: Remove unnecessary entities ------------------- #

# Get the entities that we need
.INTERMEDIATE: $(RES)/filter-necessary.tsv
$(RES)/filter-necessary.tsv: build/chebi-chemicals.ttl | build
	@echo "Finding important classes, see $@" && \
	$(ROBOT_MIN) query --input $< --query $(QRS)/filter-necessary.rq $@ && \
	sed -i '' '1d;s/<//g;s/>//g' $@

# Get the gropus that we can remove
.INTERMEDIATE: $(RES)/remove-groups.tsv
$(RES)/remove-groups.tsv: build/chebi-chemicals.ttl | build
	@echo "Finding unnecessary groups, see $@" && \
	$(ROBOT_MIN) query --input $< --query $(QRS)/remove-groups.rq $@ && \
	sed -i '' '1d;s/<//g;s/>//g' $@

# Make a precious term-file
.INTERMEDIATE: build/precious.txt
build/precious.txt: src/precious.txt $(TERMS) 
	@cat $^ > $@

.INTERMEDIATE: $(RES)/remove-molecular-entities.txt
$(RES)/remove-molecular-entities.txt: build/chebi-chemicals.ttl
	@echo "Finding nodes to remove" && \
	$(SCRP)/find_molecular_entities.py $< $@

# Filter for the entities we need
# Remove the unnecessary groups
# Remove extra classes that we don't like
# Minimize based on threshold
.INTERMEDIATE: build/chebi-minimized.ttl
build/chebi-minimized.ttl: build/chebi-chemicals.ttl $(RES)/filter-necessary.tsv \
$(RES)/remove-groups.tsv build/precious.txt $(RES)/remove-molecular-entities.txt
	@echo "Removing unnecessary terms from $<" && \
	$(ROBOT_MIN) filter --input $< --term-file $(word 2,$^) --term CHEBI:33659 \
	 --select "self annotations" --trim true --preserve-structure true \
	remove --term-file $(word 3,$^) --trim true --preserve-structure true \
	remove --term CHEBI:88184 --term CHEBI:72695 --term CHEBI:33285\
	 --term CHEBI:33561 --term CHEBI:23367 --trim true --preserve-structure true \
	remove --term-file $(word 5,$^) --trim true --preserve-structure true \
	minimize --threshold $(T) --precious $(word 4,$^) reduce --output $@

# -------------------- STEP 3: Add 'other' nodes -------------------- #

# Get a list of the 'other' nodes
.INTERMEDIATE: $(RES)/other-nodes.tsv
$(RES)/other-nodes.tsv: build/chebi-minimized.ttl
	@echo "Getting 'other' nodes, see $@" && \
	$(ROBOT) query --input $< --query $(QRS)/get-other-nodes.rq $@ && \
	sed -i '' '1d;s/$(OBO)/		obo:/g;s/<//g;s/>//g' $@

# Create a SPARQL update to add the nodes
.INTERMEDIATE: build/add-other-nodes.ru
build/add-other-nodes.ru: $(RES)/other-nodes.tsv
	@cat $(QRS)/add-other-nodes-top.txt $< $(QRS)/add-other-nodes-bot.txt > $@

# Create a SPARQL update to move children to the 'other' nodes
.INTERMEDIATE: build/move-others.ru
build/move-others.ru: $(RES)/other-nodes.tsv
	@cat $(QRS)/move-others-top.txt $< $(QRS)/move-others-bot.txt > $@

# Run updates and reason to maybe assert extra parents, 
# allowing us to remove classes from the 'other' nodes
.INTERMEDIATE: build/chebi-other.ttl
build/chebi-other.ttl: build/chebi-minimized.ttl build/add-other-nodes.ru \
build/move-others.ru
	@echo "Running the SPARQL updates for 'other' nodes on $<" && \
	$(ROBOT) query --input $< --update $(word 2,$^) \
	query --update $(word 3,$^) reason \
	query --update $(QRS)/clean-other-nodes.ru \
	query --update $(QRS)/add-other-parents.ru --output $@

# -------------------- STEP 4: Create compounds -------------------- #

# Create the compound hierarchy
.INTERMEDIATE: build/compounds.ttl
build/compounds.ttl: build/chebi-roles.ttl
	@echo "Creating compound hierarchy from $<" && \
	$(ROBOT) query --input $< --query $(QRS)/construct-compounds.rq $@

# -------------------- STEP 5: Compile -------------------- #

# Merge everything together
# Remove assertions of owl:Thing
# Reduce and reason
.INTERMEDIATE: build/chebi-merged.ttl
build/chebi-merged.ttl: build/chebi-roles.ttl build/chebi-other.ttl \
build/compounds.ttl build/precious.txt
	@echo "Merging: $^" && \
	$(ROBOT_MIN) merge --input $< --input $(word 2,$^)\
	 --input $(word 3,$^) --input src/logic.ttl \
	reduce reason --output $@

# Rehome children of 'other molecular entity' based on their chemical formula
# If there is a carbon in the formula, it belongs in 'organic molecular entity'
.INTERMEDIATE: build/chebi-rehomed.ttl
build/chebi-rehomed.ttl: build/chebi-merged.ttl
	@echo "Rehoming 'other molecular entity' children" && \
	$(SCRP)/rehome_other_entities.py $< $@

# Recreate the inorganics based on element
.INTERMEDIATE: build/chebi-elements.ttl
build/chebi-elements.ttl: build/chebi-rehomed.ttl
	@echo "Organizing elements of $<" && \
	$(SCRP)/add_elements.py $< $@

.INTERMEDIATE: build/chebi-cleaned.ttl
build/chebi-cleaned.ttl: build/chebi-elements.ttl
	@echo "Cleaning $<" && \
	$(ROBOT) remove --input $< --term CHEBI:33521 \
	query --update $(QRS)/curated/carb-derivative-update.ru \
	query --update $(QRS)/curated/clean-galacto-and-gluco.ru \
	query --update $(QRS)/curated/merge-carb-and-derivative.ru \
	query --update $(QRS)/clean-childless.ru \
	query --update $(QRS)/remove-other-parents.ru \
	query --update $(QRS)/add-other-logic.ru \
	query --update $(QRS)/curated/organic-children.ru \
	remove --term CHEBI:24431 --term CHEBI:50906 --term CHEBI:50906-compound \
     --term CHEBI:23367-other --select "self descendants" --select "complement"\
	 --select "classes" --trim true \
	remove --term-file src/remove-after-others.txt reduce --output $@ 

# -------------------- STEP 6: Add source hierarchy -------------------- #

build/ncbitaxon.owl:
	curl -Lk -o $@ http://purl.obolibrary.org/obo/ncbitaxon.owl

.INTERMEDIATE: build/ontie-module.ttl
build/ontie-module.ttl: $(EPITOPE_ORGS)
	@$(SCRP)/add_iedb_organisms.py $< $(NCBITAXON_TERMS) $@

# Create a subset with just the required terms
.INTERMEDIATE: build/ncbitaxon-module.ttl
build/ncbitaxon-module.ttl: build/ncbitaxon.owl build/ontie-module.ttl $(NCBITAXON_TERMS)
	@echo "Generating $@" && \
	$(ROBOT) merge --input $< --input $(word 2,$^) \
	extract --intermediates minimal --method MIREOT\
	 --upper-term NCBITaxon:1 --lower-terms $(word 3,$^) --output $@

# Mirror the hierachy with "product of"
.INTERMEDIATE: build/ncbitaxon-sources.ttl
build/ncbitaxon-sources.ttl: build/ncbitaxon-module.ttl
	@echo "Generating 'product of' hierarchy" && \
	$(ROBOT) query --input $< --query $(QRS)/construct-orgs.rq $@

# Merge NCBITaxon module and 'product of' hierarchy into ChEBI
.INTERMEDIATE: build/chebi-organisms.ttl
build/chebi-organisms.ttl: build/chebi-cleaned.ttl build/ncbitaxon-sources.ttl \
build/ncbitaxon-module.ttl
	@echo "Merging $^" && \
	$(ROBOT) merge --input $< --input $(word 2,$^) --input $(word 3,$^) --output $@

# add the 'produced by' axioms and reason to generate full hierarchy
.INTERMEDIATE: build/chebi-sources.ttl
build/chebi-sources.ttl: build/chebi-organisms.ttl $(EPITOPE_ORGS)
	@$(SCRP)/add_source_organisms.py $^ $@ && \
	$(ROBOT) reason --input $@ --output $@

# -------------------- STEP 7: Add counts -------------------- #

# Get the references
.INTERMEDIATE: build/chebi-references.ttl
build/chebi-references.ttl: 
	python $(SCRP)/add_references.py build/chebi-cleaned.ttl $@

# Get the counts of important (>>) subclasses
.INTERMEDIATE: $(RES)/child-counts.tsv
$(RES)/child-counts.tsv: build/chebi-references.ttl
	@echo "Getting child counts, see $@" && \
	$(ROBOT) query --input $< --query $(QRS)/child-counts.rq $@

# Add the counts to the labels
.INTERMEDIATE: build/chebi-minimal.ttl
build/chebi-minimal.ttl: build/chebi-references.ttl $(RES)/child-counts.tsv
	@echo "Adding child counts to labels" && \
	$(SCRP)/add_count.py $^ $@

# -------------------- STEP 8: Validate -------------------- #

# Ensure that all of our input terms are in the final ontology
.PHONY: validate
validate: $(TERMS) build/chebi-minimal.ttl
	@echo "Validating that all terms from $< are in $(word 2,$^)" && \
	$(SCRP)/validate.py $^

# -------------------- STEP 9: Clean up -------------------- #

# Potentially annotate in the future here
# Remove everything that is not under 'chemical entity', 'compound', or 'role'
# Run update to remove compounds AND others with no children (post reasoning)
# Run update to remove the 'other' alternative hierarchy and add disjoint axioms
.PRECIOUS: chebi-minimal.owl
chebi-minimal.owl: build/chebi-minimal.ttl build/annotations.ttl | validate
	@echo "Merging $^" && \
	$(ROBOT) merge --input $< --input $(word 2,$^) --output $@ \
	&& echo "Created $@"


# -------------------- Reports -------------------- #

chebi-minimal.ttl: 
	$(ROBOT) convert --input chebi-minimal.owl --output $@

# requires epitope_table.csv
drugs: drug_details.csv
drug_details.csv: chebi-minimal.ttl
	$(SCRP)/generate_spreadsheet.py CHEBI:23888-compound chebi-minimal.ttl epitope_table.csv $@

apps: app_details.csv
app_details.csv: chebi-minimal.ttl
	$(SCRP)/generate_spreadsheet.py CHEBI:33232-compound chebi-minimal.ttl epitope_table.csv $@ CHEBI:23888-compound

carbs: carb_details.csv
carb_details.csv: chebi-minimal.ttl
	$(SCRP)/generate_spreadsheet.py CHEBI:78616 chebi-minimal.ttl epitope_table.csv $@
