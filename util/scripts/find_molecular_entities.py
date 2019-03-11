#!/usr/bin/env python

import rdflib, sys
from rdflib import URIRef, RDFS, Literal, XSD

def main(args):
	'''Produces a list of IRIs of entities to be removed from ChEBI minimal: 
	   children of "chemical substance" (other than "mixture") and classes 
	   labeled with "organic" or "organo" under "organic molecular entity".'''
	input_path = args[1]
	output_path = args[2]

	gin = rdflib.Graph()

	print('Loading %s' % input_path)
	gin.parse(input_path, format='turtle')

	chem_substances = find_chemical_substances(gin)
	organics = find_organics(gin)

	with open(output_path, 'w') as f:
		for c in chem_substances:
			f.write(c + '\n')
		for o in organics:
			f.write(o + '\n')

def find_chemical_substances(gin):
	'''Finds non-important (not labeled with >>) children of "chemical 
	   substance", excluding "mixture".'''
	print('Querying for children of \'chemical substance\'')
	query = '''SELECT DISTINCT ?s ?label WHERE {
				  ?s rdfs:subClassOf* <http://purl.obolibrary.org/obo/CHEBI_59999> .
				  ?s rdfs:label ?label }'''
	qres = gin.query(query)
	print('%d entities found' % len(qres))
	remove = []
	for row in qres:
		iri = row.s
		label = row.label
		if '>>' not in label and 'mixture' not in label:
			remove.append(iri)
	return remove

def find_organics(gin):
	'''Finds non-important (not labeled with >>) classes labeled with "organic" 
	   or "organo".'''
	print('Querying for \'organic\' and \'compound\' entities')
	query = '''SELECT DISTINCT ?s ?label WHERE {
				  ?s rdfs:subClassOf* <http://purl.obolibrary.org/obo/CHEBI_23367> .
				  ?s rdfs:label ?label 
				  FILTER (?s != <http://purl.obolibrary.org/obo/CHEBI_23367>)}'''
	qres = gin.query(query)
	print('%d entities found' % len(qres))
	remove = []
	for row in qres:
		iri = row.s
		label = row.label
		if '>>' not in label \
		and 'molecular entity' not in label \
		and ('organo' in label or 'organic' in label):
			remove.append(iri)
		elif 'compound' in label and '>>' not in label:
			remove.append(iri)
	return remove

if __name__ == '__main__':
	main(sys.argv)
