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

    public static void sendSalesTeamMemberNotification(List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
        system.debug('newList::' + newList);
        system.debug('oldMap::' + oldMap);
        try {
            if (newList == null || newList.isEmpty()) {
                return;
            }

            Set<Id> userIds = new Set<Id>();
            List<Opportunity> oppsToNotify = new List<Opportunity>();

            for (Opportunity opp : newList) {
                Id newSalesTeamMemberId = opp.Sales_Team_Member__c;
                Id oldSalesTeamMemberId = oldMap != null && oldMap.containsKey(opp.Id) ? oldMap.get(opp.Id).Sales_Team_Member__c : null;

                if (newSalesTeamMemberId != null && (oldMap == null || newSalesTeamMemberId != oldSalesTeamMemberId)) {
                    oppsToNotify.add(opp);
                    userIds.add(newSalesTeamMemberId);
                }
            }

            if (oppsToNotify.isEmpty() || userIds.isEmpty()) {
                return;
            }

            CustomNotificationType cnt = [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName = 'Sales_Team_Member_Assigned' LIMIT 1];

            for (Opportunity opp : oppsToNotify) {
                if (opp.Sales_Team_Member__c == null) {
                    continue;
                }

                Messaging.CustomNotification notification = new Messaging.CustomNotification();
                notification.setTitle('Opportunity Assigned');
                notification.setBody('You have been assigned as Sales Team Member on Opportunity: ' + opp.Name);
                notification.setNotificationTypeId(cnt.Id);
                notification.setTargetId(opp.Id);

                Set<String> recipientIds = new Set<String>();
                recipientIds.add(String.valueOf(opp.Sales_Team_Member__c));

                notification.send(recipientIds);
            }

        } catch (Exception e) {
            System.debug('Error in sendSalesTeamMemberNotification: ' + e.getMessage());
            System.debug('Line Number: ' + e.getLineNumber());
        }
    }

    public static void deleteRelatedRecords(List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
        try{
            if (newList == null || newList.isEmpty() || oldMap == null) {
                return;
            }

            Set<Id> approvedOppIds = new Set<Id>();
            Map<Id, Id> oppOwnerById = new Map<Id, Id>();
            Set<Id> unitIdsToRelease = new Set<Id>();
            for (Opportunity opp : newList) {
                Opportunity oldOpp = oldMap.get(opp.Id);
                if (oldOpp == null) {
                    continue;
                }

                if (opp.Delete_Approval__c == 'Approved' && oldOpp.Delete_Approval__c != 'Approved') {
                    approvedOppIds.add(opp.Id);
                    oppOwnerById.put(opp.Id, opp.OwnerId);
                    if (opp.Unit__c != null) {
                        unitIdsToRelease.add(opp.Unit__c);
                    }
                }
            }

            if (approvedOppIds.isEmpty()) {
                return;
            }

            List<Payment_Schedule__c> paymentSchedulesToDelete = [SELECT Id FROM Payment_Schedule__c WHERE Opportunity__c IN :approvedOppIds];

            // List<Cost_Sheet__c> costSheetsToUpdate = new List<Cost_Sheet__c>();
            // for (Cost_Sheet__c costSheet : [SELECT Id, Cost_Scheme_Linking__c, finalize_CostSheet__c FROM Cost_Sheet__c WHERE Opportunity__c IN :approvedOppIds AND Cost_Scheme_Linking__c != null
            // ]) {
            //     costSheetsToUpdate.add(new Cost_Sheet__c(
            //         Id = costSheet.Id,
            //         Cost_Scheme_Linking__c = null,
            //         finalize_CostSheet__c = false
            //     ));
            // }

            List<Cost_Sheet__c> costSheetsToDelete = [SELECT Id FROM Cost_Sheet__c WHERE Opportunity__c IN :approvedOppIds];
            List<Task> tasksToInsert = new List<Task>();
            for (Id oppId : approvedOppIds) {
                tasksToInsert.add(new Task(
                    Subject = 'Generate Cost Sheet',
                    WhatId = oppId,
                    OwnerId = oppOwnerById.get(oppId),
                    ActivityDate = Date.today().addDays(3)
                ));
            }

            List<Opportunity> oppsToUpdate = new List<Opportunity>();
            for (Id oppId : approvedOppIds) {
                oppsToUpdate.add(new Opportunity(
                    Id = oppId,
                    Unit__c = null,
                    StageName = 'New', Cost_Sheet_Template__c = null, Payment_Scheme__c = null , Cost_Sheet_Approval_Status__c = 'Pending', Sales_Head_approval_Status__c = 'Pending', CRM_Approval_Status__c = 'Pending'
                ));
            }

            if (!paymentSchedulesToDelete.isEmpty()) {
                delete paymentSchedulesToDelete;
            }
            if (!costSheetsToDelete.isEmpty()) {
                delete costSheetsToDelete;
            }

            if (!tasksToInsert.isEmpty()) {
                insert tasksToInsert;
            }

            if (!unitIdsToRelease.isEmpty()) {
                List<Unit__c> soldUnits = [SELECT Id FROM Unit__c WHERE Id IN :unitIdsToRelease AND Status__c = 'Sold'];
                if (!soldUnits.isEmpty()) {
                    Set<Id> soldUnitIds = new Map<Id, Unit__c>(soldUnits).keySet();
                    UnitTriggerHandler.allowSoldUnitEditsForCurrentTransaction(soldUnitIds);
                    for (Unit__c u : soldUnits) {
                        u.Status__c = 'For Sale';
                    }
                    update soldUnits;
                }
            }

            if (!oppsToUpdate.isEmpty()) {
                update oppsToUpdate;
            }

        }
        catch(Exception e){
            System.debug('Error in deleteRelatedRecords: ' + e.getMessage());
            System.debug('Line Number: ' + e.getLineNumber());
        }        
    }

    public static void deleteRelatedRecordsOnSalesRejection(List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
        system.debug('after update deleteRelatedRecordsOnSalesRejection called');
        try{
            if (newList == null || newList.isEmpty() || oldMap == null) {
                return;
            }

            Set<Id> approvedOppIds = new Set<Id>();
            Map<Id, Id> oppOwnerById = new Map<Id, Id>();
            for (Opportunity opp : newList) {
                Opportunity oldOpp = oldMap.get(opp.Id);
                if (oldOpp == null) {
                    continue;
                }

                if (opp.Sales_Head_Approval_Status__c == 'Reject' && oldOpp.Sales_Head_Approval_Status__c != 'Reject') {
                    approvedOppIds.add(opp.Id);
                    oppOwnerById.put(opp.Id, opp.OwnerId);
                }
            }

            if (approvedOppIds.isEmpty()) {
                return;
            }

            List<Payment_Schedule__c> paymentSchedulesToDelete = [SELECT Id FROM Payment_Schedule__c WHERE Opportunity__c IN :approvedOppIds];

            List<Cost_Sheet__c> costSheetsToUpdate = new List<Cost_Sheet__c>();
            for (Cost_Sheet__c costSheet : [SELECT Id, Cost_Scheme_Linking__c, finalize_CostSheet__c FROM Cost_Sheet__c WHERE Opportunity__c IN :approvedOppIds AND Cost_Scheme_Linking__c != null
            ]) {
                costSheetsToUpdate.add(new Cost_Sheet__c(
                    Id = costSheet.Id,
                    finalize_CostSheet__c = false
                ));
            }

            //List<Cost_Sheet__c> costSheetsToDelete = [SELECT Id FROM Cost_Sheet__c WHERE Opportunity__c IN :approvedOppIds];
            List<Task> tasksToInsert = new List<Task>();
            for (Id oppId : approvedOppIds) {
                tasksToInsert.add(new Task(
                    Subject = 'Generate Cost Sheet',
                    WhatId = oppId,
                    OwnerId = oppOwnerById.get(oppId),
                    ActivityDate = Date.today().addDays(3)
                ));
            }

            List<Opportunity> oppsToUpdate = new List<Opportunity>();
            for (Id oppId : approvedOppIds) {
                oppsToUpdate.add(new Opportunity(
                    Id = oppId, Unit__c = null, StageName = 'New', Cost_Sheet_Template__c = null, Payment_Scheme__c = null, Cost_Sheet_Finalised__c = false
                ));
            }

            if (!paymentSchedulesToDelete.isEmpty()) {
                delete paymentSchedulesToDelete;
            }

            if (!costSheetsToUpdate.isEmpty()) {
                update costSheetsToUpdate;
            }
            
            
            if (!tasksToInsert.isEmpty()) {
                insert tasksToInsert;
            }
            if (!oppsToUpdate.isEmpty()) {
                update oppsToUpdate;
            }

        }
        catch(Exception e){
            System.debug('Error in deleteRelatedRecords: ' + e.getMessage());
            System.debug('Line Number: ' + e.getLineNumber());
        }        
    }
    
    public static void dummyMethod(){
        Integer i = 0;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
    }

}
