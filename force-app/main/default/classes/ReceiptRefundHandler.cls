public class ReceiptRefundHandler {
    
    // This method will be called from trigger when status becomes 'Approved'
    public static void processRefundOnApproval(List<Receipt__c> newRecs, Map<Id, Receipt__c> oldMap) {
        
        for(Receipt__c rec : newRecs) {
            Receipt__c oldRec = oldMap.get(rec.Id);
            
            // Check if status changed to 'Approved' (either by approval process or manually)
            if(rec.Refund_Status__c == 'Approved' && 
               (oldRec == null || oldRec.Refund_Status__c != 'Approved')) {
                
                System.debug('=== Refund Approved - Processing Deduction ===');
                System.debug('Receipt ID: ' + rec.Id);
                System.debug('Receipt Name: ' + rec.Name);
                System.debug('Refund Amount: ₹' + rec.Refund__c);
                System.debug('Original Amount: ₹' + rec.Amount__c);
                System.debug('Opportunity ID: ' + rec.Opportunity__c);
                
                // Process the refund deduction
                processRefundDeduction(rec);
            }
        }
    }
    
    private static void processRefundDeduction(Receipt__c receipt) {
        try {
            Decimal remainingRefundAmount = receipt.Refund__c;
            System.debug('Starting refund deduction. Amount to deduct: ₹' + remainingRefundAmount);
            
            // Get Payment Schedules with received amounts > 0 (latest first)
            List<Payment_Schedule__c> paymentSchedules = [
                SELECT Id, Name, Total_Received_Amount__c, CreatedDate
                FROM Payment_Schedule__c 
                WHERE Opportunity__c = :receipt.Opportunity__c 
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
            
            // Process refund against payment schedules
            for(Payment_Schedule__c ps : paymentSchedules) {
                if(remainingRefundAmount <= 0) break;
                
                Decimal currentAmount = ps.Total_Received_Amount__c;
                Decimal amountToDeduct = 0;
                
                System.debug('Processing PS: ' + ps.Name + ' | Current balance: ₹' + currentAmount);
                
                if(currentAmount >= remainingRefundAmount) {
                    amountToDeduct = remainingRefundAmount;
                    ps.Total_Received_Amount__c -= remainingRefundAmount;
                    System.debug('Deducting ₹' + amountToDeduct + ' (full remaining amount)');
                    remainingRefundAmount = 0;
                } else {
                    amountToDeduct = currentAmount;
                    ps.Total_Received_Amount__c = 0;
                    remainingRefundAmount -= currentAmount;
                    System.debug('Deducting ₹' + amountToDeduct + ' (full PS balance)');
                }
                
                totalDeducted += amountToDeduct;
                schedulesToUpdate.add(ps);
                System.debug('New PS balance: ₹' + ps.Total_Received_Amount__c);
            }
            
            // Update payment schedules
            if(!schedulesToUpdate.isEmpty()) {
                update schedulesToUpdate;
                System.debug('Updated ' + schedulesToUpdate.size() + ' payment schedules');
                System.debug('Total deducted: ₹' + totalDeducted);
            }
            
            if(remainingRefundAmount > 0) {
                System.debug('WARNING: Unable to deduct full refund. Remaining: ₹' + remainingRefundAmount);
            } else {
                System.debug('SUCCESS: Full refund processed successfully');
            }
            
        } catch(Exception e) {
            System.debug('ERROR in refund processing: ' + e.getMessage());
        }
    }
    
    // Test method
    public static void testRefundProcessing(Id receiptId) {
        Receipt__c rec = [SELECT Id, Refund_Status__c, Refund__c, Amount__c, Opportunity__c 
                          FROM Receipt__c WHERE Id = :receiptId];
        processRefundDeduction(rec);
    }
}