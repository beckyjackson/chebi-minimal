PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX oboInOwl: <http://www.geneontology.org/formats/oboInOwl#>
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX rdf:   <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX CHEBI: <http://purl.obolibrary.org/obo/CHEBI_>
PREFIX RO: <http://purl.obolibrary.org/obo/RO_>

DELETE { ?s rdfs:subClassOf ?other . }
WHERE {
	?s rdfs:subClassOf ?other ;
	   rdfs:label ?label .
	?other rdfs:label ?otherLabel .
	FILTER(STRSTARTS(STR(?otherLabel), "other "))
	?s rdfs:subClassOf ?notOther .
	FILTER(!STRENDS(STR(?notOther), "-compound"))
	?notOther rdfs:label ?notOtherLabel .
	FILTER(?notOther != ?other)
	FILTER(!STRSTARTS(STR(?notOtherLabel), "other "))
	FILTER(!STRSTARTS(STR(?notOtherLabel), "product of"))
}