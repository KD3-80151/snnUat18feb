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

        receipt.Opportunity__c = opportunityId;
            update receipt;
            System.debug('Updated Receipt: ' + receipt.Id + ' with Opportunity: ' + opportunityId);
        } catch (Exception e) {
            throw new AuraHandledException('Failed to update the Receipt: ' + e.getMessage());
        }
    }
	
}