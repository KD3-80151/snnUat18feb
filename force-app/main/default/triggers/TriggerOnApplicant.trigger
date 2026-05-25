trigger TriggerOnApplicant on Applicant__c (After insert) {
    
   if(Trigger.isAfter && Trigger.IsInsert) {
        system.debug('inside applicant after insert');
        opportunityTriggerHandler.ApplicantInsert(Trigger.new);
    }
}