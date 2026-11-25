public without sharing class DocumentTriggerHandler {

    /**
     * When a Document__c is created manually under a Project (e.g. from the Project's
     * "Documents" related list), create its Google Drive folder inside the Project folder
     * and store the folder id in Document_Id__c.
     *
     * Documents created from async code (QueueableCreateFolderGDrive / DocumentCreationHandler)
     * are skipped because those processes already create the folders themselves.
     */
    public static void createFolderForProjectDocuments(List<Document__c> newDocs) {
        if (System.isQueueable() || System.isFuture() || System.isBatch() || System.isScheduled()) {
            return;
        }

        Set<Id> projectIds = new Set<Id>();
        List<Document__c> candidates = new List<Document__c>();
        for (Document__c doc : newDocs) {
            if (doc.Project__c != null
                && String.isBlank(doc.Document_Id__c)
                && doc.Opportunity__c == null
                && doc.Account__c == null
                && doc.Applicant__c == null
                && doc.Parent_Document__c == null) {
                candidates.add(doc);
                projectIds.add(doc.Project__c);
            }
        }
        if (candidates.isEmpty()) {
            return;
        }

        // Only create the sub-folder when the Project's own Drive folder exists
        Map<Id, Project__c> projects = new Map<Id, Project__c>(
            [SELECT Id, FolderId__c FROM Project__c WHERE Id IN :projectIds AND FolderId__c != null]
        );

        List<Id> docIds = new List<Id>();
        for (Document__c doc : candidates) {
            if (projects.containsKey(doc.Project__c)) {
                docIds.add(doc.Id);
            }
        }

        if (!docIds.isEmpty() && Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()) {
            System.enqueueJob(new QueueableCreateFolderGDrive(docIds));
        }
    }
}