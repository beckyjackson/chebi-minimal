PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX owl: <http://www.w3.org/2002/07/owl#>

DELETE { ?child rdfs:subClassOf ?other }
WHERE { ?child rdfs:subClassOf ?parent ;
	           rdfs:subClassOf ?other .
	    FILTER(?parent != ?other)
	    FILTER(!isBlank(?parent))
	    ?other rdfs:label ?otherLabel .
	    ?parent rdfs:label ?parentLabel .
	    FILTER(!STRSTARTS(?parentLabel, "other "))
	    FILTER(STRSTARTS(?otherLabel, "other ")) }
