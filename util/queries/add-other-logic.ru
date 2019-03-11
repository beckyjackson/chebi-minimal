PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX owl: <http://www.w3.org/2002/07/owl#>

INSERT { ?other owl:disjointWith ?sibling }
WHERE { ?other rdfs:subClassOf ?parent ;
               rdfs:label ?otherLabel .
        FILTER(STRSTARTS(?otherLabel, "other "))
		?sibling rdfs:subClassOf ?parent.
	    FILTER(?other != ?sibling) }
