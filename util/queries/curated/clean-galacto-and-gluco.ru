PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX oboInOwl: <http://www.geneontology.org/formats/oboInOwl#>
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX rdf:   <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX CHEBI: <http://purl.obolibrary.org/obo/CHEBI_>
PREFIX RO: <http://purl.obolibrary.org/obo/RO_>

DELETE {
	# clean up galactosamine and glucosamine nodes
	?otherGalactosamine rdfs:subClassOf CHEBI:22484-other .
	?otherGlucosamine rdfs:subClassOf CHEBI:22485-other .
	?galactosamine rdfs:subClassOf CHEBI:22484 .
	?glucosamine rdfs:subClassOf CHEBI:22485 .
}
WHERE {
	# get other galactosamines that have other parents
	?otherGalactosamine rdfs:subClassOf CHEBI:22484-other .
	?otherGalactosamine rdfs:subClassOf ?otherGalParent .
	FILTER (?otherGalParent != CHEBI:22484-other)
	FILTER (?otherGalParent != CHEBI:22485-other)

	# get other glucosamines that have other parents
	?otherGlucosamine rdfs:subClassOf CHEBI:22485-other .
	?otherGlucosamine rdfs:subClassOf ?otherGluParent .
	FILTER (?otherGluParent != CHEBI:22484-other)
	FILTER (?otherGluParent != CHEBI:22485-other)

	# get galactosamines that have other parents
	?galactosamine rdfs:subClassOf CHEBI:22484 ;
				   rdfs:label ?galLabel .
	FILTER (STRSTARTS(?galLabel, ">>"))
	?galactosamine rdfs:subClassOf ?notGalParent .
	FILTER (?notGalParent != CHEBI:22484)
	FILTER (?notGalParent != CHEBI:22485)

	# get glucosamines that have other parents
	?glucosamine rdfs:subClassOf CHEBI:22485 ;
				 rdfs:label ?gluLabel .
	FILTER (STRSTARTS(?gluLabel, ">>"))
	?glucosamine rdfs:subClassOf ?notGluParent .
	FILTER (?notGluParent != CHEBI:22485)
	FILTER (?notGluParent != CHEBI:22484)
}
