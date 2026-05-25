public without Sharing  class agreementSignedByCustomerController {
    @AuraEnabled
    public static String updateRelOppAndCompleteTask(String taskId){
        if(taskId == null){
            return 'Task Id is absent';
        }
        try{
            Task task = [SELECT Id, WhatId, Status FROM Task WHERE Id =: taskId LIMIT 1];
            if(task != null){
                Opportunity opp = [SELECT Id, StageName, Agreement_Signed_By_Customer__c FROM Opportunity WHERE Id =: task.WhatId LIMIT 1];
                if(opp != null){
                    opp.StageName = 'Agreement Signed';
                    opp.Agreement_Signed_By_Customer__c = true;
                    update opp;
                }
                task.Status = 'Completed';
                update task;
            }
            return 'Success';
        }catch(Exception e){
            System.debug('Error ---> '+e.getMessage()+' @ Line '+e.getLineNumber());
            return 'Error';
        }
    }
}