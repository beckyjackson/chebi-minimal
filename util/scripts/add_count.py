#!/usr/bin/env python

import rdflib, sys
from rdflib import URIRef, RDFS, Literal, XSD

def main(args):
	ontology = args[1]
	query_res = args[2]
	output = args[3]
	entries = {}
	print('Reading new labels from %s' % query_res)
	with open(query_res, 'r') as f:
		next(f)
		for line in f:
			iri = line.split('\t')[0].strip().strip('>').strip('<')
			old_label = line.split('\t')[1].strip().strip('"')
			children = line.split('\t')[2].strip()
			label = '%s [%s]' % (old_label, children)
			entries[iri] = label

	print('Loading %s' % ontology)
	gin = rdflib.Graph()
	gin.parse(ontology, format='turtle')

	print('Updating labels')
	for iri, label in entries.items():
		uri = URIRef(iri)
		gin.remove((uri, RDFS.label, None))
		gin.add((uri, RDFS.label, Literal(label, datatype=XSD.string)))

	print('Saving %s' % output)
	gin.serialize(destination=output, format='turtle')

if __name__ == '__main__':
	main(sys.argv)