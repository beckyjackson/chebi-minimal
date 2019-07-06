PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX oboInOwl: <http://www.geneontology.org/formats/oboInOwl#>
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX rdf:   <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX CHEBI: <http://purl.obolibrary.org/obo/CHEBI_>
PREFIX RO: <http://purl.obolibrary.org/obo/RO_>

# remove old roles

DELETE { # relocate phosphocolines
		 ?phosphocoline rdfs:subClassOf ?phosphocolineRoleAxiom .

         # relocate SAIDs
         ?said rdfs:subClassOf ?saidAxiom .

         # relocate chlorhexidine
         CHEBI:3614 rdfs:subClassOf ?chlorAxiom .

         # remove analgesic roles
         ?analgesic rdfs:subClassOf ?analgesicAxiom .

         # remove antiinfective roles
         ?antiinfective rdfs:subClassOf ?antiinfectiveAxiom .

         # remove antineoplastic role
		 CHEBI:17939 rdfs:subClassOf ?antineoAxiom .

		 # remove antitussive roles
         ?antitussive rdfs:subClassOf ?antitussiveAxiom .

         # remove some from drugs
         ?notDrug rdfs:subClassOf ?drugAxiom .

         # remove drug allergen roles
       	 ?allergen rdfs:subClassOf ?allergenAxiom .

         # remove vitamin C from skin lightening agent
         CHEBI:21241 rdfs:subClassOf CHEBI:85046 . }

WHERE { # relocate phosphocolines
		VALUES ?phosphocoline {
					  CHEBI:52360	
					  CHEBI:61043 
					  CHEBI:44699 
					  CHEBI:60319 
					  CHEBI:60475 
					  CHEBI:59416 
					  CHEBI:59423 
					  CHEBI:60653 } 
		?phosphocoline rdfs:subClassOf ?phosphocolineRoleAxiom .
		?phosphocolineRoleAxiom a owl:Restriction ;
					            owl:onProperty RO:0000087 ;
					            owl:someValuesFrom ?phosphocolineRole .
		?phosphocolineRole rdfs:subClassOf* CHEBI:23888 . 

		# relocate SAIDs
		VALUES ?said { CHEBI:3207 CHEBI:17650 CHEBI:4325 }
        ?said rdfs:subClassOf ?saidAxiom .
        ?saidAxiom a owl:Restriction ;
        			owl:onProperty RO:0000087 ;
        			owl:someValuesFrom CHEBI:35472 .

        # relocate chlorhexidine
		CHEBI:3614 rdfs:subClassOf ?chlorAxiom .
		?chlorAxiom a owl:Restriction ;
				   owl:onProperty RO:0000087 ;
				   owl:someValuesFrom ?chlorRole .
		?chlorRole rdfs:subClassOf* CHEBI:23888 .

		# remove analgesic roles
		VALUES ?analgesic { CHEBI:16335 CHEBI:5118 CHEBI:6717 }
        ?analgesic rdfs:subClassOf ?analgesicAxiom .
        ?analgesicAxiom a owl:Restriction ;
        			owl:onProperty RO:0000087 ;
        			owl:someValuesFrom CHEBI:35480 .

        # remove antiinfective roles
        VALUES ?antiinfective { 
					   CHEBI:5280 
					   CHEBI:17939 
					   CHEBI:32161
					   CHEBI:102130
					   CHEBI:9331
					   CHEBI:9332
					   CHEBI:102516
					   CHEBI:132842
					   CHEBI:9334
					   CHEBI:9337 }
		?antiinfective rdfs:subClassOf ?antiinfectiveAxiom .
		?antiinfectiveAxiom a owl:Restriction ;
				   owl:onProperty RO:0000087 ;
				   owl:someValuesFrom CHEBI:35441 .

		# remove antineoplastic role
		CHEBI:17939 rdfs:subClassOf ?antineoAxiom .
        ?antineoAxiom a owl:Restriction ;
        			owl:onProperty RO:0000087 ;
        			owl:someValuesFrom CHEBI:35610 .

        # remove antitussive roles
        VALUES ?antitussive { CHEBI:5779 CHEBI:53579 }
        ?antitussive rdfs:subClassOf ?antitussiveAxiom .
        ?antitussiveAxiom a owl:Restriction ;
        			      owl:onProperty RO:0000087 ;
        			      owl:someValuesFrom CHEBI:51177 .

        # remove some from drugs
        VALUES ?notDrug { CHEBI:17823 CHEBI:16870 CHEBI:141331 }
        ?notDrug rdfs:subClassOf ?drugAxiom .
        ?drugAxiom a owl:Restriction ;
        			owl:onProperty RO:0000087 ;
        			owl:someValuesFrom ?drug .
        ?drug rdfs:subClassOf* CHEBI:23888 .

        # remove drug allergen roles
       	?allergen rdfs:subClassOf ?allergenAxiom .
        ?allergenAxiom a owl:Restriction ;
        			owl:onProperty RO:0000087 ;
        			owl:someValuesFrom CHEBI:88188 }
