public with sharing class LeadTriggerHandler {
         public static void handleLeadConversion(List<Lead> newLeads, Map<Id, Lead> oldLeadMap) {
        try {
            System.debug('Handling lead conversion for leads: ' + newLeads);

            List<Id> convertedLeadIds = new List<Id>();
            Map<Id, Id> leadToOpportunityMap = new Map<Id, Id>();

            for (Lead lead : newLeads) {
                Lead oldLead = oldLeadMap.get(lead.Id);

                if (lead.IsConverted == true && oldLead.IsConverted == false && lead.ConvertedOpportunityId != null
                ) {
                    convertedLeadIds.add(lead.Id);
                    leadToOpportunityMap.put(lead.Id, lead.ConvertedOpportunityId);
                }
            }

            if (convertedLeadIds.isEmpty()) {
                return;
            }

            List<Communication_Notes__c> existingNotes = [SELECT Id, Lead__c, Opportunity__c FROM Communication_Notes__c WHERE Lead__c IN :convertedLeadIds
            ];

            if (existingNotes.isEmpty()) {
                return;
            }
            system.debug('Existing Communication Notes: ' + existingNotes);
            for (Communication_Notes__c note : existingNotes) {
                note.Opportunity__c = leadToOpportunityMap.get(note.Lead__c);
            }

            update existingNotes;

        } catch (Exception e) {
            System.debug('Error in handleLeadConversion: ' + e.getMessage());
        }
    }


   
}