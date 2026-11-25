trigger DocumentTrigger on Document__c (after insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        DocumentTriggerHandler.createFolderForProjectDocuments(Trigger.new);
    }
}