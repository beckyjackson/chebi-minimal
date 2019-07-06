PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX oboInOwl: <http://www.geneontology.org/formats/oboInOwl#>
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX rdf:   <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX CHEBI: <http://purl.obolibrary.org/obo/CHEBI_>
PREFIX RO: <http://purl.obolibrary.org/obo/RO_>

# Make manually-curated merged nodes

# Remove old role axioms
DELETE { ?vasodilator rdfs:subClassOf ?vasodilatorRole .
		 ?vasoconstrictor rdfs:subClassOf ?vasoconstrictorRole .
		 ?bronchoconstrictor rdfs:subClassOf ?bronchoconstrictorRole .
		 ?bronchodilator rdfs:subClassOf ?bronchodilatorRole .
		 ?antiallergic rdfs:subClassOf ?antiallergicRole .
		 ?antiasthmatic rdfs:subClassOf ?antiasthmaticRole .
		 ?antitussive rdfs:subClassOf ?antitussiveRole .
		 ?renal rdfs:subClassOf ?renalRole .
		 ?diuretic rdfs:subClassOf ?diureticRole .
		 ?laxative rdfs:subClassOf ?laxAxiom . }

INSERT { # move general & local anaesthetic
		 CHEBI:38869 rdfs:subClassOf obo:IEDB_0000004 .
		 CHEBI:36333 rdfs:subClassOf obo:IEDB_0000004 .

		 # move all CNS drugs under IEBD:4
		 CHEBI:35488 rdfs:subClassOf obo:IEDB_0000004 .
		 CHEBI:35337 rdfs:subClassOf obo:IEDB_0000004 .

		 # move PNS node under IEBD:3
		 CHEBI:49110 rdfs:subClassOf obo:IEDB_0000003 .

		 # add new vasodilator/vasoconstrictor roles
		 ?vasodilator rdfs:subClassOf [ a owl:Restriction ;
							 		    owl:onProperty RO:0000087 ;
							 		    owl:someValuesFrom obo:IEDB_0000006 ] .
		 ?vasoconstrictor rdfs:subClassOf [ a owl:Restriction ;
							 		    	owl:onProperty RO:0000087 ;
							 		    	owl:someValuesFrom obo:IEDB_0000006 ] .
		 
		 # move anti-allergic/respiratory roles to merged node
		 ?bronchodilator rdfs:subClassOf [ a owl:Restriction ;
							 		       owl:onProperty RO:0000087 ;
							 		       owl:someValuesFrom obo:IEDB_0000005 ] .
		 ?bronchoconstrictor rdfs:subClassOf [ a owl:Restriction ;
							 		    	   owl:onProperty RO:0000087 ;
							 		    	   owl:someValuesFrom obo:IEDB_0000005 ] .
		 ?antiallergic rdfs:subClassOf [ a owl:Restriction ;
							 		     owl:onProperty RO:0000087 ;
							 		     owl:someValuesFrom obo:IEDB_0000005 ] .
		 ?antiasthmatic rdfs:subClassOf [ a owl:Restriction ;
							 		      owl:onProperty RO:0000087 ;
							 		      owl:someValuesFrom obo:IEDB_0000005 ] .

		 # replace antitussive with antiallergic/respiratory
		 ?antitussive rdfs:subClassOf [ a owl:Restriction ;
		 								owl:onProperty RO:0000087 ;
		 								owl:someValuesFrom obo:IEDB_0000005 ] .

		 # move renal agents and diuretics to merged node
		 ?renal rdfs:subClassOf [ a owl:Restriction ;
		 						  owl:onProperty RO:0000087 ;
		 						  owl:someValuesFrom obo:IEDB_0000007 ] .
		 ?diuretic rdfs:subClassOf [ a owl:Restriction ;
		 						     owl:onProperty RO:0000087 ;
		 						     owl:someValuesFrom obo:IEDB_0000007 ] .

		 # move laxatives under gastrointestinal drug
		 ?laxative rdfs:subClassOf [ a owl:Restriction ;
 									   owl:onProperty RO:0000087 ;
 									   owl:someValuesFrom CHEBI:55324 ] . }

WHERE { # retrieve vasodilators
		?vasodilator rdfs:subClassOf ?vasodilatorRole .
		?vasodilatorRole a owl:Restriction ;
						 owl:onProperty RO:0000087 ;
						 owl:someValuesFrom CHEBI:35620 .

		# retrieve vasoconstrictors
		?vasoconstrictor rdfs:subClassOf ?vasoconstrictorRole .
		?vasoconstrictorRole a owl:Restriction ;
						       owl:onProperty RO:0000087 ;
						       owl:someValuesFrom CHEBI:50514 .

		# retrieve bronchoconstrictors
		?bronchoconstrictor rdfs:subClassOf ?bronchoconstrictorRole .
		?bronchoconstrictorRole a owl:Restriction ;
						        owl:onProperty RO:0000087 ;
						 		owl:someValuesFrom CHEBI:50141 .

		# retrieve bronchodilators
		?bronchodilator rdfs:subClassOf ?bronchodilatorRole .
		?bronchodilatorRole a owl:Restriction ;
						    owl:onProperty RO:0000087 ;
						    owl:someValuesFrom CHEBI:35523 .

		# retrieve anti-allergic agents
		?antiallergic rdfs:subClassOf ?antiallergicRole .
		?antiallergicRole a owl:Restriction ;
						    owl:onProperty RO:0000087 ;
							owl:someValuesFrom CHEBI:50857 .

		# retrieve anti-asthmatic drugs
		?antiasthmatic rdfs:subClassOf ?antiasthmaticRole .
		?antiasthmaticRole a owl:Restriction ;
						   owl:onProperty RO:0000087 ;
						   owl:someValuesFrom CHEBI:49167 .

		# retrieve antitussive drugs
		?antitussive rdfs:subClassOf ?antitussiveRole .
		?antitussiveRole a owl:Restriction ;
						 owl:onProperty RO:0000087 ;
						 owl:someValuesFrom CHEBI:51177 .

		# retrieve renal agents
		?renal rdfs:subClassOf ?renalRole .
		?renalRole a owl:Restriction ;
				   owl:onProperty RO:0000087 ;
				   owl:someValuesFrom ?renalChildren .
		?renalChildren rdfs:subClassOf* CHEBI:35846 .

		# retrieve diuretics
		?diuretic rdfs:subClassOf ?diureticRole .
		?diureticRole a owl:Restriction ;
					  owl:onProperty RO:0000087 ;
					  owl:someValuesFrom ?diureticChildren .
		?diureticChildren rdfs:subClassOf* CHEBI:35498 .

		# retrieve laxatives
		?laxative rdfs:subClassOf ?laxAxiom .
        ?laxAxiom a owl:Restriction ;
        			owl:onProperty RO:0000087 ;
        			owl:someValuesFrom CHEBI:50503 . }
