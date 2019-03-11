PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX owl: <http://www.w3.org/2002/07/owl#>

DELETE { ?other rdfs:subClassOf ?otherParent }
WHERE { ?other rdfs:subClassOf ?otherParent ;
			   rdfs:subClassOf ?parent ;
			   rdfs:label ?label .
	    FILTER(STRSTARTS(?label, "other "))
	    ?otherParent rdfs:label ?parentLabel .
	    FILTER(STRSTARTS(?parentLabel, "other ")) }
