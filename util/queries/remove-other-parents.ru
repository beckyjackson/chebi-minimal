PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX owl: <http://www.w3.org/2002/07/owl#>

DELETE { ?other rdfs:subClassOf ?otherParent }
WHERE { ?other rdfs:subClassOf ?otherParent ;
			   rdfs:subClassOf ?parent .
	    FILTER(STRENDS(STR(?other), "other"))
	    FILTER(STRENDS(STR(?otherParent), "other")) } ;

DELETE { ?s rdfs:subClassOf ?parent }
WHERE { 
	?s rdfs:subClassOf ?parent .
	?s rdfs:subClassOf ?parent2 .
	?parent rdfs:subClassOf ?otherParent .
	FILTER(STRENDS(STR(?otherParent), "other"))
	FILTER(?parent != ?parent2)
	?parent rdfs:subClassOf* obo:CHEBI_78616 .
	?parent2 rdfs:subClassOf* obo:CHEBI_78616 . }
