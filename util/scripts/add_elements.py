#!/usr/bin/env python

import re, rdflib, sys
from rdflib import URIRef, RDFS, Literal, XSD

# does not include synthetic elements or carbon
element_map = {
	'Ac' : 'actinium',
	'Al' : 'aluminum',
	'Am' : 'americium',
	'Sb' : 'antimony',
	'Ar' : 'argon',
	'As' : 'arsenic', 
	'At' : 'astatine',
	'Ba' : 'barium',
	'Bk' : 'berkelium',
	'Be' : 'beryllium',
	'Bi' : 'bismuth',
	'Bh' : 'bohrium',
	'B' : 'boron',
	'Br' : 'bromine',
	'Cd' : 'cadmium',
	'Ca' : 'calcium',
	'Cf' : 'californium',
	'Ce' : 'cerium',
	'Cs' : 'cesium',
	'Ca' : 'calcium',
	'Cl' : 'chlorine',
	'Cr' : 'chromium',
	'Co' : 'cobalt',
	'Cn' : 'copernicium',
	'Cu' : 'copper',
	'Cm' : 'curium',
	'Ds' : 'darmstadtium',
	'Db' : 'dubnium',
	'Dy' : 'dysprosium',
	'Er' : 'erbium',
	'Es' : 'einsteinium',
	'Eu' : 'europium',
	'Fm' : 'fermium',
	'F' : 'fluorine',
	'Fr' : 'francium',
	'Gd' : 'gadolinium',
	'Ga' : 'gallium',
	'Ge' : 'germanium',
	'Au' : 'gold',
	'Hf' : 'hafnium',
	'Hs' : 'hassium',
	'He' : 'helium',
	'Ho' : 'holmium',
	'H' : 'hydrogen',
	'In' : 'indium',
	'I' : 'iodine',
	'Ir' : 'iridium',
	'Fe' : 'iron',
	'Kr' : 'krypton',
	'La' : 'lanthanum',
	'Lr' : 'lawrencium',
	'Pb' : 'lead',
	'Li' : 'lithium',
	'Lu' : 'lutetium',
	'Mg' : 'magnesium',
	'Mn' : 'manganese',
	'Mt' : 'meitnerium',
	'Md' : 'mendelevium',
	'Hg' : 'mercury',
	'Mo' : 'molybdenum',
	'Nd' : 'neodymium',
	'Ne' : 'neon',
	'Np' : 'neptunium',
	'Ni' : 'nickel',
	'Nb' : 'niobium',
	'N' : 'nitrogen',
	'No' : 'nobelium',
	'Os' : 'osmium',
	'O' : 'oxygen',
	'Pd' : 'palladium',
	'P' : 'phosphorus',
	'Pt' : 'platinum',
	'Pu' : 'plutonium',
	'Po' : 'polonium',
	'K' : 'potassium',
	'Pr' : 'praseodymium',
	'Pm' : 'promethium',
	'Pa' : 'protactinum',
	'Ra' : 'radium',
	'Rn' : 'radon',
	'Rh' : 'rhenium',
	'Rh' : 'rhodium',
	'Rg' : 'roentgenium',
	'Rb' : 'rubidium',
	'Ru' : 'ruthenium',
	'Rf' : 'rutherfordium',
	'Sm' : 'samarium',
	'Sc' : 'scandium',
	'Sg' : 'seaborgium',
	'Se' : 'selenium',
	'Si' : 'silicon',
	'Ag' : 'silver',
	'Na' : 'sodium',
	'Sr' : 'strontium',
	'S' : 'sulfur',
	'Ta' : 'tantalum',
	'Tc' : 'technetium',
	'Te' : 'tellurium',
	'Tb' : 'terbium',
	'Tl' : 'thallium',
	'Th' : 'thorium',
	'Tm' : 'thulium',
	'Sn' : 'tin',
	'Ti' : 'titanium',
	'W' : 'tungsten',
	'U' : 'uranium',
	'V' : 'vanadium',
	'Xe' : 'xenon',
	'Yb' : 'ytterbium',
	'Y' : 'yttrium',
	'Zn' : 'zinc',
	'Zr' : 'zirconium'
}

# list of elements
elements = element_map.keys()
# list of non-metal elements
nonmetals = ['H', 'He', 'B', 'N', 'O', 'F', 'Ne', 'Si', 'P', 'S', 'Cl', 'Ar', 
'Ge', 'As', 'Se', 'Br', 'Kr', 'Sb', 'Te', 'I', 'Xe', 'Po', 'At', 'Rn']
# list of metal elements (all we care about right now)
metals = [e for e in elements if e not in nonmetals]

def main(args):
	'''Usage: ./add_elements.py <chebi-input> <chebi-output>'''
	input_path = args[1]
	output_path = args[2]

	gin = rdflib.Graph()

	print('Loading %s' % input_path)
	gin.parse(input_path, format='turtle')

	assinged_inorganics = assign_elements_to_inorganics(gin)
	assigned_atoms = assign_elements_to_atoms(gin)
	used_elements = get_used_elements(assigned_atoms, assinged_inorganics)

	build_elements(gin, used_elements, assigned_atoms, assinged_inorganics)

	print('Saving %s' % output_path)
	gin.serialize(destination=output_path, format='turtle')

def assign_elements_to_inorganics(gin):
	'''Given ChEBI as an RDF graph, find all children of inorganic molecular 
	entity that have formulas. Determine which metals are in the formula and 
	assign those elements to that inorganic molecular entity. Return a map of 
	IRI to list of elements. If there are no metals in the formula, the list 
	will be empty.'''
	query = '''SELECT DISTINCT ?s ?formula WHERE {
			   ?s rdfs:subClassOf* <http://purl.obolibrary.org/obo/CHEBI_24835> ;
			      <http://purl.obolibrary.org/obo/chebi/formula> ?formula .
			   }'''
	qres = gin.query(query)
	assigned = {}
	print('%d inorganics found' % len(qres))
	if not qres:
		return {}
	for row in qres:
		iri = row.s
		formula = row.formula
		this_elements = []
		for e in metals:
			regex = '({0}[A-Z|0-9])|({0}$)'.format(e)
			if re.search(regex, formula):
				this_elements.append(e)
		assigned[iri] = this_elements
	return assigned

def assign_elements_to_atoms(gin):
	'''Given ChEEBI as an RDF graph, find all children of atom that have 
	formulas. Use the formula to determine the element of the atom, and if it is 
	a metal. Return a map of IRI to element. If the atom is not a metal, the 
	element will be an emtpy string.'''
	query = '''SELECT DISTINCT ?s ?formula WHERE {
			   ?s rdfs:subClassOf* <http://purl.obolibrary.org/obo/CHEBI_33250> ;
			      <http://purl.obolibrary.org/obo/chebi/formula> ?formula .
			   }'''
	qres = gin.query(query)
	assigned = {}
	print('%d atoms found' % len(qres))
	if not qres:
		return {}
	for row in qres:
		iri = row.s
		formula = row.formula
		for e in metals:
			regex = '^{0}$'.format(e)
			if re.search(regex, formula):
				assigned[iri] = e
				break
	return assigned

def get_used_elements(assigned_atoms, assinged_inorganics):
	'''Given the assigned atoms map and the assigned inorganics map, return a 
	list of all elements used as values.'''
	used = []
	for e in assigned_atoms.values():
		if e not in used and e != '':
			used.append(e)
	for elems in assinged_inorganics.values():
		for e in elems:
			if e not in used:
				used.append(e)
	return used

def build_elements(gin, used_elements, assigned_atoms, assinged_inorganics):
	'''Given ChEBI as an RDF graph, the list of used elements, the assigned 
	atoms map, and the assigned inorganics map, build the "inorganic atom or 
	molecule" node in the RDF graph, sorting by element. Currently only sorts by 
	metals.'''
	# don't build any nodes if there are no children to add
	if not assigned_atoms and not assinged_inorganics:
		return

	inorganic = URIRef(
		'http://purl.obolibrary.org/obo/CHEBI_24835')
	metals = URIRef(
		'http://purl.obolibrary.org/obo/CHEBI_24835-metal')
	others = URIRef(
		'http://purl.obolibrary.org/obo/CHEBI_24835-other')

	# rename 'inorganic molecular entity'
	gin.remove((inorganic, RDFS.label, None))
	gin.add((inorganic, RDFS.label, Literal('inorganic atom or molecule')))

	# create structure for metal and others under
	gin.add((metals, RDFS.label, Literal('metal atom or molecule')))
	gin.add((metals, RDFS.subClassOf, inorganic))
	gin.add((others, RDFS.label, Literal('other inorganic atom or molecule')))
	gin.add((others, RDFS.subClassOf, inorganic))

	# add each 'atom or molecule' for the used elements
	for e in used_elements:
		uri = URIRef('http://purl.obolibrary.org/obo/CHEBI_24835-%s' % e)
		if e not in element_map:
			print('Missing element mapping: %s' % e)
			continue
		label = Literal('%s atom or molecule' % element_map[e])
		gin.add((uri, RDFS.subClassOf, metals))
		gin.add((uri, RDFS.label, label))

	# place atoms
	for iri, e in assigned_atoms.items():
		uri = URIRef(iri)
		if e == '':
			gin.add((uri, RDFS.subClassOf, others))
		else:
			parent = URIRef('http://purl.obolibrary.org/obo/CHEBI_24835-%s' % e)
			gin.add((uri, RDFS.subClassOf, parent))

	# place inorganics
	for iri, elems in assinged_inorganics.items():
		uri = URIRef(iri)
		gin.remove((uri, 
			RDFS.subClassOf, 
			URIRef('http://purl.obolibrary.org/obo/CHEBI_24835')))
		if not elems:
			gin.add((uri, RDFS.subClassOf, others))
		else:
			for e in elems:
				parent = URIRef(
					'http://purl.obolibrary.org/obo/CHEBI_24835-%s' % e)
				gin.add((uri, RDFS.subClassOf, parent))

	# remove old atom node and leftover children
	# 'atom' itself is removed later by ROBOT, as it may be used in logical defs
	atom = URIRef('http://purl.obolibrary.org/obo/CHEBI_33250')
	for o in gin.subjects(RDFS.subClassOf, atom):
		if '>>' not in gin.value(URIRef(o), RDFS.label):
			gin.remove((URIRef(o), None, None))
			gin.remove((None, None, URIRef(o)))
	gin.remove((atom, None, None))

if __name__ == '__main__':
	main(sys.argv)





