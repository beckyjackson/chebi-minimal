PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX CHEBI: <http://purl.obolibrary.org/obo/CHEBI_>
PREFIX RO: <http://purl.obolibrary.org/obo/RO_>

# Manually-curated updates for application roles

# Merge all cosmetics
DELETE { ?cosmetic rdfs:subClassOf ?cosmeticAxiom . }
INSERT { ?cosmetic rdfs:subClassOf [ a owl:Restriction ;
                                     owl:onProperty RO:0000087 ;
                                     owl:someValuesFrom obo:IEDB_0000008 ] . }
WHERE  { ?cosmetic rdfs:subClassOf ?cosmeticAxiom .
         ?cosmeticAxiom a owl:Restriction ;
                        owl:onProperty RO:0000087 ;
                        owl:someValuesFrom ?cosmeticRole .
         ?cosmeticRole rdfs:subClassOf* CHEBI:64857 . } ;


# Change 'food additive' to 'food-related agent'
DELETE { CHEBI:64047 rdfs:label ?label . }
INSERT { CHEBI:64047 rdfs:label "food-related agent" . }
WHERE  { CHEBI:64047 rdfs:label ?label . } ;


# Replace food anticaking agent & food humectant with 'food-related agent'
DELETE { ?food rdfs:subClassOf ?foodAxiom . }
INSERT { ?food rdfs:subClassOf [ a owl:Restriction ;
                                 owl:onProperty RO:0000087 ;
                                 owl:someValuesFrom CHEBI:64047 ] }
WHERE  { ?food rdfs:subClassOf ?foodAxiom .
         ?foodAxiom a owl:Restriction ;
                    owl:onProperty RO:0000087 ;
                    owl:someValuesFrom ?foodRole .
         ?foodRole rdfs:subClassOf* CHEBI:64047 . } ;


# Merge all detergents
DELETE { ?detergent rdfs:subClassOf ?detergentAxiom . }
INSERT { ?detergent rdfs:subClassOf [ a owl:Restriction ;
 									  owl:onProperty RO:0000087 ;
 									  owl:someValuesFrom obo:IEDB_0000008 ] . }
WHERE  { ?detergent rdfs:subClassOf ?detergentAxiom .
         ?detergentAxiom a owl:Restriction ;
                         owl:onProperty RO:0000087 ;
                         owl:someValuesFrom ?detergentRole .
         ?detergentRole rdfs:subClassOf* CHEBI:27780 . } ;
