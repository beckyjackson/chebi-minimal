PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX owl: <http://www.w3.org/2002/07/owl#>

DELETE { ?s ?p ?o }
WHERE { { ?s ?p ?o ;
		          rdfs:label ?label .
		FILTER(STRENDS(?label, "compound"))
		FILTER NOT EXISTS { ?chem rdfs:subClassOf ?s } }
UNION { ?s ?p ?o ;
		   rdfs:label ?label .
		FILTER(STRSTARTS(?label, "other "))
		FILTER NOT EXISTS { ?chem rdfs:subClassOf ?s } } }
