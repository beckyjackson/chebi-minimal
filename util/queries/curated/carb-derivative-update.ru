PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX oboInOwl: <http://www.geneontology.org/formats/oboInOwl#>
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX rdf:   <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX CHEBI: <http://purl.obolibrary.org/obo/CHEBI_>
PREFIX RO: <http://purl.obolibrary.org/obo/RO_>

DELETE {
	# remove old ganglioside labels
	CHEBI:28892-other rdfs:label ?otherGangLabel .
	CHEBI:36544 rdfs:label ?sialodiosylceramideLabel .
	CHEBI:36543 rdfs:label ?sialotetraosylceramideLabel .

	# remove ganglioside GM1 subclass statement
	CHEBI:61048 rdfs:subClassOf CHEBI:18216 .

	# remove ganglioside GT1b subclass statement
	CHEBI:60913 rdfs:subClassOf CHEBI:28058 .

	# flatten glycoglycerolipid node
	?glycoglycerolipid rdfs:subClassOf ?glycoglycerolipidParent .

	# flatten oligoglycosylceramide node
	?oligoglycosylceramideChildren rdfs:subClassOf ?oligoglycosylceramide .

	# remove galactosylceramide sulfate from sulfoglycolipid
	CHEBI:18318 rdfs:subClassOf CHEBI:26829 .

	# remove direct children of carb derivative
	?carb rdfs:subClassOf CHEBI:63299 .
}

INSERT {
	# move beta-D ... to other node
	CHEBI:51013 rdfs:subClassOf CHEBI:28892-other .

	# rename ganglioside nodes
	CHEBI:28892-other rdfs:label "GM2 and related gangliosides" .
	CHEBI:36544 rdfs:label "GM3 and related gangliosides" .
	CHEBI:36543 rdfs:label "GM1 and related gangliosides" .

	# add new ganglioside GM1 subclass statement
	CHEBI:61048 rdfs:subClassOf CHEBI:36543 .

	# add new ganglioside GT1b subclass statement
	CHEBI:60913 rdfs:subClassOf CHEBI:36543 .

	# flatten glycoglycerolipid node
	?glycoglycerolipid rdfs:subClassOf CHEBI:24385 .

	# flatten oligoglycosylceramide node
	?oligoglycosylceramideChildren rdfs:subClassOf CHEBI:36520-other .

	# move direct children of carb derivative to other node
	?carb rdfs:subClassOf CHEBI:63299-other .
}

WHERE {
	# get old ganglioside labels
	CHEBI:28892-other rdfs:label ?otherGangLabel .
	CHEBI:36544 rdfs:label ?sialodiosylceramideLabel .
	CHEBI:36543 rdfs:label ?sialotetraosylceramideLabel .

	# flatten glycoglycerolipid node
	?glycoglycerolipid rdfs:subClassOf* CHEBI:24385 .
	?glycoglycerolipid rdfs:subClassOf ?glycoglycerolipidParent .
	?glycoglycerolipidParent rdfs:subClassOf* CHEBI:24385 .

	# flatten oligoglycosylceramide node only at top level
	?oligoglycosylceramide rdfs:subClassOf CHEBI:36520 ;
						   rdfs:label ?oligoglycosylceramideLabel .
    FILTER(STRSTARTS(?oligoglycosylceramideLabel, ">>"))
    ?oligoglycosylceramideChildren rdfs:subClassOf ?oligoglycosylceramide .

	# get direct children of carb derivative except glycolipid
	?carb rdfs:subClassOf CHEBI:63299 ;
		  rdfs:label ?carbLabel .
    FILTER (STRSTARTS(?carbLabel, ">>")) .
    FILTER (?carb != CHEBI:33563)
}