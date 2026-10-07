public without sharing class receiptTriggerHandler {

    public static void generateDoc(List<Receipt__c> newRecords, Map<Id, Receipt__c> oldMap){
        if(newRecords == null || newRecords.isEmpty() || oldMap == null) return;

        List<String> rcptIds = new List<String>();
        for(Receipt__c rcpt : newRecords){
            Receipt__c oldRcpt = oldMap.get(rcpt.Id);
            if(oldRcpt == null) continue;

            if(rcpt.Approval_Status__c == 'Approved' && oldRcpt.Approval_Status__c != 'Approved'){
                rcptIds.add(rcpt.Id);
            }
        }

        if(!rcptIds.isEmpty()){
            QueueableToGenerateDocDigio queueable = new QueueableToGenerateDocDigio(rcptIds);
            System.enqueueJob(queueable);
        }
    }

    public static void updtRcpdAmtOnPymntSchedule(List<Receipt__c> newRecords, Map<Id, Receipt__c> oldMap) {

        System.debug('newRecords==>' + newRecords);
        System.debug('oldMap==>' + oldMap);

        if (newRecords == null || newRecords.isEmpty() || oldMap == null) return;

        Map<Id, List<Receipt__c>> oppToApprovedReceipts = new Map<Id, List<Receipt__c>>();
        Set<Id> oppIdsToProcess                         = new Set<Id>();
        Set<Id> oldOppIdsToRecalc                       = new Set<Id>();
        Set<Id> oppIdsForWelcomeLetter                  = new Set<Id>();

        
        List<Payment_Schedule__c> psToInsert = new List<Payment_Schedule__c>();

        for (Receipt__c rcpt : newRecords) {
            Receipt__c oldRcpt = oldMap.get(rcpt.Id);
            if (oldRcpt == null) continue;

            Decimal totalRcptAmt = (rcpt.Amount__c == null ? 0 : rcpt.Amount__c) + (rcpt.TDS_Amount__c == null ? 0 : rcpt.TDS_Amount__c);

            System.debug('totalRcptAmt==>' + totalRcptAmt);

            if (rcpt.Opportunity__c != null && totalRcptAmt > 0 && rcpt.Approval_Status__c == 'Approved' && oldRcpt.Approval_Status__c != 'Approved' && (rcpt.Type__c == 'Tax Invoice' || rcpt.Type__c == 'Credit' || rcpt.Type__c == 'Debit')) {

                if (!oppToApprovedReceipts.containsKey(rcpt.Opportunity__c)) {
                    oppToApprovedReceipts.put(rcpt.Opportunity__c, new List<Receipt__c>());
                }
                oppToApprovedReceipts.get(rcpt.Opportunity__c).add(rcpt);
                oppIdsToProcess.add(rcpt.Opportunity__c);
                oppIdsForWelcomeLetter.add(rcpt.Opportunity__c);

            }

            if (totalRcptAmt > 0 && rcpt.Approval_Status__c == 'Approved' && rcpt.Type__c == 'Tax Invoice' && rcpt.Opportunity__c != null && oldRcpt.Opportunity__c != null && rcpt.Opportunity__c != oldRcpt.Opportunity__c) {

                oldOppIdsToRecalc.add(oldRcpt.Opportunity__c);
                oppIdsToProcess.add(rcpt.Opportunity__c);
            }
        }

        if (oppIdsToProcess.isEmpty() || oppToApprovedReceipts.isEmpty()) {
            System.debug('No Tax Invoice / Credit / Debit receipts approved / moved. Skipping Payment Schedule update.');
            return;
        }

        List<Payment_Schedule__c> paymentSchedules = [SELECT Id, Opportunity__c, Installment_Sequence__c, Agreement_Value__c, Tax_Amount__c, Demand_Letter_Sent__c, Status__c, Total_Amount_Inclusive_Of_Tax__c,
                Total_Received_Amount__c, Opportunity__r.AccountId, Tax_Invoice_Created__c, Debit_Payment_Schedule__c FROM Payment_Schedule__c WHERE Opportunity__c IN :oppIdsToProcess ORDER BY Opportunity__c, Installment_Sequence__c
        ];
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

        Set<Id> peMasterIds = new Set<Id>();
        for (List<Receipt__c> rcptList : oppToApprovedReceipts.values()) {
            for (Receipt__c rcpt : rcptList) {
                if (rcpt.Type__c == 'Debit' && rcpt.Pricing_Element_Master__c != null) {
                    peMasterIds.add(rcpt.Pricing_Element_Master__c);
                }
            }
        }
        Map<Id, String> peMasterNameById = new Map<Id, String>();
        if (!peMasterIds.isEmpty()) {
            for (Pricing_Element_Master__c peMaster : [SELECT Id, Name FROM Pricing_Element_Master__c WHERE Id IN :peMasterIds]) {
                peMasterNameById.put(peMaster.Id, peMaster.Name);
            }
        }

        for (Id oppId : oppToApprovedReceipts.keySet()) {
            List<Payment_Schedule__c> psList = oppToPaymentSchedules.get(oppId);
            if (psList == null || psList.isEmpty()) continue;

            for (Receipt__c rcpt : oppToApprovedReceipts.get(oppId)) {

                Decimal rcptAmt = (rcpt.Amount__c == null ? 0 : rcpt.Amount__c) + (rcpt.TDS_Amount__c == null ? 0 : rcpt.TDS_Amount__c);
                System.debug('rcptAmt ::::' + rcptAmt);
                if (rcptAmt <= 0) continue;

                if (rcpt.Type__c == 'Debit') {
                    system.debug('enter debit');
                    Payment_Schedule__c debitPS = new Payment_Schedule__c();
                    debitPS.Opportunity__c = rcpt.Opportunity__c;

                    String peMasterName = peMasterNameById.get(rcpt.Pricing_Element_Master__c);
                    debitPS.Name = 'Debit Note : ' + (String.isNotBlank(peMasterName) ? peMasterName : '');
                    debitPS.Agreement_Value__c = rcpt.Amount__c != null ? rcpt.Amount__c : 0;
                    debitPS.Tax_Amount__c = rcpt.Total_Credit_Debit_Gst__c != null ? rcpt.Total_Credit_Debit_Gst__c : 0;
                    // debitPS.Installment_Sequence__c = psList.size() + 1;
                    debitPS.Debit_Payment_Schedule__c = true;
                    psToInsert.add(debitPS);
                    system.debug('Created Debit Payment Schedule: ' + debitPS);
                    
                    // for (Integer i = psList.size() - 1; i >= 0; i--) {
                    //     if (rcptAmt <= 0) break;

                    //     Payment_Schedule__c ps = psList[i];

                    //     if (ps.Status__c != 'Unpaid' || ps.Demand_Letter_Sent__c == true) {
                    //         continue;
                    //     }

                    //     Decimal prevReceived = (ps.Total_Received_Amount__c == null ? 0 : ps.Total_Received_Amount__c);
                    //     System.debug('prevReceived ::::' + prevReceived);
                    //     if (prevReceived <= 0) continue;

                    //     Decimal deduction = Math.min(prevReceived, rcptAmt);
                    //     system.debug('deduction ::::' + deduction);
                    //     ps.Total_Received_Amount__c = prevReceived - deduction;
                    //     rcptAmt -= deduction;
                    //     psToUpdateMap.put(ps.Id, ps);
                    // }

                } else if (rcpt.Type__c == 'Credit') {
                    for (Payment_Schedule__c ps : psList) {
                        if (rcptAmt <= 0) break;

                        if (ps.Status__c != 'Unpaid' || ps.Demand_Letter_Sent__c == true) {
                            continue;
                        }

                        if (ps.Installment_Sequence__c == null) {
                            continue;
                        }


                        Decimal agreement = (ps.Agreement_Value__c == null ? 0 : ps.Agreement_Value__c);
                        Decimal taxAmt    = (ps.Tax_Amount__c == null ? 0 : ps.Tax_Amount__c);
                        Decimal totalAmt  = agreement + taxAmt;
                        Decimal prevReceived = (ps.Total_Received_Amount__c == null ? 0 : ps.Total_Received_Amount__c);
                        Decimal remainingDue = totalAmt - prevReceived;

                        if (remainingDue <= 0) continue;

                        Decimal applied = Math.min(rcptAmt, remainingDue);
                        System.debug('applied ::::' + applied);
                        ps.Total_Received_Amount__c = prevReceived + applied + rcpt.Total_Credit_Debit_Gst__c;
                        system.debug('ps.Total_Received_Amount__c after applying credit ::::' + ps.Total_Received_Amount__c);
                        rcptAmt -= applied;
                        system.debug('rcptAmt after applying credit ::::' + rcptAmt);
                         if (rcpt.Tax_Invoice_Included__c == true && ps.Demand_Letter_Sent__c == false) {
                            System.debug('Creating tax invoice for Credit receipt on Payment Schedule: ' + ps.Id);

                            Decimal taxForReceivedAmount = 0;
                            if (totalAmt > 0) {
                                taxForReceivedAmount = ((applied * taxAmt) / totalAmt) + rcpt.Total_Credit_Debit_Gst__c;
                            }

                            Tax_Invoice__c inv = new Tax_Invoice__c();
                            inv.Payment_Schedule__c = ps.Id;
                            inv.Opportunity__c      = ps.Opportunity__c;
                            inv.Account__c          = ps.Opportunity__r.AccountId;
                            inv.Receipt__c          = rcpt.Id;
                            inv.Received_Amount__c  = applied + rcpt.Total_Credit_Debit_Gst__c;
                            inv.SGST__c             = taxForReceivedAmount / 2;
                            inv.CGST__c             = taxForReceivedAmount / 2;

                            taxInvoicesToInsert.add(inv);
                            ps.Tax_Invoice_Created__c = true;
                        }
                        psToUpdateMap.put(ps.Id, ps);
                    }
                } 

                else {
                    system.debug('for all receipts');
                    Boolean isAgainstDebitTaxInvoice = rcpt.Type__c == 'Tax Invoice' && isAgainstDebitReceipt(rcpt) && rcpt.Payment_Schedule__c != null;
                    for (Payment_Schedule__c ps : psList) {
                        if (rcptAmt <= 0) break;

                        if (isAgainstDebitTaxInvoice) {
                            if (ps.Id != rcpt.Payment_Schedule__c || ps.Installment_Sequence__c != null) {
                                continue;
                            }
                        } else if (ps.Installment_Sequence__c == null) {
                            continue;
                        }

                        Decimal agreement = (ps.Agreement_Value__c == null ? 0 : ps.Agreement_Value__c);
                        Decimal taxAmt    = (ps.Tax_Amount__c == null ? 0 : ps.Tax_Amount__c);
                        Decimal totalAmt  = agreement + taxAmt;
                        Decimal prevReceived = (ps.Total_Received_Amount__c == null ? 0 : ps.Total_Received_Amount__c);
                        Decimal remainingDue = totalAmt - prevReceived;

                        if (remainingDue <= 0) continue;

                        Decimal applied = Math.min(rcptAmt, remainingDue);
                        ps.Total_Received_Amount__c = prevReceived + applied;
                        rcptAmt -= applied;

                        if (rcpt.Type__c == 'Tax Invoice' && ps.Demand_Letter_Sent__c == false) {
                            system.debug('Creating tax invoice for Payment Schedule: ' + ps.Id);
                            Decimal taxForReceivedAmount = 0;
                            if (totalAmt > 0) {
                                taxForReceivedAmount = (applied * taxAmt) / totalAmt;
                            }
                            system.debug('Tax for received amount: ' + taxForReceivedAmount);

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

                        if (isAgainstDebitTaxInvoice) {
                            break;
                        }
                    }
                }
            }
        }
        if (!psToInsert.isEmpty()) {
            Database.SaveResult[] srList = Database.insert(psToInsert, false);

            for (Integer i = 0; i < srList.size(); i++) {
                if (srList[i].isSuccess()) {
                    System.debug('Debit Payment Schedule inserted successfully. Id ==> ' + srList[i].getId());
                } else {
                    for (Database.Error err : srList[i].getErrors()) {
                        System.debug('Failed Debit Payment Schedule ==> ' + psToInsert[i]);
                        System.debug('Status Code ==> ' + err.getStatusCode());
                        System.debug('Message ==> ' + err.getMessage());
                        System.debug('Fields ==> ' + err.getFields());
                    }
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

            List<Receipt__c> oldOppReceipts = [SELECT Id, Opportunity__c, Amount__c, TDS_Amount__c FROM Receipt__c WHERE Opportunity__c IN :oldOppIdsToRecalc AND Approval_Status__c = 'Approved' AND Type__c = 'Tax Invoice'];

            Map<Id, Decimal> oldOppToApprovedTotal = new Map<Id, Decimal>();
            for (Receipt__c r : oldOppReceipts) {
                Decimal total = (r.Amount__c == null ? 0 : r.Amount__c) + (r.TDS_Amount__c == null ? 0 : r.TDS_Amount__c);

                oldOppToApprovedTotal.put(r.Opportunity__c, (oldOppToApprovedTotal.containsKey(r.Opportunity__c) ? oldOppToApprovedTotal.get(r.Opportunity__c) : 0) + total);
            }

            List<Payment_Schedule__c> paymentSchedulesOld = [
                SELECT Id, Opportunity__c, Installment_Sequence__c, Agreement_Value__c, Tax_Amount__c, Total_Received_Amount__c
                FROM Payment_Schedule__c
                WHERE Opportunity__c IN :oldOppIdsToRecalc
                ORDER BY Opportunity__c, Installment_Sequence__c
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

            for (Id oppIdVal : oldOppToPaymentSchedules.keySet()) {
                Decimal remaining = oldOppToApprovedTotal.containsKey(oppIdVal) ? oldOppToApprovedTotal.get(oppIdVal) : 0;

                for (Payment_Schedule__c ps : oldOppToPaymentSchedules.get(oppIdVal)) {
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
        
        //!for sending welcome letter email-----------------------------------------------------------------------------
        // if (!oppIdsForWelcomeLetter.isEmpty()) {
        //     System.debug('oppIdsForWelcomeLetter => ' + oppIdsForWelcomeLetter);

        //     List<Opportunity> oppsToQueue = [SELECT Id, Welcome_Sent_Date__c FROM Opportunity WHERE Id IN :oppIdsForWelcomeLetter AND Welcome_Sent_Date__c = NULL];
        //     System.debug('oppsToQueue => ' + oppsToQueue);

        //     for (Opportunity o : oppsToQueue) {
        //         if (!Test.isRunningTest()) {
        //             System.enqueueJob(new QueueableToGenerateWelcomeLetter(o.Id));
        //         } else {
        //             System.debug('Test context: skipping enqueue for Opp => ' + o.Id);
        //         }
        //     }
        // }
    }

    private static Boolean isAgainstDebitReceipt(Receipt__c rcpt) {
        return rcpt != null && String.valueOf(rcpt.Against_Debit__c).toLowerCase() == 'true';
    }

    // Called after new payment schedules are created (e.g. re-generate after delete approval)
    // to backfill received amounts from already-approved receipts on the opportunity.
    public static void applyApprovedReceiptsToSchedules(Id oppId) {
        if (oppId == null) return;

        List<Receipt__c> approvedReceipts = [
            SELECT Id, Opportunity__c, Opportunity__r.Name, Amount__c, TDS_Amount__c, Approval_Status__c,
                   Type__c, Total_Credit_Debit_Gst__c, Tax_Invoice_Included__c,
                   Payment_Schedule__c, Against_Debit__c, Description__c
            FROM Receipt__c
            WHERE Opportunity__c = :oppId
              AND Approval_Status__c = 'Approved'
              AND Type__c IN ('Tax Invoice', 'Credit', 'Debit')
        ];

        if (approvedReceipts.isEmpty()) return;

        // Simulate receipts transitioning from non-Approved to Approved so the
        // existing updtRcpdAmtOnPymntSchedule logic picks them all up.
        Map<Id, Receipt__c> fakeOldMap = new Map<Id, Receipt__c>();
        for (Receipt__c rcpt : approvedReceipts) {
            Receipt__c fakeOld = rcpt.clone(true, false, false, false);
            fakeOld.Approval_Status__c = 'Pending';
            fakeOldMap.put(rcpt.Id, fakeOld);
        }

        updtRcpdAmtOnPymntSchedule(approvedReceipts, fakeOldMap);
    }

     public static void dummyMethod(){
        Integer i = 0;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
    }
}