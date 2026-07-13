public without sharing class ReceiptTransferPaymentScheduleInvoker {

    public class Request {
        @InvocableVariable(required=true)
        public Id transferLogId;
    }

    @InvocableMethod(label='Recalculate Payment Schedules For Receipt Transfer')
    public static void run(List<Request> requests) {
        System.debug('Received requests:::' + requests.size());

        Set<Id> transferLogIds = new Set<Id>();
        for (Request req : requests) {
            if (req != null && req.transferLogId != null) {
                transferLogIds.add(req.transferLogId);
            }
        }
        if (transferLogIds.isEmpty()) {
            return;
        }

        List<Receipt_Transfer_Log_LineItem__c> lineItems = [SELECT Id, Receipt__c, From_Opportunity__c, To_Opportunity__c, Receipt__r.Id, Receipt__r.Type__c,
                Receipt__r.Amount__c, Receipt__r.TDS_Amount__c, Receipt__r.Approval_Status__c FROM Receipt_Transfer_Log_LineItem__c WHERE Receipt_Transfer_Log__c IN :transferLogIds];
        System.debug('Fetched line items:::' + lineItems.size());
        if (lineItems.isEmpty()) {
            return;
        }

        Set<Id> oppIds = new Set<Id>();
        for (Receipt_Transfer_Log_LineItem__c li : lineItems) {
            if (li.Receipt__r == null || li.Receipt__r.Approval_Status__c != 'Approved' || li.Receipt__r.Type__c == 'Debit') {
                continue;
            }
            if (li.From_Opportunity__c != null) {
                oppIds.add(li.From_Opportunity__c);
            }
            if (li.To_Opportunity__c != null) {
                oppIds.add(li.To_Opportunity__c);
            }
        }

        if (oppIds.isEmpty()) {
            return;
        }

        Map<Id, List<Payment_Schedule__c>> oppToSchedules = getSchedulesByOpportunity(oppIds);
        List<Payment_Schedule__c> schedulesToUpdate = new List<Payment_Schedule__c>();
        Set<Id> updatedScheduleIds = new Set<Id>();

        for (Receipt_Transfer_Log_LineItem__c li : lineItems) {
            if (li.Receipt__r == null || li.Receipt__r.Approval_Status__c != 'Approved' || li.Receipt__r.Type__c == 'Debit') {
                continue;
            }

            Decimal movedAmt = getAmount(li.Receipt__r.Amount__c) + getAmount(li.Receipt__r.TDS_Amount__c);
            System.debug('Processing Line Item Id: ' + li.Id + ' with movedAmt: ' + movedAmt);
            if (movedAmt <= 0) {
                continue;
            }

            if (li.From_Opportunity__c != null && oppToSchedules.containsKey(li.From_Opportunity__c)) {
                applyTransferredAmount(oppToSchedules.get(li.From_Opportunity__c), movedAmt, true, schedulesToUpdate, updatedScheduleIds);
            }

            // if (li.To_Opportunity__c != null && oppToSchedules.containsKey(li.To_Opportunity__c)) {
            //     applyTransferredAmount(oppToSchedules.get(li.To_Opportunity__c), movedAmt, false, schedulesToUpdate, updatedScheduleIds);
            // }

            if (li.To_Opportunity__c != null && oppToSchedules.containsKey(li.To_Opportunity__c)) {
                List<Payment_Schedule__c> originalToOppSchedules = oppToSchedules.get(li.To_Opportunity__c);
                List<Payment_Schedule__c> toOppSchedules = new List<Payment_Schedule__c>();

                for (Integer i = originalToOppSchedules.size() - 1; i >= 0; i--) {
                    toOppSchedules.add(originalToOppSchedules[i]);
                }

                applyTransferredAmount(toOppSchedules, movedAmt, false, schedulesToUpdate, updatedScheduleIds);
            }

        }

        if (!schedulesToUpdate.isEmpty()) {
            update schedulesToUpdate;
        }
    }

    private static Map<Id, List<Payment_Schedule__c>> getSchedulesByOpportunity(Set<Id> oppIds) {
        system.debug('Fetching Payment Schedules for Opportunity Ids: ' + oppIds);
        Map<Id, List<Payment_Schedule__c>> oppToSchedules = new Map<Id, List<Payment_Schedule__c>>();

        for (Payment_Schedule__c ps : [SELECT Id, Opportunity__c, Installment_Sequence__c, Agreement_Value__c, Tax_Amount__c, Total_Amount_Inclusive_Of_Tax__c,
                Total_Received_Amount__c FROM Payment_Schedule__c WHERE Opportunity__c IN :oppIds AND Installment_Sequence__c != null ORDER BY Opportunity__c, Installment_Sequence__c DESC
        ]) {
            if (!oppToSchedules.containsKey(ps.Opportunity__c)) {
                oppToSchedules.put(ps.Opportunity__c, new List<Payment_Schedule__c>());
            }
            oppToSchedules.get(ps.Opportunity__c).add(ps);
        }

        return oppToSchedules;
    }

    private static void applyTransferredAmount(List<Payment_Schedule__c> schedules, Decimal transferAmount, Boolean isFromOpportunity, List<Payment_Schedule__c> schedulesToUpdate, Set<Id> updatedScheduleIds) {
        System.debug('Applying transferred amount: ' + transferAmount + ' to schedules for ' + (isFromOpportunity ? 'From Opportunity' : 'To Opportunity'));
        Decimal remainingAmount = transferAmount;

        for (Payment_Schedule__c ps : schedules) {
            if (remainingAmount <= 0) {
                break;
            }

            Decimal currentReceived = getAmount(ps.Total_Received_Amount__c);
            Decimal scheduleTotal = getScheduleTotal(ps);
            System.debug('Processing Payment Schedule Id: ' + ps.Id + ' with currentReceived: ' + currentReceived + ' and scheduleTotal: ' + scheduleTotal);
            if (isFromOpportunity) {
                if (currentReceived <= 0) {
                    continue;
                }

                Decimal deduction = Math.min(currentReceived, remainingAmount);
                System.debug('Calculated deduction: ' + deduction);
                if (deduction <= 0) {
                    continue;
                }

                ps.Total_Received_Amount__c = currentReceived - deduction;
                remainingAmount -= deduction;
            } else {
                Decimal remainingDue = scheduleTotal - currentReceived;
                System.debug('Calculated remainingDue: ' + remainingDue);
                if (remainingDue <= 0) {
                    continue;
                }

                Decimal applied = Math.min(remainingDue, remainingAmount);
                System.debug('Calculated applied amount: ' + applied);
                if (applied <= 0) {
                    continue;
                }

                ps.Total_Received_Amount__c = currentReceived + applied;
                remainingAmount -= applied;
            }

            if (!updatedScheduleIds.contains(ps.Id)) {
                schedulesToUpdate.add(ps);
                updatedScheduleIds.add(ps.Id);
            }
        }
    }

    private static Decimal getScheduleTotal(Payment_Schedule__c scheduleRec) {
        Decimal totalInclusive = getAmount(scheduleRec.Total_Amount_Inclusive_Of_Tax__c);
        system.debug('totalInclusive => ' + totalInclusive);
        if (totalInclusive > 0) {
            return totalInclusive;
        }
        return getAmount(scheduleRec.Agreement_Value__c) + getAmount(scheduleRec.Tax_Amount__c);
    }

    private static Decimal getAmount(Decimal val) {
        System.debug('getAmount => ' + val);
        return val == null ? 0 : val;
    }
}