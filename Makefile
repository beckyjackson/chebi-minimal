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
SOURCE_ORGS = build/ncbitaxon-terms.txt
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

all: minimal products

minimal: chebi-minimal.owl
products: chebi-product-of.owl

clean: chebi-minimal.owl
	rm -rf build

.PHONY: build
build:
	mkdir -p build && mkdir -p build/results

# -------------------- STEP 1: Get the module -------------------- #

.PRECIOUS: build/chebi.owl
build/chebi.owl:
	curl -Lk http://purl.obolibrary.org/obo/chebi.owl > $@

.INTERMEDIATE: build/annotations.ttl
build/annotations.ttl: build/chebi.owl
	$(ROBOT) filter \
	 --input $< \
	 --select "annotation-properties annotations" \
	 --output $@

CURATED_UPDATES := $(foreach U,$(shell find $(QRS)/curated -name \*.ru -print), --update $(U))

# Extract our subset from ChEBI
# Annotate labels of important terms with >>
# Perform manually-curated clean-up of roles
.INTERMEDIATE: build/chebi-module.ttl
build/chebi-module.ttl: build/chebi.owl $(TERMS) | build
	$(ROBOT) extract \
	 --input $< \
	 --term-file $(word 2,$^) \
	 --method BOT \
	query \
	 --update $(QRS)/add-label-prefix.ru \
	remove \
	 --term CHEBI:53000 \
	 --output $@

# Use a template to add in new nodes
.INTERMEDIATE: build/chebi-curated.ttl
build/chebi-curated.ttl: build/chebi-module.ttl src/curated.csv
	$(ROBOT) template \
	 --input $< \
	 --merge-before \
	 --template $(word 2,$^) \
	 --output $@

# Run updates to remove and replace roles
.INTERMEDIATE: build/chebi-updated.ttl
build/chebi-updated.ttl: build/chebi-curated.ttl
	$(ROBOT) query \
	 --input $< \
	 --update $(QRS)/curated/remove-roles.ru \
	 --update $(QRS)/curated/replace-drug-roles.ru \
	 --update $(QRS)/curated/replace-app-roles.ru \
	 --update $(QRS)/inherit-roles.ru \
	 --output $@

# Remove manually-curated nodes
.INTERMEDIATE: build/chebi-removed.ttl
build/chebi-removed.ttl: build/chebi-updated.ttl
	$(ROBOT) remove \
	 --input $< \
	 --term-file src/manual-remove.txt \
	remove \
	 --term-file src/manual-remove-descendants.txt \
	 --select "descendants" \
	remove \
	 --term-file src/manual-remove-plus-descendants.txt \
	 --select "self descendants" \
	reduce \
	 --output $@

# Separate the roles into own file (with role logic)
# Remove logic for any non-roles without >>
.INTERMEDIATE: build/chebi-roles.ttl
build/chebi-roles.ttl: build/chebi-removed.ttl
	$(ROBOT) filter \
	 --input $< \
	 --term CHEBI:50906 \
	 --select "self descendants annotations" \
	 --trim false \
	query \
	 --update $(QRS)/trim-roles.ru \
	 --output $@

# Keep chemical entities in their own file
.INTERMEDIATE: build/chebi-chemicals.ttl
build/chebi-chemicals.ttl: build/chebi-removed.ttl
	$(ROBOT_MIN) remove \
	 --input $< \
	 --term CHEBI:50906 \
	 --select "self descendants" \
	 --output $@

# ------------------- STEP 2: Remove unnecessary entities ------------------- #

# Get the entities that we need
.INTERMEDIATE: $(RES)/filter-necessary.tsv
$(RES)/filter-necessary.tsv: build/chebi-chemicals.ttl | build
	$(ROBOT_MIN) query \
	 --input $< \
	 --query $(QRS)/filter-necessary.rq $@ && \
	sed -i '' '1d;s/<//g;s/>//g' $@

# Get the gropus that we can remove
.INTERMEDIATE: $(RES)/remove-groups.tsv
$(RES)/remove-groups.tsv: build/chebi-chemicals.ttl | build
	$(ROBOT_MIN) query \
	 --input $< \
	 --query $(QRS)/remove-groups.rq $@ && \
	sed -i '' '1d;s/<//g;s/>//g' $@

# Make a precious term-file
.INTERMEDIATE: build/precious.txt
build/precious.txt: src/precious.txt $(TERMS) 
	cat $^ > $@

.INTERMEDIATE: $(RES)/remove-molecular-entities.txt
$(RES)/remove-molecular-entities.txt: build/chebi-chemicals.ttl
	$(SCRP)/find_molecular_entities.py $< $@

# Filter for the entities we need
# Remove the unnecessary groups
# Remove extra classes that we don't like
# Minimize based on threshold
.INTERMEDIATE: build/chebi-minimized.ttl
build/chebi-minimized.ttl: build/chebi-chemicals.ttl $(RES)/filter-necessary.tsv \
$(RES)/remove-groups.tsv build/precious.txt $(RES)/remove-molecular-entities.txt
	$(ROBOT_MIN) filter \
	 --input $< \
	 --term-file $(word 2,$^) \
	 --term CHEBI:33659 \
	 --select "self annotations" \
	 --trim true \
	remove \
	 --term-file $(word 3,$^) \
	remove \
	 --term CHEBI:88184 \
	 --term CHEBI:72695 \
	 --term CHEBI:33285 \
	 --term CHEBI:33561 \
	 --term CHEBI:23367 \
	remove \
	 --term-file $(word 5,$^) \
	minimize \
	 --threshold $(T) \
	 --precious $(word 4,$^) \
	reduce \
	 --output $@

# -------------------- STEP 3: Add 'other' nodes -------------------- #

# Get a list of the 'other' nodes
.INTERMEDIATE: $(RES)/other-nodes.tsv
$(RES)/other-nodes.tsv: build/chebi-minimized.ttl
	$(ROBOT) query --input $< --query $(QRS)/get-other-nodes.rq $@ && \
	sed -i '' '1d;s/$(OBO)/		obo:/g;s/<//g;s/>//g' $@

# Create a SPARQL update to add the nodes
.INTERMEDIATE: build/add-other-nodes.ru
build/add-other-nodes.ru: $(RES)/other-nodes.tsv
	cat $(QRS)/add-other-nodes-top.txt $< $(QRS)/add-other-nodes-bot.txt > $@

# Create a SPARQL update to move children to the 'other' nodes
.INTERMEDIATE: build/move-others.ru
build/move-others.ru: $(RES)/other-nodes.tsv
	cat $(QRS)/move-others-top.txt $< $(QRS)/move-others-bot.txt > $@

# Run updates and reason to maybe assert extra parents, 
# allowing us to remove classes from the 'other' nodes
.INTERMEDIATE: build/chebi-other.ttl
build/chebi-other.ttl: build/chebi-minimized.ttl build/add-other-nodes.ru \
build/move-others.ru
	$(ROBOT) query \
	 --input $< \
	 --update $(word 2,$^) \
	query \
	 --update $(word 3,$^) \
	reason \
	query \
	 --update $(QRS)/clean-other-nodes.ru \
	query \
	 --update $(QRS)/add-other-parents.ru \
	 --output $@

# -------------------- STEP 4: Create compounds -------------------- #

# Create the compound hierarchy
.INTERMEDIATE: build/compounds.ttl
build/compounds.ttl: build/chebi-roles.ttl
	$(ROBOT) query \
	 --input $< \
	 --query $(QRS)/construct-compounds.rq $@

# -------------------- STEP 5: Compile -------------------- #

# Merge everything together
# Remove assertions of owl:Thing
# Reduce and reason
.INTERMEDIATE: build/chebi-merged.ttl
build/chebi-merged.ttl: build/chebi-roles.ttl build/chebi-other.ttl \
build/compounds.ttl build/precious.txt
	$(ROBOT_MIN) merge \
	 --input $< \
	 --input $(word 2,$^) \
	 --input $(word 3,$^) \
	 --input src/logic.ttl \
	reduce \
	reason \
	 --output $@

# Rehome children of 'other molecular entity' based on their chemical formula
# If there is a carbon in the formula, it belongs in 'organic molecular entity'
.INTERMEDIATE: build/chebi-rehomed.ttl
build/chebi-rehomed.ttl: build/chebi-merged.ttl
	$(SCRP)/rehome_other_entities.py $< $@

# Recreate the inorganics based on element
.INTERMEDIATE: build/chebi-elements.ttl
build/chebi-elements.ttl: build/chebi-rehomed.ttl
	$(SCRP)/add_elements.py $< $@

.INTERMEDIATE: build/chebi-cleaned.ttl
build/chebi-cleaned.ttl: build/chebi-elements.ttl
	$(ROBOT) query \
	 --input $< \
	 --update $(QRS)/curated/carb-derivative-update.ru \
	 --update $(QRS)/curated/clean-galacto-and-gluco.ru \
	 --update $(QRS)/curated/merge-carb-and-derivative.ru \
	 --update $(QRS)/clean-childless.ru \
	 --update $(QRS)/remove-other-parents.ru \
	 --update $(QRS)/add-other-logic.ru \
	 --update $(QRS)/curated/organic-children.ru \
	remove \
	 --term CHEBI:24431 \
	 --term CHEBI:50906 \
	 --term CHEBI:50906-compound \
     --select "self descendants" \
     --select "complement"\
	 --select "classes" \
	remove \
	 --term-file src/remove-after-others.txt \
	reduce \
	query --update $(QRS)/remove-extra-others.ru --output $@ 

# -------------------- STEP 6: Add source hierarchy -------------------- #

build/organism-tree.owl:
	curl -Lk -o $@ http://10.0.7.92/organisms/latest/build/organism-tree.owl

build/ncbitaxon.owl:
	curl -Lk -o $@ http://purl.obolibrary.org/obo/ncbitaxon.owl

.INTERMEDIATE: build/ontie-module.ttl
build/ontie-module.ttl:
	$(SCRP)/add_iedb_organisms.py $(EPITOPE_ORGS) $(SOURCE_ORGS) $@

# Create a subset with just the required terms
.INTERMEDIATE: build/organism-module.ttl
build/organism-module.ttl: build/organism-tree.owl build/ontie-module.ttl build/ncbitaxon.owl
	$(ROBOT) merge \
	 --input $< \
	 --input $(word 2, $^) \
	 --input $(word 3, $^) \
	extract \
	 --method MIREOT \
	 --upper-term OBI:0100026 \
	 --lower-terms $(SOURCE_ORGS) \
	remove \
	 --term NCBITaxon:1 \
	 --term NCBITaxon:131567 \
	 --output $@

# Mirror the hierachy with "product of"
.INTERMEDIATE: build/organism-sources.ttl
build/organism-sources.ttl: build/organism-module.ttl
	$(ROBOT) query \
	 --input $< \
	 --query $(QRS)/construct-orgs.rq $@

.INTERMEDIATE: build/filter-products.txt
build/filter-products.txt:
	sed '1d' $(EPITOPE_ORGS) | awk -F"," '{print $$1}' > $@

.INTERMEDIATE: build/chebi-products.ttl
build/chebi-products.ttl: build/chebi-cleaned.ttl build/filter-products.txt
	$(ROBOT) filter \
	 --input $< \
	 --term-file $(word 2,$^) \
	 --select "self annotations" \
	 --preserve-structure false \
	remove \
	 --axioms logical \
	 --output $@

# Merge NCBITaxon module and 'product of' hierarchy
.INTERMEDIATE: build/chebi-organisms.ttl
build/chebi-organisms.ttl: build/chebi-products.ttl build/organism-sources.ttl \
build/organism-module.ttl
	$(ROBOT) merge \
	 --input $< \
	 --input $(word 2,$^) \
	 --input $(word 3,$^) \
	 --output $@

# add the 'produced by' axioms and reason to generate full hierarchy
.INTERMEDIATE: build/chebi-sources.ttl
build/chebi-sources.ttl: build/chebi-organisms.ttl $(EPITOPE_ORGS)
	$(SCRP)/add_source_organisms.py $^ $@ && \
	$(ROBOT) reason \
	 --input $@ \
	 --output $@

# Get the references
.INTERMEDIATE: build/chebi-product-references.ttl
build/chebi-product-references.ttl: build/chebi-sources.ttl
	python $(SCRP)/add_references.py $< $@

# Get the counts of important (>>) subclasses
.INTERMEDIATE: $(RES)/product-child-counts.tsv
$(RES)/product-child-counts.tsv: build/chebi-product-references.ttl
	$(ROBOT) query \
	 --input $< \
	 --query $(QRS)/child-counts.rq $@

# Add the counts to the labels
.INTERMEDIATE: build/chebi-product-of.ttl
build/chebi-product-of.ttl: build/chebi-product-references.ttl $(RES)/child-counts.tsv
	$(SCRP)/add_count.py $^ $@

# final (separate) 'product of' hierarchy
chebi-product-of.owl: build/chebi-product-of.ttl
	$(ROBOT) convert --input $< --output $@

# -------------------- STEP 7: Add counts -------------------- #

# Get the references
.INTERMEDIATE: build/chebi-references.ttl
build/chebi-references.ttl: build/chebi-sources.ttl
	python $(SCRP)/add_references.py $< $@

# Get the counts of important (>>) subclasses
.INTERMEDIATE: $(RES)/child-counts.tsv
$(RES)/child-counts.tsv: build/chebi-references.ttl
	$(ROBOT) query \
	 --input $< \
	 --query $(QRS)/child-counts.rq $@

# Add the counts to the labels
.INTERMEDIATE: build/chebi-minimal.ttl
build/chebi-minimal.ttl: build/chebi-references.ttl $(RES)/child-counts.tsv
	$(SCRP)/add_count.py $^ $@

# -------------------- STEP 8: Validate -------------------- #

# Ensure that all of our input terms are in the final ontology
.PHONY: validate
validate: $(TERMS) build/chebi-minimal.ttl
	$(SCRP)/validate.py $^

# -------------------- STEP 9: Clean up -------------------- #

# Potentially annotate in the future here
# Remove everything that is not under 'chemical entity', 'compound', or 'role'
# Run update to remove compounds AND others with no children (post reasoning)
# Run update to remove the 'other' alternative hierarchy and add disjoint axioms
.PRECIOUS: chebi-minimal.owl
chebi-minimal.owl: build/chebi-minimal.ttl build/annotations.ttl | validate
	$(ROBOT) merge \
	 --input $< \
	 --input build/annotations.ttl \
	 --output $@ \
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
