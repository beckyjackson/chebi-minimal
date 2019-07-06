PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX oboInOwl: <http://www.geneontology.org/formats/oboInOwl#>
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX rdf:   <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX CHEBI: <http://purl.obolibrary.org/obo/CHEBI_>
PREFIX RO: <http://purl.obolibrary.org/obo/RO_>

# merge other aromatics
DELETE { ?arom rdfs:subClassOf CHEBI:50860 }
INSERT { ?arom rdfs:subClassOf CHEBI:33659 . }
WHERE { VALUES ?arom { CHEBI:47916 } } ;

# merge alkaloids
DELETE { ?alks rdfs:subClassOf CHEBI:50860 }
INSERT { obo:IEDB_0000023 rdfs:subClassOf CHEBI:50860 ;
						  rdfs:label "piperidines and other alkaloids" .
		 ?alks rdfs:subClassOf obo:IEDB_0000023 . }
WHERE { VALUES ?alks { CHEBI:26151
					   CHEBI:22315 } } ;

# flatten aldehydes
DELETE { ?aldehyde rdfs:subClassOf ?aldehydeParent }
INSERT { ?aldehyde rdfs:subClassOf CHEBI:17478 }
WHERE { ?aldehyde rdfs:subClassOf* CHEBI:17478 .
		?aldehyde rdfs:subClassOf ?aldehydeParent .
		?aldehydeParent rdfs:subClassOf* CHEBI:17478 . } ;

# flatten phenylalanine derivative
DELETE { ?otherPhen rdfs:subClassOf CHEBI:25985-other }
INSERT { ?otherPhen rdfs:subClassOf CHEBI:25985 }
WHERE { ?otherPhen rdfs:subClassOf CHEBI:25985-other } ;
