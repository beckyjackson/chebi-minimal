#!/usr/bin/python

import MySQLdb, os, rdflib, sys
from rdflib import OWL, URIRef, RDF, RDFS, Literal, XSD

missing = []

# requirements:
# set environment variables MYSQL_HOST, MYSQL_USER, MYSQL_PW, and MYSQL_DB

def main(args):
	# Usage: py add_references.py <Input ChEBI file> <Output ChEBI file>
	chebi_file = args[1]
	output_file = args[2]
	#conn_str = os.environ['ORACLE_CONN']
	#conn = cx_Oracle.connect(conn_str)

	print('Making connection')
	mysql_host = os.environ['MYSQL_HOST']
	mysql_user = os.environ['MYSQL_USER']
	mysql_pw = os.environ['MYSQL_PW']
	mysql_db = os.environ['MYSQL_DB']
	conn = MySQLdb.connect(host=mysql_host, user=mysql_user, passwd=mysql_pw, db=mysql_db)

	# map of source ID -> ChEBI ID
	source_chebi_map = get_source_chebi_map(conn)
	
	print('Loading %s' % chebi_file)
	gin = rdflib.Graph()
	gin.parse(chebi_file, format='turtle')

	# map of CHEBI ID -> all children IDs (includes self)
	chebi_children_map = get_chebi_children_map(gin)
	# map of CHEBI ID -> all children with source IDs
	#source_children_map = get_source_children_map(
	#	conn, source_chebi_map, chebi_children_map)
	# list of reference counts for each CHEBI ID including children counts
	references = get_references(conn, chebi_children_map)

	print('Updating labels')
	for info in references:
		assign_label(gin, info)

	print('Missing %d ChEBI IDs' % len(missing))
	print('Saving %s' % output_file)
	gin.serialize(destination=output_file, format='turtle')

def get_source_chebi_map(conn):
	'''Given an Oracle connection, return a map of SIDs -> CHEBI IDs'''
	print('Getting Source ID -> ChEBI ID map')
	source_chebi_map = {}
	c = conn.cursor()
	query = u'SELECT source_id,accession FROM source \
	          WHERE `database`=\'ChEBI\''
	c.execute(query)
	for row in c.fetchall():
		sid = row[0]
		cid = row[1]
		source_chebi_map[cid] = sid
	return source_chebi_map

def get_chebi_children_map(gin):
	'''Given an RDF Graph, return a map of CHEBI ID -> list of children IDs.'''
	print('Getting list of children for each ChEBI ID')
	# Find roles to exclude from checking references
	roles = []
	qres = gin.query(
		'SELECT ?s WHERE { \
		 ?s rdfs:subClassOf* <http://purl.obolibrary.org/obo/CHEBI_50906> }')
	for row in qres:
		roles.append(row.s)
	chebi_children_map = {}
	# Iterate through all IRIs of classes
	chebi_iris = gin.subjects(RDF.type, OWL.Class)
	for iri in chebi_iris:
		# Skip if it's a role
		if iri in roles:
			continue
		# Get all the children CURIEs
		cid = to_curie(iri)
		if '-other' in iri:
			# Only query direct children of 'other' nodes
			qres = gin.query(
				'SELECT ?s WHERE { ?s rdfs:subClassOf <%s> }' % iri)
		else:
			# Otherwise get all descendants
			qres = gin.query(
				'SELECT ?s WHERE { ?s rdfs:subClassOf* <%s> }' % iri)
		children = []
		for row in qres:
			child = to_curie(row.s)
			children.append(child)
		chebi_children_map[cid] = children
	return chebi_children_map

def get_source_children_map(conn, source_chebi_map, chebi_children_map):
	'''Given an Oracle connection, a map of SIDs to CHEBI IDs, and a map of 
	CHEBI IDs to lists of children CHEBI IDs, return a map of all CHEBI IDs to 
	list of children as SIDs. If a child does not have an SID, do not include in 
	the list.'''
	print('Getting Source IDs for each child of each ChEBI ID')
	source_children_map = {}
	for cid,children in chebi_children_map.items():
		source_children = []
		for c in children:
			if c in source_chebi_map:
				source_children.append(source_chebi_map[c])
		source_children_map[cid] = source_children
	return source_children_map

def get_references(conn, source_children_map):
	'''Given an Oracle connection and a map of CHEBI IDs to the SIDs of the 
	children, return a list of reference counts. Each reference is a map with 
	"id", "assays", and "refs".'''
	print('Getting total references for each ChEBI ID and children')
	references = []
	for cid,children in source_children_map.items():
		if not children:
			info = {'id': cid, 'assays': 0, 'refs': 0}
			references.append(info)
			continue
		quoted_children = []
		for ch in children:
			quoted_children.append('\'%s\'' % ch)
		# Max num of expressions is 1000
		if len(quoted_children) > 999:
			# Partition list if necessary
			parts = partition(quoted_children, 999)
			ref_count = {'assays': 0, 'refs': 0}
			for p in parts:
				new_count = query_references(conn, p)
				new_assays = ref_count['assays'] + new_count['assays']
				new_refs = ref_count['refs'] + new_count['refs']
				ref_count['assays'] = new_assays
				ref_count['refs'] = new_refs
			ref_count['id'] = cid
			references.append(ref_count)
		else:
			# Otherwise just use the list as normal
			ref_count = query_references(conn, quoted_children)
			ref_count['id'] = cid
			references.append(ref_count)
	return references

def query_references(conn, quoted_children):
	'''Given an Oracle connection and a list of quoted children SIDs, query for 
	number of references to all SIDs in the list. Return a map with "assays" and 
	"refs" keys.'''
	references = []
	child_str = ', '.join(quoted_children)
	query = u'SELECT COUNT(*), COUNT(DISTINCT REFERENCE_ID)\
			      FROM OBJECT WHERE MOL1_ACCESSION IN (%s)' % child_str
	c = conn.cursor()
	c.execute(query)
	for row in c.fetchall():
		assays = row[0]
		refs = row[1]
	return {'assays': assays, 'refs': refs}

def partition(l, n):
	'''Partition a big list into smaller lists of size n'''
	for i in range(0, len(l), n):
		yield l[i:i + n]

def assign_label(gin, info):
	'''Given a Graph and a map of info, assign a new label with assay and 
	reference counts to the ID specified in info'''
	uri = URIRef(
		'http://purl.obolibrary.org/obo/' + info['id'].replace(':', '_'))
	references = ' [%sa %sr]' % (info['assays'], info['refs'])
	old_label = gin.value(
		subject=uri, predicate=RDFS.label, any=False, default=None)
	if not old_label:
		missing.append(info['id'])
		return
	new_label = old_label + references
	gin.remove((uri, RDFS.label, None))
	gin.add((uri, RDFS.label, Literal(new_label)))

def to_curie(iri):
	return iri.split('/')[-1].replace('_', ':')

if __name__ == '__main__':
	main(sys.argv)