trigger TriggerOnLead on Lead (before insert, after insert, before update, after update) {
    
    LeadHandler li = new LeadHandler();
    
    if(Trigger.isBefore && Trigger.isInsert) {
        li.assignToQueue(Trigger.new);
        LeadHandler.updateDuplicateLeads(Trigger.new);
    }
    
    if(Trigger.isAfter && Trigger.isInsert ){
        System.debug('Trigger is firing on after insert ');
        LeadHandler.sendAnSMSonLeadPhone(Trigger.new);
        LeadHandler.shareLead(Trigger.new);
    }  
    if(Trigger.isAfter && Trigger.isUpdate){
        System.debug('Trigger is firing on after update');
        List<Lead> leadsToProcess = new List<Lead>();
        for(Id leadId : Trigger.newMap.keySet()){
            Lead newLead = Trigger.newMap.get(leadId);
            Lead oldLead = Trigger.oldMap.get(leadId);
            if (newLead.Email != oldLead.Email || newLead.Phone != oldLead.Phone || newLead.Alternate_Email__c != oldLead.Alternate_Email__c || newLead.Alternate_Phone__c != oldLead.Alternate_Phone__c) {
                leadsToProcess.add(newLead);
            }
        }
        if(!leadsToProcess.isEmpty()){
            LeadHandler.sendAnSMSonLeadPhone(Trigger.new);
        }
      //  LeadHandler.shareLead(Trigger.new);
    }
    
    if(Trigger.isBefore && Trigger.isUpdate){
        System.debug('Trigger is firing on before update');
        LeadHandler.validationsAfterStatusChange(Trigger.new, Trigger.oldMap);
        LeadHandler.updateDuplicateLeadsBeforeUpdate(Trigger.new, Trigger.oldMap);
    }
    
}