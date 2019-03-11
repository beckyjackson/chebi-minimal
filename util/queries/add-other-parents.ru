PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX owl: <http://www.w3.org/2002/07/owl#>

INSERT { ?s rdfs:subClassOf ?newParent }
WHERE { ?s rdfs:label ?label ;
		   rdfs:subClassOf ?parent .
		FILTER(STRSTARTS(?label, "other "))
		?parent rdfs:subClassOf ?nextParent .
		FILTER(?nextParent != owl:Thing)
		BIND(IRI(CONCAT(STR(?nextParent), "-other")) AS ?newParent)
		FILTER EXISTS { ?newParent rdfs:label ?newParentLabel } }