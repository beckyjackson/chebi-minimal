PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX oboInOwl: <http://www.geneontology.org/formats/oboInOwl#>
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX rdf:   <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX CHEBI: <http://purl.obolibrary.org/obo/CHEBI_>
PREFIX RO: <http://purl.obolibrary.org/obo/RO_>

# for now only working with drugs

INSERT { ?chem rdfs:subClassOf ?newRoleAx .
		 ?newRoleAx a owl:Restriction ;
		 			owl:onProperty RO:0000087 ;
		 			owl:someValuesFrom ?otherRole . }
WHERE { ?chem rdfs:subClassOf ?roleAxiom .
		?roleAxiom a owl:Restriction ;
				   owl:onProperty RO:0000087 ;
				   owl:someValuesFrom ?role .
	 	?role rdfs:subClassOf* ?otherRole .
	 	?otherRole rdfs:subClassOf* CHEBI:23888 }