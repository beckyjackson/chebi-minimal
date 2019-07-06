PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX oboInOwl: <http://www.geneontology.org/formats/oboInOwl#>
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX rdf:   <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX CHEBI: <http://purl.obolibrary.org/obo/CHEBI_>
PREFIX RO: <http://purl.obolibrary.org/obo/RO_>

INSERT { 
	obo:IEDB_0000010 rdfs:label "1 monosaccharide or monosaccharide derivative" ;
					 rdfs:subClassOf CHEBI:78616 .
	obo:IEDB_0000011 rdfs:label "2 disaccharide or disaccharide derivative" ;
					 rdfs:subClassOf CHEBI:78616 .
	obo:IEDB_0000012 rdfs:label "3 trisaccharide or trisccharide derivative" ;
					 rdfs:subClassOf CHEBI:78616 .
	obo:IEDB_0000013 rdfs:label "4 tetrasaccharide or teetrasaccharide derivative" ;
					 rdfs:subClassOf CHEBI:78616 .
	obo:IEDB_0000014 rdfs:label "5 pentasaccharide or pentasaccharide derivative" ;
					 rdfs:subClassOf CHEBI:78616 .
	obo:IEDB_0000015 rdfs:label "6 hexasaccharide or hexasaccharide derivative" ;
					 rdfs:subClassOf CHEBI:78616 .
	obo:IEDB_0000016 rdfs:label "7 heptasaccharide or heptasaccharide derivative" ;
					 rdfs:subClassOf CHEBI:78616 .
	obo:IEDB_0000017 rdfs:label "8 octasaccharide or octasaccharide derivative" ;
					 rdfs:subClassOf CHEBI:78616 .
	obo:IEDB_0000018 rdfs:label "9 polysaccharide or polysaccharide derivative" ;
					 rdfs:subClassOf CHEBI:78616 .
	CHEBI:35381 rdfs:subClassOf obo:IEDB_0000010 .
	CHEBI:63367 rdfs:subClassOf obo:IEDB_0000010 .
	CHEBI:36233 rdfs:subClassOf obo:IEDB_0000011 .
	CHEBI:63353 rdfs:subClassOf obo:IEDB_0000011 .
	CHEBI:27150 rdfs:subClassOf obo:IEDB_0000012 .
	CHEBI:63571 rdfs:subClassOf obo:IEDB_0000012 . 
	CHEBI:50126 rdfs:subClassOf obo:IEDB_0000013 .
	CHEBI:63567 rdfs:subClassOf obo:IEDB_0000013 .
	CHEBI:35369 rdfs:subClassOf obo:IEDB_0000014 .
	CHEBI:63566 rdfs:subClassOf obo:IEDB_0000014 .
	CHEBI:35368 rdfs:subClassOf obo:IEDB_0000015 .
	CHEBI:63565 rdfs:subClassOf obo:IEDB_0000015 .
	CHEBI:53463 rdfs:subClassOf obo:IEDB_0000016 .
	CHEBI:63568 rdfs:subClassOf obo:IEDB_0000016 .
	CHEBI:61863 rdfs:subClassOf obo:IEDB_0000017 .
	CHEBI:71061 rdfs:subClassOf obo:IEDB_0000017 . 
	CHEBI:18154 rdfs:subClassOf obo:IEDB_0000018 .
	CHEBI:65212 rdfs:subClassOf obo:IEDB_0000018 . }
WHERE {} ;

INSERT { ?s rdfs:subClassOf CHEBI:16646-other }
WHERE { ?s rdfs:subClassOf CHEBI:50699-other }
