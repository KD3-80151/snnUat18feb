public with sharing class CallDetailsTaskHandler {
    
    public static void createCallDetailsTask(List<Call_Details__c> callDetailsList) {
        List<Task> tasksToInsert = new List<Task>();

        for (Call_Details__c callDetail : callDetailsList) {
            if(callDetail.Status__c == 'Customer Busy' || callDetail.Status__c == 'EXECUTIVE BUSY' || callDetail.Status__c == 'NOANSWER') {
                Task task = new Task();
                task.Subject = 'Call was not picked please take followup in next 2 hrs';
                task.WhoId = callDetail.Id;
                task.OwnerId = callDetail.OwnerId;
                task.Status = 'Not Started';
                task.Priority = 'Normal';
            tasksToInsert.add(task);
            }
        }

        if (!tasksToInsert.isEmpty()) {
            insert tasksToInsert;
        }
    }
}