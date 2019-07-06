PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX oboInOwl: <http://www.geneontology.org/formats/oboInOwl#>
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX rdf:   <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX CHEBI: <http://purl.obolibrary.org/obo/CHEBI_>
PREFIX RO: <http://purl.obolibrary.org/obo/RO_>

# Make manually-curated merged nodes

# Remove old role axioms
DELETE { ?cosmetic rdfs:subClassOf ?cosmeticAxiom .
		 ?detergent rdfs:subClassOf ?detergentAxiom .

		 # remove label of food additive
         CHEBI:64047 rdfs:label ?label .

         ?food rdfs:subClassOf ?foodAxiom . }

INSERT { # move cosmetics under merged node
		 ?cosmetic rdfs:subClassOf [ a owl:Restriction ;
 									 owl:onProperty RO:0000087 ;
 									 owl:someValuesFrom obo:IEDB_0000008 ] .

 		 # move detergents under merged node
		 ?detergent rdfs:subClassOf [ a owl:Restriction ;
 									  owl:onProperty RO:0000087 ;
 									  owl:someValuesFrom obo:IEDB_0000008 ] .

         CHEBI:64047 rdfs:label "food-related agent" .

         ?food rdfs:subClassOf [ a owl:Restriction ;
                                 owl:onProperty RO:0000087 ;
                                 owl:someValuesFrom CHEBI:64047 ] }

WHERE { # retrieve cosmetics
        ?cosmetic rdfs:subClassOf ?cosmeticAxiom .
        ?cosmeticAxiom a owl:Restriction ;
                       owl:onProperty RO:0000087 ;
                       owl:someValuesFrom ?cosmeticRole .
        ?cosmeticRole rdfs:subClassOf* CHEBI:64857 .

        # retrieve detergents
        ?detergent rdfs:subClassOf ?detergentAxiom .
        ?detergentAxiom a owl:Restriction ;
                        owl:onProperty RO:0000087 ;
                        owl:someValuesFrom ?detergentRole .
        ?detergentRole rdfs:subClassOf* CHEBI:27780 .

        # get label of food additive
        CHEBI:64047 rdfs:label ?label .

        # replace food anticaking agent & food humectant
        ?food rdfs:subClassOf ?foodAxiom .
        ?foodAxiom a owl:Restriction ;
                   owl:onProperty RO:0000087 ;
                   owl:someValuesFrom ?foodRole .
        ?foodRole rdfs:subClassOf* CHEBI:64047 . }
