public class BatchToDeleteDuplicateLeads implements Database.Batchable<SObject> {
    private List<Id> leadIdsToDelete;

    public BatchToDeleteDuplicateLeads(List<Lead> leadsToDelete) {
        this.leadIdsToDelete = new List<Id>();
        for (Lead lead : leadsToDelete) {
            this.leadIdsToDelete.add(lead.Id);
        }
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT Id FROM Lead WHERE Id IN :leadIdsToDelete]);
    }

    public void execute(Database.BatchableContext bc, List<Lead> scope) {
        try {
			System.debug('scope==>'+scope);
            delete scope; 
        } catch (Exception ex) {
            System.debug('Error while deleting leads: ' + ex.getMessage());
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Batch job finished: Deleted duplicate leads.');
    }
}