PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX oboInOwl: <http://www.geneontology.org/formats/oboInOwl#>
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX rdf:   <http://www.w3.org/1999/02/22-rdf-syntax-ns#>

DELETE { ?s ?p ?o .
		 ?x ?y ?s }
WHERE { ?s ?p ?o ;
		   a owl:Class ;
		   rdfs:label ?label .
		OPTIONAL { ?x ?y ?s }
		FILTER NOT EXISTS { ?s rdfs:subClassOf* obo:CHEBI_50906 }
		FILTER(!STRSTARTS(STR(?label), ">>")) }