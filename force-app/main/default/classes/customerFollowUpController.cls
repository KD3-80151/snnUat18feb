public without sharing class customerFollowUpController {

    public static final String LOST_STAGE = 'Closed Lost';

    @AuraEnabled
    public static String saveFollowUp(String taskId, String customerResponse, String title, String remarks, String lossReason) {
        if (String.isBlank(taskId)) {
            throw new AuraHandledException('Task Id is missing.');
        }
        if (customerResponse != 'Interested' && customerResponse != 'Not Interested') {
            throw new AuraHandledException('Please select Customer Response.');
        }

        Savepoint sp = Database.setSavepoint();
        try {
            List<Task> tasks = [SELECT Id, WhatId, Status FROM Task WHERE Id = :taskId LIMIT 1];
            if (tasks.isEmpty() || tasks[0].WhatId == null) {
                throw new AuraHandledException('Opportunity not found for this task.');
            }
            Task task = tasks[0];
            Opportunity opp = new Opportunity(Id = task.WhatId, Customer_Response__c = customerResponse);

            if (customerResponse == 'Interested') {
                if (String.isBlank(title) || String.isBlank(remarks)) {
                    throw new AuraHandledException('Title and Remarks are required.');
                }
                opp.Next_Action_Reason__c = (title.trim() + ' - ' + remarks.trim()).abbreviate(2000);
                insert new Communication_Notes__c(
                    Opportunity__c = opp.Id,
                    Title__c = title.trim(),
                    Remarks__c = remarks.trim()
                );
            } else {
                if (String.isBlank(lossReason) || String.isBlank(remarks)) {
                    throw new AuraHandledException('Opportunity Lost Reason and Remarks are required.');
                }
                opp.Loss_Reason__c = lossReason;
                opp.Next_Action_Reason__c = (lossReason + ' - ' + remarks.trim()).abbreviate(2000);
                opp.StageName = LOST_STAGE;
                insert new Communication_Notes__c(
                    Opportunity__c = opp.Id,
                    Title__c = 'Not Interested - ' + lossReason,
                    Remarks__c = remarks.trim()
                );
            }
            update opp;

            task.Status = 'Completed';
            update task;
            return 'Success';
        } catch (AuraHandledException e) {
            Database.rollback(sp);
            throw e;
        } catch (Exception e) {
            Database.rollback(sp);
            throw new AuraHandledException(e.getMessage());
        }
    }
}