PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX owl: <http://www.w3.org/2002/07/owl#>

DELETE { ?s ?p ?o }
WHERE { { ?s ?p ?o ;
		          rdfs:label ?label .
		?s rdfs:subClassOf* obo:CHEBI_50906-compound .
		FILTER NOT EXISTS { ?chem rdfs:subClassOf ?s }
		FILTER(!STRSTARTS(?label, ">>")) }
UNION { ?s ?p ?o ;
		   rdfs:label ?label .
		FILTER(STRSTARTS(?label, "other "))
		FILTER NOT EXISTS { ?chem rdfs:subClassOf ?s } } }
