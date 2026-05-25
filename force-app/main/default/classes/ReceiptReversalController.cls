public with sharing class ReceiptReversalController {
    public class receiptWrapper {
        @AuraEnabled public List<Receipt__c> relatedReceipts { get; set; }
        @AuraEnabled public String clientName { get; set; }
    }
    @AuraEnabled
    public static receiptWrapper getRelReceipts(String unitId){
        System.debug('Received Unit Id: ' + unitId);
        receiptWrapper wrapper = new receiptWrapper();
        if(String.isEmpty(unitId)){
            return null;
        }else{
            try{
                List<Receipt__c> relatedReceipts = [SELECT Id, Name, Receipt_Date__c, Amount__c, Bank__c, Cheque_Number__c, Cheque_Date__c, Receipt_Number__c, Opportunity__c, Opportunity__r.Unit__c, Demand_Letter__c, Status__c FROM Receipt__c WHERE Opportunity__r.Unit__c = :unitId AND Status__c NOT IN ('Bounced/Cancelled', 'Represent')];
                System.debug('Related Receipts: ' + relatedReceipts);
                if(!relatedReceipts.isEmpty()){
                    wrapper.relatedReceipts = relatedReceipts;
                }
                List<Opportunity> opp = [SELECT Id, Name, Unit__c, Account.Name FROM Opportunity WHERE Unit__c = :unitId];
                if(!opp.isEmpty()){
                    wrapper.clientName = opp[0].Account.Name;
                }
                System.debug('Related Receipts: ' + wrapper.relatedReceipts);
                System.debug('Client Name: ' + wrapper.clientName);
                return wrapper;
            }
            catch(Exception e){
                System.debug('Error while fetching receipts: ' + e.getMessage() + 'at line: ' + e.getLineNumber());
                return null;
            }
        }
    }
    @AuraEnabled
    public static string saveReceiptChanges(List<Receipt__c> receipts, String typeOfCheque, Date bouncedDate, String bouncedReason){
        try {
            if(!receipts.isEmpty()){
                System.debug('Received Receipt: ' + receipts);
                List<Receipt__c> receiptsToUpdate = new List<Receipt__c>();
                if(typeOfCheque == 'Same Cheque'){
                    for(Receipt__c receipt : receipts){
                        receipt.Bounced_Date__c = bouncedDate;
                        receipt.Bounced_Reason__c = bouncedReason;
                        receipt.Status__c = 'Represent';
                        receiptsToUpdate.add(receipt);
                    }
                } else if(typeOfCheque == 'New Cheque'){
                    for(Receipt__c receipt : receipts){
                        receipt.Bounced_Date__c = bouncedDate;
                        receipt.Bounced_Reason__c = bouncedReason;
                        receipt.Status__c = 'Bounced/Cancelled';
                        receiptsToUpdate.add(receipt);
                    }
                }
                update receiptsToUpdate;
                System.debug('Updated Receipts: ' + receiptsToUpdate);
                return 'SUCCESS';
            } else {
                System.debug('No receipts found to update.');
                return 'ERROR';
            }
        } catch (Exception e) {
            System.debug('Error while saving receipt changes: ' + e.getMessage() + 'at line: ' + e.getLineNumber());
            return 'ERROR';
        }
    }
}