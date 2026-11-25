public without sharing class TransferReceiptController {

	@AuraEnabled
    public static void updateReceiptOpportunity(String receiptId, String opportunityId) {
		
       

        try {
			 System.debug('Received Receipt ID: ' + receiptId);
        System.debug('Received Opportunity ID: ' + opportunityId);

        if (String.isEmpty(receiptId) || String.isEmpty(opportunityId)) {
            throw new AuraHandledException('Receipt ID and Opportunity ID must be provided.');
        }

        // Retrieve the Receipt record
        Receipt__c receipt = [SELECT Id, Opportunity__c FROM Receipt__c WHERE Id = :receiptId LIMIT 1];
        if (receipt == null) {
            throw new AuraHandledException('Receipt record not found.');
        }
        System.debug('Found Receipt: ' + receipt.Id);

        // Client (21 Nov): receipts can only be moved to an active (not Closed Lost) opportunity
        List<Opportunity> target = [SELECT Id, StageName FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
        if (target.isEmpty() || target[0].StageName == 'Closed Lost') {
            AuraHandledException closedLost = new AuraHandledException('Receipts can only be moved to an active opportunity, not a Closed Lost one.');
            closedLost.setMessage('Receipts can only be moved to an active opportunity, not a Closed Lost one.');
            throw closedLost;
        }

        receipt.Opportunity__c = opportunityId;
            update receipt;
            System.debug('Updated Receipt: ' + receipt.Id + ' with Opportunity: ' + opportunityId);
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException('Failed to update the Receipt: ' + e.getMessage());
        }
    }
	
}