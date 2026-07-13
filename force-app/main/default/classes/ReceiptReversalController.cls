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
                List<Receipt__c> relatedReceipts = [SELECT Id, Name, Receipt_Date__c, Amount__c, Bank__c, Cheque_Number__c, Cheque_Date__c, Receipt_Number__c, Opportunity__c, Opportunity__r.Unit__c, Demand_Letter__c, Status__c FROM Receipt__c WHERE Opportunity__r.Unit__c = :unitId AND Mode_Of_Payment__c = 'Cheque' AND Type__c = 'Tax Invoice' AND Approval_Status__c = 'Approved' AND Status__c NOT IN ('Bounced/Cancelled', 'Represent') order by Name];
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
                Set<Id> receiptIds = new Set<Id>();
                for (Receipt__c receipt : receipts) {
                    if (receipt.Id != null) {
                        receiptIds.add(receipt.Id);
                    }
                }

                Map<Id, Receipt__c> receiptDetailsById = new Map<Id, Receipt__c>();
                if (!receiptIds.isEmpty()) {
                    receiptDetailsById = new Map<Id, Receipt__c>([SELECT Id, Opportunity__c, Amount__c, TDS_Amount__c FROM Receipt__c WHERE Id IN :receiptIds]);
                }

                List<Tax_Invoice__c> taxInvoicesToDelete = new List<Tax_Invoice__c>();
                if (!receiptIds.isEmpty()) {
                    taxInvoicesToDelete = [SELECT Id FROM Tax_Invoice__c WHERE Receipt__c IN :receiptIds];
                }

                List<Receipt__c> receiptsToUpdate = new List<Receipt__c>();
                Map<Id, Decimal> oppToReceiptAmountToReverse = new Map<Id, Decimal>();
                if(typeOfCheque == 'Same Cheque'){
                    for(Receipt__c receipt : receipts){
                        receipt.Bounced_Date__c = bouncedDate;
                        receipt.Bounced_Reason__c = bouncedReason;
                        receipt.Status__c = 'Represent';
                        receipt.Approval_Status__c = null;
                        receiptsToUpdate.add(receipt);
                        addReceiptAmountForReversal(receipt, receiptDetailsById, oppToReceiptAmountToReverse);
                    }
                } else if(typeOfCheque == 'New Cheque'){
                    for(Receipt__c receipt : receipts){
                        receipt.Bounced_Date__c = bouncedDate;
                        receipt.Bounced_Reason__c = bouncedReason;
                        receipt.Status__c = 'Bounced/Cancelled';
                        receipt.Approval_Status__c = null;
                        receiptsToUpdate.add(receipt);
                        addReceiptAmountForReversal(receipt, receiptDetailsById, oppToReceiptAmountToReverse);
                    }
                }

                List<Payment_Schedule__c> paymentSchedulesToUpdate = getPaymentSchedulesToReverse(oppToReceiptAmountToReverse);
                if (!paymentSchedulesToUpdate.isEmpty()) {
                    update paymentSchedulesToUpdate;
                }

                if (!taxInvoicesToDelete.isEmpty()) {
                    delete taxInvoicesToDelete;
                }

                update receiptsToUpdate;

                if (typeOfCheque == 'Same Cheque') {
                    submitReceiptsForApproval(receiptsToUpdate);
                }

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

    private static void addReceiptAmountForReversal(Receipt__c receipt, Map<Id, Receipt__c> receiptDetailsById, Map<Id, Decimal> oppToReceiptAmountToReverse) {
        system.debug('Processing receipt for reversal: ' + receipt.Id);
        Receipt__c receiptDetail = receiptDetailsById.get(receipt.Id);
        system.debug('Retrieved receipt detail for Id: ' + receipt.Id);
        if (receiptDetail == null || receiptDetail.Opportunity__c == null) {
            return;
        }

        Decimal receiptAmount = getAmount(receiptDetail.Amount__c) + getAmount(receiptDetail.TDS_Amount__c);
        if (receiptAmount <= 0) {
            return;
        }
        system.debug('Calculated receipt amount for Id: ' + receipt.Id + ' with value: ' + receiptAmount);

        Decimal existingAmount = oppToReceiptAmountToReverse.containsKey(receiptDetail.Opportunity__c) ? oppToReceiptAmountToReverse.get(receiptDetail.Opportunity__c) : 0;
        system.debug('Existing amount for Opportunity Id: ' + receiptDetail.Opportunity__c + ' is: ' + existingAmount);
        oppToReceiptAmountToReverse.put(receiptDetail.Opportunity__c, existingAmount + receiptAmount);
    }

    private static List<Payment_Schedule__c> getPaymentSchedulesToReverse(Map<Id, Decimal> oppToReceiptAmountToReverse) {
        List<Payment_Schedule__c> paymentSchedulesToUpdate = new List<Payment_Schedule__c>();
        if (oppToReceiptAmountToReverse.isEmpty()) {
            return paymentSchedulesToUpdate;
        }

        Map<Id, List<Payment_Schedule__c>> oppToPaymentSchedules = new Map<Id, List<Payment_Schedule__c>>();
        for (Payment_Schedule__c ps : [SELECT Id, Opportunity__c, Installment_Sequence__c, Total_Received_Amount__c FROM Payment_Schedule__c WHERE Opportunity__c IN :oppToReceiptAmountToReverse.keySet() AND Installment_Sequence__c != null ORDER BY Opportunity__c, Installment_Sequence__c DESC]) {
            if (!oppToPaymentSchedules.containsKey(ps.Opportunity__c)) {
                oppToPaymentSchedules.put(ps.Opportunity__c, new List<Payment_Schedule__c>());
            }
            oppToPaymentSchedules.get(ps.Opportunity__c).add(ps);
        }

        for (Id oppId : oppToReceiptAmountToReverse.keySet()) {
            Decimal remainingAmount = oppToReceiptAmountToReverse.get(oppId);
            system.debug('Processing Opportunity Id: ' + oppId + ' with amount to reverse: ' + remainingAmount);
            List<Payment_Schedule__c> paymentSchedules = oppToPaymentSchedules.get(oppId);

            if (paymentSchedules == null || paymentSchedules.isEmpty() || remainingAmount <= 0) {
                continue;
            }

            for (Payment_Schedule__c ps : paymentSchedules) {
                if (remainingAmount <= 0) {
                    break;
                }

                Decimal currentReceived = getAmount(ps.Total_Received_Amount__c);
                if (currentReceived <= 0) {
                    continue;
                }

                Decimal deduction = Math.min(currentReceived, remainingAmount);
                if (deduction <= 0) {
                    continue;
                }

                ps.Total_Received_Amount__c = currentReceived - deduction;
                remainingAmount -= deduction;
                System.debug('Updated Payment Schedule Id: ' + ps.Id + ' with new Total Received Amount: ' + ps.Total_Received_Amount__c + ' and remaining amount to reverse: ' + remainingAmount);
                paymentSchedulesToUpdate.add(ps);
            }
        }

        return paymentSchedulesToUpdate;
    }

    private static void submitReceiptsForApproval(List<Receipt__c> receiptsToSubmit) {
        if (receiptsToSubmit.isEmpty()) {
            return;
        }

        List<Receipt__c> approvalStatusUpdates = new List<Receipt__c>();
        for (Receipt__c receipt : receiptsToSubmit) {
            try {
                Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                req.setObjectId(receipt.Id);
                req.setProcessDefinitionNameOrId('Receipt_Approval_Process');
                Approval.process(req);

                approvalStatusUpdates.add(new Receipt__c(
                    Id = receipt.Id,
                    Approval_Status__c = 'Sent'
                ));
            } catch (Exception ex) {
                approvalStatusUpdates.add(new Receipt__c(
                    Id = receipt.Id,
                    Approval_Status__c = 'Approval Failed'
                ));
            }
        }

        if (!approvalStatusUpdates.isEmpty()) {
            update approvalStatusUpdates;
        }
    }

    private static Decimal getAmount(Decimal value) {
        system.debug('getAmount called with value: ' + value);
        return value == null ? 0 : value;
    }
}