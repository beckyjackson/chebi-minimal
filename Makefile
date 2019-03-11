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

# Important directories
QRS = util/queries
RES = build/results
SCRP = ./util/scripts

# TODO:
# email Randi list of recategorized 'other molecular entity' children

# -------------------- OVERVIEW -------------------- #

# 1 Extract entities from ChEBI using the $(TERMS) and BOT method of extraction. 
#   Add >> to the labels of any terms in the seed set. Separate the 'role' 
#   hierarchy into its own file and remove it from the ontology to be processed.

# 2 Remove any unnecessary grouping entities, and bottom-level classes that were
#   not part of the seed set. Minimize, collapsing the hierarchy, based on $(T).

# 3 Add 'other' nodes to capture children who have been orphaned by minimizing.
#   These are all the bottom-level classes that end up under major grouping 
#   classes, such as 'organic molecular entity'.

# 4 Create a 'compound' hierarchy that mirrors the 'role' hierarchy. Add logic 
#   to connect chemical entities to compound parents. 

# 5 Merge all parts (chemical entities, roles, and compounds) and add counts to 
#   the labels. The counts show the number of seed-set descendants of a class.

# 6 Clean up the merged ontology by removing anything NOT under chemical entity,
#   role, or compound. Also clean up the compounds by removing any compound with 
#   no children.

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
	curl -Lk http://purl.obolibrary.org/obo/chebi.owl > $@

# Extract with min intermediates using BOT
.INTERMEDIATE: build/chebi-module.ttl
build/chebi-module.ttl: build/chebi.owl $(TERMS) | build
	@echo "Extracting $(word 2,$^) from $<" && \
	$(ROBOT) extract --input $< --term-file $(word 2,$^)\
	 --method BOT query --update $(QRS)/add-label-prefix.ru \
	query --update $(QRS)/add-roles-to-children.ru --output $@

# Separate the roles into own file (with role logic)
# Remove logic for any non-roles without >>
.INTERMEDIATE: build/chebi-roles.ttl
build/chebi-roles.ttl: build/chebi-module.ttl
	@echo "Separating role hierarchy into $@" && \
	$(ROBOT) filter --input $< --term CHEBI:50906\
	 --select "self descendants annotations" --trim false \
	query --update $(QRS)/trim-roles.ru --output $@

# Keep chemical entities in their own file
.INTERMEDIATE: build/chebi-chemicals.ttl
build/chebi-chemicals.ttl: build/chebi-module.ttl
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
# Flag upper-level precious terms ($)
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
	$(ROBOT_MIN) filter --input $< --term-file $(word 2,$^)\
	 --select "self annotations" --trim true --preserve-structure true \
	remove --term-file $(word 3,$^) --trim true --preserve-structure true \
	remove --term CHEBI:88184 --term CHEBI:72695 --term CHEBI:33285\
	 --term CHEBI:33561 --trim true --preserve-structure true \
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

# -------------------- STEP 5: compile -------------------- #

# Merge everything together
# Remove assertions of owl:Thing
# Reduce and reason
.INTERMEDIATE: build/chebi-merged.ttl
build/chebi-merged.ttl: build/chebi-roles.ttl build/chebi-other.ttl \
build/compounds.ttl build/precious.txt
	@echo "Merging: $^" && \
	$(ROBOT_MIN) merge --input $< --input $(word 2,$^)\
	 --input $(word 3,$^) --input src/logic.ttl \
	remove --term owl:Thing reduce reason --output $@

# Rehome children of 'other molecular entity' based on their chemical formula
# If there is a carbon in the formula, it belongs in 'organic molecular entity'
build/chebi-cleaned.ttl: build/chebi-merged.ttl
	@echo "Rehoming 'other molecular entity' children" && \
	$(SCRP)/rehome_other_entities.py $< $@

# Get the counts of important (>>) subclasses
.INTERMEDIATE: $(RES)/child-counts.tsv
$(RES)/child-counts.tsv: build/chebi-cleaned.ttl
	@echo "Getting child counts, see $@" && \
	$(ROBOT) query --input $< --query $(QRS)/child-counts.rq $@

# Add the counts to the labels
.INTERMEDIATE: build/chebi-minimal.ttl
build/chebi-minimal.ttl: build/chebi-cleaned.ttl $(RES)/child-counts.tsv
	@echo "Adding child counts to labels" && \
	$(SCRP)/add_count.py $^ $@

# -------------------- STEP 6: validate -------------------- #

# Ensure that all of our input terms are in the final ontology
.PHONY: validate
validate: $(TERMS) build/chebi-minimal.ttl
	@echo "Validating that all terms from $< are in $(word 2,$^)" && \
	$(SCRP)/validate.py $^

# -------------------- STEP 7: clean up -------------------- #

# Potentially annotate in the future here
# Remove everything that is not under 'chemical entity', 'compound', or 'role'
# Run update to remove compounds AND others with no children (post reasoning)
# Run update to remove the 'other' alternative hierarchy and add disjoint axioms
.PRECIOUS: chebi-minimal.owl
chebi-minimal.owl: build/chebi-minimal.ttl | validate
	@echo "Cleaning $<" && \
	$(ROBOT) query --input $< --update $(QRS)/clean-childless.ru \
	query --update $(QRS)/remove-other-parents.ru \
	query --update $(QRS)/add-other-logic.ru \
	remove --term CHEBI:24431 --term CHEBI:50906 --term CHEBI:50906-compound \
     --term CHEBI:23367-other --select "self descendants" --select "complement"\
	 --select "classes" --trim true --output $@ \
	&& echo "Created $@"