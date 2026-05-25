public with sharing class LeadTaskController {
    @AuraEnabled(cacheable=true)
    public static List<Task> getRelatedTasks(Id leadId) {
        return [SELECT Id, Status,Priority FROM Task WHERE WhoId = :leadId];
    }
}