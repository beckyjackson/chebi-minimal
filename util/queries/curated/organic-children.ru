PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX CHEBI: <http://purl.obolibrary.org/obo/CHEBI_>
PREFIX RO: <http://purl.obolibrary.org/obo/RO_>

# merge other aromatics
DELETE { ?arom rdfs:subClassOf CHEBI:50860 }
INSERT { ?arom rdfs:subClassOf CHEBI:33659 . }
WHERE  { VALUES ?arom { CHEBI:47916 } } ;

# merge alkaloids
DELETE { ?alks rdfs:subClassOf CHEBI:50860 }
INSERT { obo:IEDB_0000023 rdfs:subClassOf CHEBI:50860 ;
                          rdfs:label "piperidines and other alkaloids" .
         ?alks rdfs:subClassOf obo:IEDB_0000023 . }
WHERE  { VALUES ?alks { CHEBI:26151
                        CHEBI:22315 } } ;

# flatten aldehydes
DELETE { ?aldehyde rdfs:subClassOf ?aldehydeParent }
INSERT { ?aldehyde rdfs:subClassOf CHEBI:17478 }
WHERE  { ?aldehyde rdfs:subClassOf* CHEBI:17478 .
         ?aldehyde rdfs:subClassOf ?aldehydeParent .
         ?aldehydeParent rdfs:subClassOf* CHEBI:17478 . } ;

# flatten phenylalanine derivative
DELETE { ?otherPhen rdfs:subClassOf CHEBI:25985-other }
INSERT { ?otherPhen rdfs:subClassOf CHEBI:25985 }
WHERE  { ?otherPhen rdfs:subClassOf CHEBI:25985-other } ;

# update sulfur label
DELETE { CHEBI:33261 rdfs:label ?label . }
INSERT { CHEBI:33261 rdfs:label "sulfur compounds" . }
WHERE  { CHEBI:33261 rdfs:label ?label . } ;

# update aromatic label
DELETE { CHEBI:33659 rdfs:label ?label . }
INSERT { CHEBI:33659 rdfs:label "aromatic compounds" . }
WHERE  { CHEBI:33659 rdfs:label ?label . } ;

# move to 'other'
DELETE { ?others rdfs:subClassOf CHEBI:50860 }
INSERT { ?others rdfs:subClassOf CHEBI:50860-other }
WHERE  { VALUES ?others { CHEBI:37622 
                          CHEBI:33575 
                          CHEBI:35701 
                          CHEBI:53212 
                          CHEBI:38104 
                          CHEBI:46774 } }
