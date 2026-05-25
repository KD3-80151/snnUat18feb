trigger TriggerOnOpportunity on Opportunity (before insert,before update,after insert,after update) {
    
    DocumentCreationHandler dCH = new DocumentCreationHandler();
    
    if(Trigger.isAfter && Trigger.isInsert) {
        
        // dCH.CreateDocuments(Trigger.new);
        opportunityTriggerHandler.afterInsert(Trigger.new);
    }
    
    
    if (Trigger.isAfter && Trigger.isUpdate) {
        OpportunityTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
    }


    
}