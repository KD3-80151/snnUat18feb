public without sharing class PaymentConfirmationController {

	 @AuraEnabled
    public static void updateOpportunityStage(Id taskId) {
		System.debug('taskId==>'+taskId);

		Task taskRecord = [select id,WhatId,Status from Task Where Id =: taskId Limit 1];
        
        Opportunity opp = [SELECT Id, StageName,OwnerId FROM Opportunity WHERE Id = :taskRecord.WhatId LIMIT 1];
        
        opp.StageName = 'Payment Confirmation';
        update opp;

		taskRecord.Status = 'Completed';
		update taskRecord;

		Task newRecord = new Task();
		newRecord.Subject = 'Add Receipt Details/Token Amount';
		newRecord.ActivityDate = Date.newInstance(System.now().addDays(3).year(), 
                                  System.now().addDays(3).month(), 
                                  System.now().addDays(3).day());  // Adds 72 hours (3 days) to the current time

		 newRecord.WhatId = opp.Id;
        newRecord.OwnerId = opp.OwnerId;
		insert newRecord;
    }
}