PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX owl: <http://www.w3.org/2002/07/owl#>

# give all parent class roles to all descendants
INSERT { ?child rdfs:subClassOf ?roleAx }
WHERE  { ?child rdfs:subClassOf* ?parent .
         FILTER (?child != ?parent)
         ?parent rdfs:subClassOf ?roleAx .
         ?roleAx a owl:Restriction ;
                 owl:onProperty obo:RO_0000087 ;
                 owl:someValuesFrom ?role . } ;

INSERT { ?child rdfs:subClassOf [ a owl:Restriction ;
                                  owl:onProperty obo:RO_0000087 ;
                                  owl:someValuesFrom ?parentRole ] }
WHERE  { ?child rdfs:subClassOf ?roleAx .
         ?roleAx a owl:Restriction ;
                 owl:onProperty obo:RO_0000087 ;
                 owl:someValuesFrom ?role .
         ?role rdfs:subClassOf* ?parentRole } ;


# add 'has role' some ancestor for all roles
INSERT { ?chem rdfs:subClassOf ?newRoleAx .
         ?newRoleAx a owl:Restriction ;
                    owl:onProperty obo:RO_0000087 ;
                    owl:someValuesFrom ?otherRole . }
WHERE  { ?chem rdfs:subClassOf ?roleAxiom .
         ?roleAxiom a owl:Restriction ;
                    owl:onProperty obo:RO_0000087 ;
                    owl:someValuesFrom ?role .
         ?role rdfs:subClassOf* ?otherRole .
         ?otherRole rdfs:subClassOf* obo:CHEBI_50906 .
         FILTER (?otherRole != obo:CHEBI_50906)   # not 'role'
         FILTER (?otherRole != obo:CHEBI_23888)   # not 'drug'
         FILTER (?otherRole != obo:CHEBI_33232)   # not 'application'
         FILTER (?otherRole != obo:CHEBI_24432)   # not 'biological role'
         FILTER (?otherRole != obo:CHEBI_51086) } # not 'chemical role'
 