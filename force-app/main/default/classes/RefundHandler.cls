public class RefundHandler {
    
    public static void handleBefore(List<Refund__c> newList, Boolean isInsert) {
        Set<Id> receiptIds = new Set<Id>();
        
        for (Refund__c ref : newList) {
            if (ref.Receipt__c != null) {
                receiptIds.add(ref.Receipt__c);
            }
        }
        
        if (!receiptIds.isEmpty()) {
            Map<Id, Receipt__c> receiptsMap = new Map<Id, Receipt__c>([
                SELECT Id, Name, Approval_Status__c, Amount__c, Opportunity__c,
                Opportunity__r.Name, Unit_Name__c
                FROM Receipt__c
                WHERE Id IN :receiptIds
            ]);
            
            for (Refund__c ref : newList) {
                Receipt__c relatedReceipt = receiptsMap.get(ref.Receipt__c);
                
                if (relatedReceipt == null) {
                    ref.addError('Invalid Receipt selected');
                    continue;
                }
                
                if (relatedReceipt.Approval_Status__c != 'Approved') {
                    ref.addError('Cannot create refund. The associated Receipt (' + relatedReceipt.Name + ') is not approved. Current status: ' + relatedReceipt.Approval_Status__c);
                }
                
                if (ref.Refund_Amount__c > relatedReceipt.Amount__c) {
                    ref.addError('Refund amount (₹' + ref.Refund_Amount__c + ') cannot exceed Receipt amount (₹' + relatedReceipt.Amount__c + ')');
                }
                
                if (isInsert && ref.Approval_Status__c == null) {
                    ref.Approval_Status__c = 'Pending';
                }
            }
        }
    }
    
    public static void handleAfterInsert(List<Refund__c> newList) {
        Set<Id> refundsToSubmit = new Set<Id>();
        Set<Id> approvedRefunds = new Set<Id>();
        
        for (Refund__c ref : newList) {
            if (ref.Approval_Status__c == 'Pending') {
                refundsToSubmit.add(ref.Id);
            } else if (ref.Approval_Status__c == 'Approved') {
                approvedRefunds.add(ref.Id);
            }
        }
        
        for (Id refundId : refundsToSubmit) {
            submitForApproval(refundId);
        }
        
        for (Id refundId : approvedRefunds) {
            processRefundDeduction(refundId);
        }
    }
    
    public static void handleAfterUpdate(List<Refund__c> newList, Map<Id, Refund__c> oldMap) {
        List<Refund__c> approvedRefunds = new List<Refund__c>();
        
        for (Refund__c ref : newList) {
            Refund__c oldRef = oldMap.get(ref.Id);
            
            if (ref.Approval_Status__c == 'Approved' && (oldRef == null || oldRef.Approval_Status__c != 'Approved')) {
                approvedRefunds.add(ref);
            }
        }
        
        for (Refund__c ref : approvedRefunds) {
            processRefundDeduction(ref.Id);
        }
    }
    
    public static void submitForApproval(Id refundId) {
        try {
            System.debug('=== Submitting Refund for Approval ===');
            System.debug('Refund ID: ' + refundId);
            
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setObjectId(refundId);
            req.setSubmitterId(UserInfo.getUserId());
            req.setProcessDefinitionNameOrId('Refund_Approval');
            req.setSkipEntryCriteria(true);
            
            Approval.ProcessResult result = Approval.process(req);
            
            System.debug('Approval submitted successfully: ' + result.isSuccess());
            
        } catch(Exception e) {
            System.debug('ERROR submitting refund for approval: ' + e.getMessage());
        }
    }
    
    public static void processRefundDeduction(Id refundId) {
        try {
            Refund__c refund = [
                SELECT Id, Name, Refund_Amount__c, Refund_Date__c, Receipt__c,
                Receipt__r.Id, Receipt__r.Opportunity__c, Receipt__r.Amount__c, Receipt__r.Name,
                Remarks__c
                FROM Refund__c
                WHERE Id = :refundId
                LIMIT 1
            ];
            
            System.debug('=== Processing Approved Refund ===');
            System.debug('Refund ID: ' + refund.Id);
            System.debug('Refund Name: ' + refund.Name);
            System.debug('Refund Amount: ₹' + refund.Refund_Amount__c);
            System.debug('Receipt: ' + refund.Receipt__r.Name);
            System.debug('Opportunity ID: ' + refund.Receipt__r.Opportunity__c);
            
            Decimal remainingRefundAmount = refund.Refund_Amount__c;
            
            List<Payment_Schedule__c> paymentSchedules = [
                SELECT Id, Name, Total_Received_Amount__c, CreatedDate,
                Total_Due_Amount__c, Agreement_Value__c
                FROM Payment_Schedule__c
                WHERE Opportunity__c = :refund.Receipt__r.Opportunity__c
                AND Total_Received_Amount__c > 0
                ORDER BY CreatedDate DESC
            ];
            
            System.debug('Found ' + paymentSchedules.size() + ' payment schedules with balance');
            
            if(paymentSchedules.isEmpty()) {
                System.debug('ERROR: No payment schedules found with positive balance');
                return;
            }
            
            List<Payment_Schedule__c> schedulesToUpdate = new List<Payment_Schedule__c>();
            Decimal totalDeducted = 0;
            
            for(Payment_Schedule__c ps : paymentSchedules) {
                if(remainingRefundAmount <= 0) {
                    break;
                }
                
                Decimal currentAmount = ps.Total_Received_Amount__c;
                Decimal amountToDeduct = 0;
                
                System.debug('Processing PS: ' + ps.Name);
                System.debug('  Current Received: ₹' + currentAmount);
                System.debug('  (Due: ₹' + ps.Total_Due_Amount__c + ', Agreement: ₹' + ps.Agreement_Value__c + ')');
                
                if(currentAmount >= remainingRefundAmount) {
                    amountToDeduct = remainingRefundAmount;
                    ps.Total_Received_Amount__c = ps.Total_Received_Amount__c - remainingRefundAmount;
                    System.debug('  Deducting ₹' + amountToDeduct + ' (full remaining amount)');
                    remainingRefundAmount = 0;
                } else {
                    amountToDeduct = currentAmount;
                    ps.Total_Received_Amount__c = 0;
                    remainingRefundAmount = remainingRefundAmount - currentAmount;
                    System.debug('  Deducting ₹' + amountToDeduct + ' (full PS balance)');
                }
                
                totalDeducted += amountToDeduct;
                schedulesToUpdate.add(ps);
                System.debug('  New Received balance: ₹' + ps.Total_Received_Amount__c);
            }
            
            if(!schedulesToUpdate.isEmpty()) {
                update schedulesToUpdate;
                System.debug('Updated ' + schedulesToUpdate.size() + ' payment schedules');
                System.debug('Total deducted from Total_Received_Amount__c: ₹' + totalDeducted);
            }
            
            if(refund.Receipt__c != null) {
                Decimal currentReceiptAmount = refund.Receipt__r.Amount__c == null ? 0 : refund.Receipt__r.Amount__c;
                Decimal newReceiptAmount = currentReceiptAmount - refund.Refund_Amount__c;
                decimal amntPaidExclTax = newReceiptAmount / (1.05);
                decimal cgst = amntPaidExclTax * 0.025;
                decimal sgst = amntPaidExclTax * 0.025;
                system.debug('Current Receipt Amount: ₹' + currentReceiptAmount);
                system.debug('New Receipt Amount: ₹' + newReceiptAmount);
                if(newReceiptAmount < 0) {
                    newReceiptAmount = 0;
                }
                
                Receipt__c receiptToUpdate = new Receipt__c(
                    Id = refund.Receipt__c,
                    Amount__c = newReceiptAmount,
                    Amount_Paid_Excluding_TAX__c = amntPaidExclTax,
                    CGST__c = cgst,
                    SGST__c = sgst
                );
                
                if(receiptToUpdate != null){
                    update receiptToUpdate;
                    
                }
                System.debug('Updated Receipt Amount to: ₹' + newReceiptAmount);
            }
            
            if(remainingRefundAmount > 0) {
                System.debug('WARNING: Partial refund only. Remaining: ₹' + remainingRefundAmount);
            } else {
                System.debug('SUCCESS: Full refund processed successfully');
            }
            
        } catch(Exception e) {
            System.debug('ERROR in refund processing: ' + e.getMessage());
            System.debug('Stack Trace: ' + e.getStackTraceString());
        }
    }
    
}