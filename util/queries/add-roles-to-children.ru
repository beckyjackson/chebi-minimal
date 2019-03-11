PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX owl: <http://www.w3.org/2002/07/owl#>

INSERT { ?child rdfs:subClassOf ?roleAx }
WHERE { ?child rdfs:subClassOf* ?parent .
		FILTER (?child != ?parent)
        ?parent rdfs:subClassOf ?roleAx .
        ?roleAx a owl:Restriction ;
                owl:onProperty obo:RO_0000087 ;
                owl:someValuesFrom ?role . }
