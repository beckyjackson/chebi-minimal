#!/usr/bin/env python

import rdflib, re, sys
from rdflib import URIRef, RDFS, Literal, XSD

def main(args):
	'''Categorizes "other chemical entity" children as either organic or 
	   inorganic and moves them to the appropriate node.'''
	input_path = args[1]
	output_path = args[2]

	gin = rdflib.Graph()

	print('Loading %s' % input_path)
	gin.parse(input_path, format='turtle')

	rehome_others(gin)
	print('Saving %s' % output_path)
	gin.serialize(destination=output_path, format='turtle')

def rehome_others(gin):
	'''Queries for direct children of "other chemical entity" and "chemical 
	   entity" that have a formula annotation. Moves the classes to organic or 
	   inorganic nodes.'''
	print('Querying for \'other molecular entity\' children and their formulas')
	query = '''SELECT DISTINCT ?s ?formula WHERE { {
				  ?s rdfs:subClassOf <http://purl.obolibrary.org/obo/CHEBI_24431-other> ;
				     <http://purl.obolibrary.org/obo/chebi/formula> ?formula .
				  } UNION {
				  ?s rdfs:subClassOf <http://purl.obolibrary.org/obo/CHEBI_24431> ;
				     rdfs:label ?label .
				  FILTER(STRSTARTS(?label, ">>"))
				  ?c rdfs:subClassOf ?s ;
				     <http://purl.obolibrary.org/obo/chebi/formula> ?formula . } }'''
	qres = gin.query(query)
	print('%d entities found' % len(qres))
	organic = []
	inorganic = []
	for row in qres:
		iri = row.s
		formula = row.formula
		# if it matches this regex, it is organic (carbon-containing)
		if re.search("C[A-Z|0-9]", formula):
			organic.append(iri)
		else:
			inorganic.append(iri)
	assert_new_parents(gin, organic, inorganic)
	# Remove all links to 'other chemical entity'
	gin.remove((URIRef('http://purl.obolibrary.org/obo/CHEBI_24431-other'), None, None))
	gin.remove((None, None, URIRef('http://purl.obolibrary.org/obo/CHEBI_24431-other')))

def assert_new_parents(gin, organic, inorganic):
	'''Asserts all IRIs in organic as children of "organic molecular entity" and
	   all IRIs in inorganic as children of "inorganic molecular entity".'''
	organic_uri = URIRef('http://purl.obolibrary.org/obo/CHEBI_50860-other')
	inorganic_uri = URIRef('http://purl.obolibrary.org/obo/CHEBI_24835')
	other_uri = URIRef('http://purl.obolibrary.org/obo/CHEBI_24431-other')

	print('Moving %d classes to organic and %d classes to inorganic' 
		  % (len(organic), len(inorganic)))

	for org in organic:
		uri = URIRef(org)
		gin.remove((uri, RDFS.subClassOf, other_uri))
		gin.add((uri, RDFS.subClassOf, organic_uri))

	for inorg in inorganic:
		uri = URIRef(inorg)
		gin.remove((uri, RDFS.subClassOf, other_uri))
		gin.add((uri, RDFS.subClassOf, inorganic_uri))


if __name__ == '__main__':
	main(sys.argv)
