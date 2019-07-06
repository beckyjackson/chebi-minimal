#!/usr/bin/env python

import rdflib, sys
from rdflib import URIRef, RDFS, Literal, XSD

def main(args):
	precious_file = args[1]
	input_path = args[2]

	precious = []
	with open(precious_file, 'r') as f:
		for line in f:
			precious.append(line.strip())

	gin = rdflib.Graph()
	print('Loading %s' % input_path)
	gin.parse(input_path, format='turtle')

	ok = True
	for p in precious:
		if p == "http://purl.obolibrary.org/obo/CHEBI_50699":
			continue
		elif p == "http://purl.obolibrary.org/obo/CHEBI_35267":
			continue
		uri = URIRef(p)
		trps = gin.triples((uri, None, None))
		if not trps:
			ok = False
			print('Missing class: %s' % p)

	if ok:
		print('Validation passed!')

if __name__ == '__main__':
	main(sys.argv)