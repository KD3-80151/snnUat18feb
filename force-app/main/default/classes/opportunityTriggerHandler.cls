public without sharing class opportunityTriggerHandler {

      public static void afterInsert(List<Opportunity> oppList){
        try{
            List<Id> oppIds = new List<Id>();
            if(!oppList.isEmpty()){
                for(Opportunity opp : oppList){
                    oppIds.add(opp.Id);
                }
            }
            if(!oppIds.isEmpty()){
                System.enqueueJob(new QueueableCreateFolderGDrive(oppIds));
            }
        }catch(Exception e){
            system.debug('Error ==> ' + e.getMessage());
            system.debug('Error in line ==> ' + e.getLineNumber());
        }
    }

    public static void ApplicantInsert(List<Applicant__c> appList){
        try{
            List<Document__c> documentListToInsert = new List<Document__c>();
            List<Id> docIds = new List<Id>();
            List<Id> appIds = new List<Id>();
            if(!appList.isEmpty()){
                for(Applicant__c app : appList){
                    appIds.add(app.Id);
                }

                List<Applicant__c> applicantList = [SELECT Id,Name,Account__c,Opportunity__c,Account__r.Name from Applicant__c where Id IN: appIds];
                if(!applicantList.isEmpty()){
                    for(Applicant__c app : applicantList){
                        Document__c doc = new Document__c();
                        doc.Opportunity__c = app.Opportunity__c;
                        doc.Account__c = app.Account__c;
                        doc.Applicant__c = app.Id;
                        doc.Name = 'Co Applicant - ' + app.Account__r.Name;
                        System.debug('doc ===> ' + doc);
                        documentListToInsert.add(doc);
                    }
                }

                if(!documentListToInsert.isEmpty()){
                    insert documentListToInsert;
                    for(Document__c doc : documentListToInsert){
                        System.debug('adter insert doc ===> ' + doc);
                        docIds.add(doc.Id);
                    }
                }
                System.debug('docids ===> ' + docIds);
                
                if(!docIds.isEmpty()){
                    System.enqueueJob(new QueueableCreateFolderGDrive(docIds));
                }
            }

            
        }catch(Exception e){
            system.debug('Error ==> ' + e.getMessage());
            system.debug('Error in line ==> ' + e.getLineNumber());
        }
    }
    
    
    
      public static void afterUpdate(List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
        System.debug('after update get called123');
          List<Opportunity> oppsToUpdate = new List<Opportunity>();
        List<Task> tasksToUpdate = new List<Task>();

        for (Opportunity opp : newList) {
            Opportunity oldOpp = oldMap.get(opp.Id);

            // Check if Registration_Date__c was changed
            if (opp.Registration_Date__c != oldOpp.Registration_Date__c && 
                opp.Registration_Date__c != null) {
                
                // 1. Change stage
                Opportunity updatedOpp = new Opportunity(
                    Id = opp.Id,
                    StageName = 'Pre Handover Check'
                );
                oppsToUpdate.add(updatedOpp);

                // 2. Find open tasks with subject "Update Registration Date"
                List<Task> relatedTasks = [
                    SELECT Id, Status 
                    FROM Task 
                    WHERE WhatId = :opp.Id 
                    AND Subject = 'Update Registration Date'
                    AND Status != 'Completed'
                ];

                for (Task t : relatedTasks) {
                    t.Status = 'Completed';
                    tasksToUpdate.add(t);
                }
            }
        }

        if (!oppsToUpdate.isEmpty()) {
            update oppsToUpdate;
        }
        if (!tasksToUpdate.isEmpty()) {
            update tasksToUpdate;
        }
    }
}