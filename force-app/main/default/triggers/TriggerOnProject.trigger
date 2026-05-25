trigger TriggerOnProject on Project__c (After insert) {
    DocumentCreationHandler dCH = new DocumentCreationHandler();
    if(Trigger.isAfter && Trigger.isInsert) {
        system.debug('inside after insert');
        List<Id> accIds = new List<Id>();
        for(Id accId : Trigger.newMap.keySet()) {
            accIds.add(accId);
        }
        System.enqueueJob(new QueueableCreateFolderGDrive(accIds));
    }

}