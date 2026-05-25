public without sharing class TaskAuraHelper {
    @AuraEnabled
    Public Static Task getCurrentTaskRecord(String recordId){
        Task TaskRec = new Task();
        try{
            if(!String.isBlank(recordId)){
                TaskRec = [SELECT Id,Subject,Remarks__c,Description,Current_Task_Status__c,Next_Task_Status__c,Status,WhoId,WhatId,ActivityDate,Task_Master_del__c,Task_Master_del__r.Name,Task_Master_del__r.Object_Type__c,Task_Master_del__r.Task_Subject__c,Task_Master_del__r.Action_Type__c,Task_Master_del__r.Action_URL__c FROM Task WHERE Id=:recordId];
                system.debug('TaskRec ====> '+TaskRec);
                if(TaskRec !=null){
                    System.debug('TaskRec==>'+TaskRec);
                    return TaskRec;
                }
            }
        }catch(Exception e){
            System.debug('The Error ::'+e.getMessage() +' AND Error Line No :'+e.getLineNumber());
        }
        return null;
    }
}