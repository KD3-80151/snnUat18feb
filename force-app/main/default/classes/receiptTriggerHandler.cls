public without sharing class receiptTriggerHandler {
    public static void generateDoc(List<Receipt__c> newRecords, Map<Id, Receipt__c> oldMap){
        if(!newRecords.isEmpty()){
            List<String> rcptIds = new List<String>();
            for(Receipt__c rcpt : newRecords){ 
                if(rcpt.Approval_Status__c == 'Approved' && oldMap.get(rcpt.Id).Approval_Status__c != 'Approved'){
                    rcptIds.add(rcpt.Id);
                }
            }
            if(!rcptIds.isEmpty()){
                QueueableToGenerateDocDigio queueable = new QueueableToGenerateDocDigio(rcptIds);
                System.enqueueJob(queueable);
            }
        }
    }
    
    
    public static void updtRcpdAmtOnPymntSchedule(List<Receipt__c> newRecords, Map<Id, Receipt__c> oldMap) {
        
        System.debug('newRecords==>' + newRecords);
        System.debug('oldMap==>' + oldMap);
        
        if (newRecords == null || newRecords.isEmpty() || oldMap == null) return;
        
        Map<Id, List<Receipt__c>> oppToApprovedReceipts = new Map<Id, List<Receipt__c>>();
        Set<Id> oppIdsToProcess = new Set<Id>();
        
        Set<Id> oldOppIdsToRecalc = new Set<Id>();
        
        for (Receipt__c rcpt : newRecords) {
            Receipt__c oldRcpt = oldMap.get(rcpt.Id);
            if (oldRcpt == null) continue;
            
            if (rcpt.Opportunity__c != null && rcpt.Amount__c != null && rcpt.Approval_Status__c == 'Approved' && oldRcpt.Approval_Status__c != 'Approved') {
                
                if (!oppToApprovedReceipts.containsKey(rcpt.Opportunity__c)) {
                    oppToApprovedReceipts.put(rcpt.Opportunity__c, new List<Receipt__c>());
                }
                oppToApprovedReceipts.get(rcpt.Opportunity__c).add(rcpt);
                oppIdsToProcess.add(rcpt.Opportunity__c);
            }
            
            if (rcpt.Amount__c != null && rcpt.Approval_Status__c == 'Approved' && rcpt.Opportunity__c != null && oldRcpt.Opportunity__c != null && rcpt.Opportunity__c != oldRcpt.Opportunity__c) {
                
                oldOppIdsToRecalc.add(oldRcpt.Opportunity__c);
                oppIdsToProcess.add(rcpt.Opportunity__c);
            }
        }

        
        if (oppIdsToProcess.isEmpty()) return;
        
        List<Payment_Schedule__c> paymentSchedules = [SELECT Id, Opportunity__c, Installment_Sequence__c, Agreement_Value__c, Tax_Amount__c, Total_Amount_Inclusive_Of_Tax__c, Total_Received_Amount__c, Opportunity__r.AccountId, Tax_Invoice_Created__c FROM Payment_Schedule__c WHERE Opportunity__c IN :oppIdsToProcess ORDER BY Opportunity__c, Installment_Sequence__c];
        if (paymentSchedules.isEmpty()) return;
        
        Map<Id, List<Payment_Schedule__c>> oppToPaymentSchedules = new Map<Id, List<Payment_Schedule__c>>();
        for (Payment_Schedule__c ps : paymentSchedules) {
            if (!oppToPaymentSchedules.containsKey(ps.Opportunity__c)) {
                oppToPaymentSchedules.put(ps.Opportunity__c, new List<Payment_Schedule__c>());
            }
            oppToPaymentSchedules.get(ps.Opportunity__c).add(ps);
        }
        
        Map<Id, Payment_Schedule__c> psToUpdateMap = new Map<Id, Payment_Schedule__c>();
        List<Tax_Invoice__c> taxInvoicesToInsert = new List<Tax_Invoice__c>();
        
        for (Id oppId : oppToApprovedReceipts.keySet()) {
            
            List<Payment_Schedule__c> psList = oppToPaymentSchedules.get(oppId);
            if (psList == null || psList.isEmpty()) continue;
            
            for (Receipt__c rcpt : oppToApprovedReceipts.get(oppId)) {
                
                Decimal rcptAmt = (rcpt.Amount__c == null ? 0 : rcpt.Amount__c);
                if (rcptAmt <= 0) continue;
                
                for (Payment_Schedule__c ps : psList) {
                    if (rcptAmt <= 0) break;
                    
                    Decimal agreement = (ps.Agreement_Value__c == null ? 0 : ps.Agreement_Value__c);
                    Decimal taxAmt    = (ps.Tax_Amount__c == null ? 0 : ps.Tax_Amount__c);
                    Decimal totalAmt  = agreement + taxAmt; 
                    
                    Decimal prevReceived = (ps.Total_Received_Amount__c == null ? 0 : ps.Total_Received_Amount__c);
                    
                    Decimal remainingDue = totalAmt - prevReceived;
                    if (remainingDue <= 0) continue;
                    system.debug('remainingDue::>>'+ remainingDue);
                    System.debug('rcptAmt::>>'+ rcptAmt);
                    Decimal applied = (rcptAmt >= remainingDue) ? remainingDue : rcptAmt;
                    System.debug('applied::>>'+ applied);
                    
                    ps.Total_Received_Amount__c = (rcpt.Type__c == 'Credit') ? (prevReceived - applied) : (prevReceived + applied);
                    rcptAmt -= applied;
                    
                    if (ps.Tax_Invoice_Created__c != true) {
                        
                        Decimal taxForReceivedAmount = 0;
                        if (totalAmt > 0) {
                            taxForReceivedAmount = (applied * taxAmt) / totalAmt;
                        }
                        
                        Tax_Invoice__c inv = new Tax_Invoice__c();
                        inv.Payment_Schedule__c = ps.Id;
                        inv.Opportunity__c      = ps.Opportunity__c;
                        inv.Account__c          = ps.Opportunity__r.AccountId;
                        inv.Receipt__c          = rcpt.Id;
                        inv.Received_Amount__c  = applied;
                        inv.SGST__c             = taxForReceivedAmount / 2;
                        inv.CGST__c             = taxForReceivedAmount / 2;
                        
                        taxInvoicesToInsert.add(inv);
                        
                        ps.Tax_Invoice_Created__c = true;
                    }
                    
                    psToUpdateMap.put(ps.Id, ps);
                }
            }
        }
        
        if (!psToUpdateMap.isEmpty()) {
            update psToUpdateMap.values();
            System.debug('Payment Schedule updated: ' + psToUpdateMap.size());
        }
        
        if (!taxInvoicesToInsert.isEmpty()) {
            insert taxInvoicesToInsert;
            System.debug('Tax Invoices inserted: ' + taxInvoicesToInsert.size());
        }
        
        if (!oldOppIdsToRecalc.isEmpty()) {
            
            List<AggregateResult> arList = [SELECT Opportunity__c opp, SUM(Amount__c) total FROM Receipt__c WHERE Opportunity__c IN :oldOppIdsToRecalc AND Approval_Status__c = 'Approved' GROUP BY Opportunity__c];
            
            Map<Id, Decimal> oldOppToApprovedTotal = new Map<Id, Decimal>();
            for (AggregateResult ar : arList) {
                oldOppToApprovedTotal.put((Id)ar.get('opp'), (Decimal)ar.get('total'));
            }
            
            List<Payment_Schedule__c> paymentSchedulesOld = [SELECT Id, Opportunity__c, Installment_Sequence__c, Agreement_Value__c, Tax_Amount__c, Total_Received_Amount__c FROM Payment_Schedule__c WHERE Opportunity__c IN :oldOppIdsToRecalc ORDER BY Opportunity__c, Installment_Sequence__c
                                                            ];
            
            if (paymentSchedulesOld.isEmpty()) return;
            
            Map<Id, List<Payment_Schedule__c>> oldOppToPaymentSchedules = new Map<Id, List<Payment_Schedule__c>>();
            for (Payment_Schedule__c ps : paymentSchedulesOld) {
                if (!oldOppToPaymentSchedules.containsKey(ps.Opportunity__c)) {
                    oldOppToPaymentSchedules.put(ps.Opportunity__c, new List<Payment_Schedule__c>());
                }
                oldOppToPaymentSchedules.get(ps.Opportunity__c).add(ps);
            }
            
            List<Payment_Schedule__c> psToUpdateOldOpp = new List<Payment_Schedule__c>();
            
            for (Id oppId : oldOppToPaymentSchedules.keySet()) {
                
                Decimal remaining = oldOppToApprovedTotal.containsKey(oppId) ? oldOppToApprovedTotal.get(oppId) : 0;
                
                for (Payment_Schedule__c ps : oldOppToPaymentSchedules.get(oppId)) {
                    
                    Decimal agreement = (ps.Agreement_Value__c == null ? 0 : ps.Agreement_Value__c);
                    Decimal taxAmt    = (ps.Tax_Amount__c == null ? 0 : ps.Tax_Amount__c);
                    Decimal totalAmt  = agreement + taxAmt;
                    
                    Decimal applied = (remaining >= totalAmt) ? totalAmt : remaining;
                    
                    ps.Total_Received_Amount__c = applied;
                    remaining -= applied;
                    
                    psToUpdateOldOpp.add(ps);
                    
                    if (remaining <= 0) break;
                }
            }
            
            if (!psToUpdateOldOpp.isEmpty()) {
                update psToUpdateOldOpp;
                System.debug('Old opp schedules recalculated: ' + psToUpdateOldOpp.size());
            }
        }
    }    
}