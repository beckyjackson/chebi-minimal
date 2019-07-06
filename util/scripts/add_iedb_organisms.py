#!/usr/bin/env python

import csv, MySQLdb, os, rdflib, sys
from rdflib import BNode, URIRef, RDFS, Literal, XSD

all_iris = {}

def main(args):
  '''Usage: ./add_iedb_organisms.py \
            <epitope-organisms> <terms-to-extract> <ttl-output>'''
  # table of epitope to source organism
  epitope_organisms_path = args[1]
  # also produces a set of IRIs to extract
  terms_to_extract = args[2]
  # the turtle output of ONTIE terms
  output = args[3]

  org_ids = get_org_ids(epitope_organisms_path)

  gin = rdflib.Graph()

  add_orgs_details(gin, org_ids)
  save_iris(terms_to_extract)

  print('Saving %s' % output)
  gin.serialize(destination=output, format='turtle')

def get_org_ids(epitope_organisms_path):
  '''Given a path to the epitope-organisms table, 
     return all organism IDs.'''
  org_ids = []
  with open(epitope_organisms_path, 'r') as f:
    reader = csv.reader(f, delimiter=',')
    # skip headers
    next(reader)
    for row in reader:
      org_ids.append(row[1])
  return set(org_ids)

def add_orgs_details(gin, org_ids):
  '''Given an RDF graph and a list of ONTIE organism IDs,
     add the organism labels and parents to the graph.'''
  # connect to the database
  print('Making connection')
  mysql_host = os.environ['MYSQL_HOST']
  mysql_user = os.environ['MYSQL_USER']
  mysql_pw = os.environ['MYSQL_PW']
  mysql_db = os.environ['MYSQL_DB']
  conn = MySQLdb.connect(host=mysql_host, user=mysql_user, passwd=mysql_pw, db=mysql_db)

  print('Querying organism table')
  for org_id in org_ids:
    add_org_details(gin, conn, org_id, org_ids)

def add_org_details(gin, conn, org_id, org_ids):
  '''Given an RDF graph, a MySQLdb connection, an organism ID, and the list of IDs,
     add the organim details to the graph 
     and check if the parent details need to be added.'''
  query = u'SELECT iri,organism_name,parent_tax_id \
            FROM organism WHERE organism_id = \'%s\'' % org_id
  c = conn.cursor()
  c.execute(query)
  res = c.fetchone()
  iri = res[0]
  label = res[1]
  if iri is None:
    print('ERROR: NO IRI FOR \'%s\'' % label)
    return

  all_iris[iri] = label

  if 'ONTIE' not in iri:
    # stop if it's not an ONTIE term
    return

  parent_id = res[2]

  # get the correct IRI of the parent
  query = u'SELECT iri FROM organism WHERE organism_id = \'%s\'' % parent_id
  c = conn.cursor()
  c.execute(query)
  res = c.fetchone()
  parent_iri = res[0]

  # add these to gin
  gin.add((URIRef(iri), RDFS.label, Literal(label)))
  gin.add((URIRef(iri), RDFS.subClassOf, URIRef(parent_iri)))
  if 'ONTIE' in parent_iri and parent_id not in org_ids:
    add_org_details(gin, conn, parent_id, org_ids)

def save_iris(terms_to_extract):
  print('Writing IRIs to %s' % terms_to_extract)
  with open(terms_to_extract, 'w+') as f:
    for iri, label in all_iris.items():
      f.write('%s # %s\n' % (iri, label))

if __name__ == '__main__':
  main(sys.argv)