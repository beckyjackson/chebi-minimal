#!/usr/bin/env python3

import csv, operator, os, sys, rdflib, re
from rdflib import URIRef, RDFS, Literal, XSD

all_nodes = []

def main(args):
	# usage: generate_spreadsheet.py 
	#        <root node> <chebi ttl> <epitope table> <output>
	root_node = args[1]
	chebi_file = args[2]
	epitope_table = args[3]
	output_csv = args[4]
	if len(args) > 5:
		exclude = args[5]
	else:
		exclude = None

	chebi_to_epitope = get_epitope_map(epitope_table)

	print('Loading %s' % chebi_file)
	gin = rdflib.Graph()
	gin.parse(chebi_file, format='turtle')

	exclude_label = None
	if exclude:
		# get the label of the node to exclude
		exclude_label = get_label(gin, exclude)
		print('Getting details for %s, excluding %s' 
			  % (root_node, exclude_label))
		recursively_get_children_excluding(gin, root_node, 0, exclude)
	else:
		print('Getting details for %s' % root_node)
		recursively_get_children(gin, root_node, 0)
	
	with open(output_csv, 'w') as f:
		if exclude:
			print('Writing results to %s (excluding)' % output_csv)
			f.write('# References,# Assays,# Epitopes,ChEBI ID,ChEBI IRI,' + 
			    'IEDB Link,Depth,Label,IEDB Synonym,Roles,Application?,In Excluded Node,' +
			    'Indented Label\n')
			for node in all_nodes:
				f.write(get_line_excluding(
					gin, node, chebi_to_epitope, exclude))
		else:
			f.write('# References,# Assays,# Epitopes,ChEBI ID,ChEBI IRI,' + 
				    'IEDB Link,Depth,Label,IEDB Synonym,Roles,Application?,Indented Label\n')
			for node in all_nodes:
				f.write(get_line(node, chebi_to_epitope))

def get_label(gin, entity):
	if 'http://' not in entity:
		iri = curie_iri(entity)
	else:
		iri = entity
	label = gin.value(subject=URIRef(iri), predicate=RDFS.label, any=False)
	if not label:
		return entity
	return label

def get_epitope_map(epitope_table):
	'''Given a path to the epitope table from IEDB, return a map of ChEBI ID to 
	   eptiope ID and synonyms.'''
	epitopes = {}
	with open(epitope_table, 'r') as f:
		reader = csv.reader(f, delimiter=',')
		next(reader)
		for line in reader:
			epitope_id = line[0]
			chebi_id = line[7]
			synonyms = line[8]
			if 'CHEBI' not in chebi_id:
				continue
			chebi_id = chebi_id.replace("_", ":")
			epitopes[chebi_id] = {'epitope_id': epitope_id, 
			                      'synonyms': synonyms}
	return epitopes

def recursively_get_children_excluding(gin, root, depth, exclude):
	'''Given a graph, a root node, the depth of the node, and a node to exclude,
	   recursively add children to all_nodes, excluding exclude.'''
	if 'http://' not in exclude:
		exclude = curie_iri(exclude)
	depth += 1
	children = get_children(gin, root, depth)
	if children:
		for c in children:
			if c['iri'] == exclude:
				continue
			all_nodes.append(c)
			recursively_get_children_excluding(gin, c['iri'], depth, exclude)

def recursively_get_children(gin, root, depth):
	'''Given a graph and a root node, recursively add children to all_nodes.'''
	depth += 1
	children = get_children(gin, root, depth)
	if children:
		for c in children:
			all_nodes.append(c)
			recursively_get_children(gin, c['iri'], depth)

# TODO: add comma-separated list of roles
def get_children(gin, root, depth):
	'''Given a graph and a root node, return a dict of direct child nodes sorted 
	   alphabetically by label.'''
	if 'http://' not in root:
		root = curie_iri(root)
    # gets the children with labels and optionally with roles
	query = '''SELECT DISTINCT ?child ?label (GROUP_CONCAT(DISTINCT ?role;separator=", ") AS ?roles) ?app WHERE {
			   { ?child rdfs:subClassOf <%s> ;
			          rdfs:label ?label .
			    FILTER NOT EXISTS {
			     ?child rdfs:subClassOf ?anon .
			   	 ?anon a owl:Restriction ;
			           owl:onProperty <http://purl.obolibrary.org/obo/RO_0000087> ;
			           owl:someValuesFrom ?x . }
			    BIND("" AS ?role)
			    BIND("" AS ?app)
			   } UNION {
			    ?child rdfs:subClassOf <%s> ;
			           rdfs:subClassOf ?anon ;
			           rdfs:label ?label .
			    ?anon a owl:Restriction ;
			          owl:onProperty <http://purl.obolibrary.org/obo/RO_0000087> ;
			          owl:someValuesFrom ?roleIRI .
			    ?roleIRI rdfs:subClassOf* ?roleParent ;
			    		 rdfs:label ?role .
			    ?roleParent rdfs:subClassOf <http://purl.obolibrary.org/obo/CHEBI_50906> .
			    BIND(xsd:string(IF(?roleParent = <http://purl.obolibrary.org/obo/CHEBI_33232>, "true", "")) AS ?app)
			   } }
			   GROUP BY ?child ?label ?roles 
			   ORDER BY ?label''' % (root, root)
	qres = gin.query(query)
	children = []
	for row in qres:
		roles = row.roles
		if not roles:
			roles = ''
		children.append({'iri': row.child, 
						 'label': row.label, 
						 'depth': depth, 
						 'roles': roles,
						 'app': row.app})
	return children

def get_line_excluding(gin, node, epitope_map, exclude):
	'''Given a node, the chebi-to-source map, and a node to exclude, return a 
	   spreadsheet line.'''
	iri = node['iri']
	curie = iri_curie(iri)
	if 'compound' in iri:
		chebi_link = ''
	else:
		chebi_link = iri

	# find out if it is also in the excluded node
	in_excluded = is_in_node(gin, iri, exclude)
	print('%s %s' % (iri, in_excluded))

	full_label = node['label']
	details = parse_label(full_label)
	label = details['label']
	assays = details['assays']
	refs = details['refs']
	epitopes = details['epitopes']
	roles = node['roles']
	app = node['app']

	# depth - 1 for indentation
	depth = int(node['depth']) - 1
	indent = '    ' * depth
	indented_label = indent + label
	# reset the depth to its original number
	depth = depth + 1

	if curie in epitope_map:
		source = epitope_map[curie]
		epitope_id = source['epitope_id']
		iedb_link = 'http://www.iedb.org/epitope/' + str(epitope_id)
		synonyms = source['synonyms']
	else:
		iedb_link = ''
		synonyms = ''

	return '"%s","%s","%s","%s","%s","%s","%s","%s","%s","%s","%s","%s","%s"\n' \
			% (refs, 
			   assays, 
			   epitopes, 
			   curie, 
			   chebi_link,
			   iedb_link, 
			   str(depth), 
			   label, 
			   synonyms,
			   roles,
			   app,
			   in_excluded, 
			   indented_label)

def get_line(node, epitope_map):
	'''Given a node and the chebi-to-source map, return a spreadsheet line.'''
	iri = node['iri']
	curie = iri_curie(iri)
	if 'compound' in iri:
		chebi_link = ''
	else:
		chebi_link = iri

	full_label = node['label']
	details = parse_label(full_label)
	label = details['label']
	assays = details['assays']
	refs = details['refs']
	epitopes = details['epitopes']
	roles = node['roles']
	app = node['app']

	# depth - 1 for indentation
	depth = int(node['depth']) - 1
	indent = '    ' * depth
	indented_label = indent + label
	# reset the depth to its original number
	depth = depth + 1

	if curie in epitope_map:
		source = epitope_map[curie]
		epitope_id = source['epitope_id']
		iedb_link = 'http://www.iedb.org/epitope/' + str(epitope_id)
		synonyms = source['synonyms'].replace('"', '\'\'')
	else:
		iedb_link = ''
		synonyms = ''

	return '"%s","%s","%s","%s","%s","%s","%s","%s","%s","%s","%s","%s"\n' \
			% (refs, 
			   assays, 
			   epitopes, 
			   curie, 
			   chebi_link,
			   iedb_link, 
			   str(depth), 
			   label, 
			   synonyms,
			   roles, 
			   app,
			   indented_label)

def is_in_node(gin, iri, node_iri):
	'''Given a graph to query, a child IRI, and a node IRI, determine if the 
	   child entity appears in the node.'''
	if 'http://' not in iri:
		iri = curie_iri(iri)
	if 'http://' not in node_iri:
		node_iri = curie_iri(node_iri)
	query = '''ASK { <%s> rdfs:subClassOf* <%s> }''' % (iri, node_iri)
	return bool(gin.query(query))

def parse_label(label):
	'''Given a label with count details, return a map of label components 
	   (label, assays, refs, and epitopes)'''
	if not re.search(r'.* \[[0-9]*a [0-9]*r [0-9]*d\]$', label):
		if not re.search(r'.*\[[0-9]*a [0-9]*r\]$', label):
			print('Missing refs: ' + label)
			return None
		groups = re.match(r'(.*) \[([0-9]*)a ([0-9]*)r\]$', label)
		label = groups[1]
		assays = groups[2]
		refs = groups[3]
		return {'label': label, 'assays': assays, 'refs': refs, 'epitopes': '0'}
	groups = re.match(r'(.*) \[([0-9]*)a ([0-9]*)r ([0-9]*)d\]$', label)
	label = groups[1]
	assays = groups[2]
	refs = groups[3]
	descendants = groups[4]
	return {'label': label, 
	        'assays': assays, 
	        'refs': refs, 
	        'epitopes': descendants}

def curie_iri(curie):
	'''Convert a CURIE to IRI'''
	return 'http://purl.obolibrary.org/obo/' + curie.replace(':', '_')

def iri_curie(iri):
	'''Convert an IRI to CURIE'''
	return iri[31:].replace('_', ':')

if __name__ == '__main__':
	main(sys.argv)
