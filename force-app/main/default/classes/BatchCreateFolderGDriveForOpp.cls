public without sharing class BatchCreateFolderGDriveForOpp implements Database.Batchable<SObject>, Database.AllowsCallouts {

    public String query;

    public BatchCreateFolderGDriveForOpp() {
        this.query = 'SELECT Id FROM Opportunity WHERE CreatedDate = TODAY';
    }

    public BatchCreateFolderGDriveForOpp(String query) {
        this.query = query;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Opportunity> scope) {
        List<Id> oppIds = new List<Id>();
        for (Opportunity opp : scope) {
            oppIds.add(opp.Id);
        }

        if (!oppIds.isEmpty()) {
            System.enqueueJob(new QueueableCreateFolderGDrive(oppIds));
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('BatchCreateFolderGDriveForOpp completed');
    }
}
