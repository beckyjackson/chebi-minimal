#!/usr/bin/env python

import csv, MySQLdb, os, rdflib, sys
from rdflib import BNode, URIRef, RDFS, Literal, XSD

# Important URIs
produced_by = URIRef('http://purl.obolibrary.org/obo/RO_0003001')
rdf_type = URIRef('http://www.w3.org/1999/02/22-rdf-syntax-ns#type')
restriction = URIRef('http://www.w3.org/2002/07/owl#Restriction')
some_vals = URIRef('http://www.w3.org/2002/07/owl#someValuesFrom')
on_prop = URIRef('http://www.w3.org/2002/07/owl#onProperty')


def main(args):
  '''Usage: ./add_source_organisms.py \
            <chebi-minimal> <epitope-organisms> <ttl-output>'''
  # ChEBI minimal with 'product of' hierarchy
  input_path = args[1]
  # table of epitope to source organism
  epitope_organisms_path = args[2]
  output = args[3]

  gin = rdflib.Graph()

  print('Loading %s' % input_path)
  gin.parse(input_path, format='turtle')

  epitope_organisms = get_epitope_organisms(gin, epitope_organisms_path)
  add_produced_by_axioms(gin, epitope_organisms)

  print('Saving %s' % output)
  gin.serialize(destination=output, format='turtle')


def get_epitope_organisms(gin, epitope_organisms_path):
  '''Given a path to the epitope_organisms table, 
     return a table of ChEBI ID to source organism IRI.'''
  epitope_organisms = {}

  print('Making connection')
  mysql_host = os.environ['MYSQL_HOST']
  mysql_user = os.environ['MYSQL_USER']
  mysql_pw = os.environ['MYSQL_PW']
  mysql_db = os.environ['MYSQL_DB']
  conn = MySQLdb.connect(host=mysql_host, 
                         user=mysql_user, 
                         passwd=mysql_pw, 
                         db=mysql_db)

  print('Getting organism IRIs from IEDB')
  with open(epitope_organisms_path, 'r') as f:
    reader = csv.reader(f, delimiter=',')
    # skip headers
    next(reader)
    for row in reader:
      chebi_id = 'http://purl.obolibrary.org/obo/' + row[0].replace(':', '_')
      org_id = row[1]

      # execute the query
      c = conn.cursor()
      query = u'SELECT organism_name,iri \
                FROM organism WHERE organism_id = \'%s\'' % org_id
      c.execute(query)
      res = c.fetchone()
      label = res[0]
      iri = res[1]
      if iri is None:
        # ignore NULL IRIs, they are not in ONTIE (yet?)
        print('Organism \'{0}\' for {1} has no IRI'.format(label, row[0]))
        # remove them from the product-of tree for now
        gin.remove((URIRef(chebi_id), None, None))
        continue

      # add to dictionary
      if chebi_id in epitope_organisms:
        orgs = epitope_organisms[chebi_id]
      else:
        orgs = []
      orgs.append(iri)
      epitope_organisms[chebi_id] = orgs

  return epitope_organisms


def add_produced_by_axioms(gin, epitope_organisms):
  '''Given an RDF graph and a map of ChEBI IDs to orgnanism IRIs, 
     add the "produced by" axioms.'''
  print('Adding \'produced by\' axioms')
  for chebi_id,orgs in epitope_organisms.items():
    chebi_uri = URIRef(chebi_id)
    if (URIRef(chebi_id), None, None) in gin:
      for o in orgs:
        if (URIRef(o), None, None) in gin:
          bnode = BNode()
          gin.add((bnode, rdf_type, restriction))
          gin.add((bnode, on_prop, produced_by))
          gin.add((bnode, some_vals, URIRef(o)))
          gin.add((chebi_uri, RDFS.subClassOf, bnode))
        else:
          print(
            'Organism {0} for {1} does not exist in organism tree'.format(
              iri_curie(o), iri_curie(chebi_id)))
    else:
      print(
        '{0} exists in IEDB but does not exist in ChEBI minimal'.format(
          iri_curie(chebi_id)))


def iri_curie(iri):
  '''Convert an IRI to CURIE'''
  return iri.split('/')[-1].replace('_', ':')

if __name__ == '__main__':
  main(sys.argv)
  