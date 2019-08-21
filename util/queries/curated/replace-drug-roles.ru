PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX CHEBI: <http://purl.obolibrary.org/obo/CHEBI_>
PREFIX RO: <http://purl.obolibrary.org/obo/RO_>

# Manually-curated updates for drug roles

# merge vasodilator and vasoconstrictor roles
DELETE { ?vasodilator rdfs:subClassOf ?vasodilatorRole .
         ?vasoconstrictor rdfs:subClassOf ?vasoconstrictorRole . }
INSERT { ?vasodilator rdfs:subClassOf [ a owl:Restriction ;
                                        owl:onProperty RO:0000087 ;
                                        owl:someValuesFrom obo:IEDB_0000006 ] .
         ?vasoconstrictor rdfs:subClassOf [ a owl:Restriction ;
                                            owl:onProperty RO:0000087 ;
                                            owl:someValuesFrom obo:IEDB_0000006 ] . }
WHERE  { ?vasodilator rdfs:subClassOf ?vasodilatorRole .
         ?vasodilatorRole a owl:Restriction ;
                          owl:onProperty RO:0000087 ;
                          owl:someValuesFrom CHEBI:35620 .

         ?vasoconstrictor rdfs:subClassOf ?vasoconstrictorRole .
         ?vasoconstrictorRole a owl:Restriction ;
                                owl:onProperty RO:0000087 ;
                                owl:someValuesFrom CHEBI:50514 . } ;


# merge anti-allergic and respiratory roles
DELETE { ?bronchoconstrictor rdfs:subClassOf ?bronchoconstrictorRole .
         ?bronchodilator rdfs:subClassOf ?bronchodilatorRole .
         ?antiallergic rdfs:subClassOf ?antiallergicRole .
         ?antiasthmatic rdfs:subClassOf ?antiasthmaticRole . }
INSERT { ?bronchodilator rdfs:subClassOf [ a owl:Restriction ;
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
                                          owl:someValuesFrom obo:IEDB_0000005 ] . }
WHERE  { ?bronchoconstrictor rdfs:subClassOf ?bronchoconstrictorRole .
         ?bronchoconstrictorRole a owl:Restriction ;
                                 owl:onProperty RO:0000087 ;
                                 owl:someValuesFrom CHEBI:50141 .

         ?bronchodilator rdfs:subClassOf ?bronchodilatorRole .
         ?bronchodilatorRole a owl:Restriction ;
                             owl:onProperty RO:0000087 ;
                             owl:someValuesFrom CHEBI:35523 .

         ?antiallergic rdfs:subClassOf ?antiallergicRole .
         ?antiallergicRole a owl:Restriction ;
                             owl:onProperty RO:0000087 ;
                             owl:someValuesFrom CHEBI:50857 .

         ?antiasthmatic rdfs:subClassOf ?antiasthmaticRole .
         ?antiasthmaticRole a owl:Restriction ;
                            owl:onProperty RO:0000087 ;
                            owl:someValuesFrom CHEBI:49167 . } ;


# replace antitussive with new respiratory role
DELETE { ?antitussive rdfs:subClassOf ?antitussiveRole . }
INSERT { ?antitussive rdfs:subClassOf [ a owl:Restriction ;
                                        owl:onProperty RO:0000087 ;
                                        owl:someValuesFrom obo:IEDB_0000005 ] . }
WHERE  { ?antitussive rdfs:subClassOf ?antitussiveRole .
         ?antitussiveRole a owl:Restriction ;
                          owl:onProperty RO:0000087 ;
                          owl:someValuesFrom CHEBI:51177 . } ;


# merge renal agent and diuretic
DELETE { ?renal rdfs:subClassOf ?renalRole .
         ?diuretic rdfs:subClassOf ?diureticRole . }
INSERT { ?renal rdfs:subClassOf [ a owl:Restriction ;
                                  owl:onProperty RO:0000087 ;
                                  owl:someValuesFrom obo:IEDB_0000007 ] .
         ?diuretic rdfs:subClassOf [ a owl:Restriction ;
                                     owl:onProperty RO:0000087 ;
                                     owl:someValuesFrom obo:IEDB_0000007 ] . }
WHERE  { ?renal rdfs:subClassOf ?renalRole .
         ?renalRole a owl:Restriction ;
                    owl:onProperty RO:0000087 ;
                    owl:someValuesFrom ?renalChildren .
         ?renalChildren rdfs:subClassOf* CHEBI:35846 .

         ?diuretic rdfs:subClassOf ?diureticRole .
         ?diureticRole a owl:Restriction ;
                       owl:onProperty RO:0000087 ;
                       owl:someValuesFrom ?diureticChildren .
         ?diureticChildren rdfs:subClassOf* CHEBI:35498 . } ;


# change laxative to gastrointestinal drug role
DELETE { ?laxative rdfs:subClassOf ?laxAxiom . }
INSERT { ?laxative rdfs:subClassOf [ a owl:Restriction ;
                                       owl:onProperty RO:0000087 ;
                                       owl:someValuesFrom CHEBI:55324 ] . }
WHERE  { ?laxative rdfs:subClassOf ?laxAxiom .
         ?laxAxiom a owl:Restriction ;
                     owl:onProperty RO:0000087 ;
                     owl:someValuesFrom CHEBI:50503 . } ;


# move general & local anaesthetic
INSERT { ?an rdfs:subClassOf obo:IEDB_0000004 . }
WHERE  { VALUES ?an { CHEBI:38869 CHEBI:36333 } } ;


# move all CNS drugs under IEBD:4
INSERT { ?cns rdfs:subClassOf obo:IEDB_0000004 . }
WHERE  { VALUES ?cns { CHEBI:35488 CHEBI:35337 } } ;


# move PNS node under IEBD:3
INSERT { ?pns rdfs:subClassOf obo:IEDB_0000003 . }
WHERE  { VALUES ?pns { CHEBI:49110 } } ;
