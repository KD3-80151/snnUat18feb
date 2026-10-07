/*
 * Backfill Payment_Schedule__c.Total_Received_Amount__c (and Tax Invoice creation) for
 * Opportunities whose receipts were already Approved BEFORE the Payment Schedules existed.
 *
 * Scope: Opportunities under Project__c = 'a0Fa700000YCCGLEA5'
 *
 * IMPORTANT: this calls receiptTriggerHandler.updtRcpdAmtOnPymntSchedule() ONCE for ALL
 * matching Opportunities together (bulkified), instead of looping
 * applyApprovedReceiptsToSchedules(oppId) per Opportunity - that per-Opportunity loop issues
 * a fresh set of SOQL queries every call and blows the 100-query governor limit once there
 * are more than a couple dozen Opportunities under the Project.
 *
 * NOTE: only run this ONCE. Debit-type receipts create a brand new Payment_Schedule__c
 * record every time they're processed (see receiptTriggerHandler.cls line ~111), so
 * re-running this for Opportunities already backfilled will create duplicate Debit
 * Payment Schedules.
 */

Set<Id> oppIds = new Map<Id, Opportunity>([
    SELECT Id FROM Opportunity WHERE Project__c = 'a0Fa700000YCCGLEA5'
]).keySet();

System.debug('Opportunities to backfill: ' + oppIds.size());

List<Receipt__c> approvedReceipts = [
    SELECT Id, Opportunity__c, Opportunity__r.Name, Amount__c, TDS_Amount__c, Approval_Status__c,
           Type__c, Total_Credit_Debit_Gst__c, Tax_Invoice_Included__c,
           Payment_Schedule__c, Against_Debit__c, Description__c
    FROM Receipt__c
    WHERE Opportunity__c IN :oppIds
      AND Approval_Status__c = 'Approved'
      AND Type__c IN ('Tax Invoice', 'Credit', 'Debit')
];

System.debug('Approved receipts to replay: ' + approvedReceipts.size());

if (!approvedReceipts.isEmpty()) {
    Map<Id, Receipt__c> fakeOldMap = new Map<Id, Receipt__c>();
    for (Receipt__c rcpt : approvedReceipts) {
        Receipt__c fakeOld = rcpt.clone(true, false, false, false);
        fakeOld.Approval_Status__c = 'Pending';
        fakeOldMap.put(rcpt.Id, fakeOld);
    }

    receiptTriggerHandler.updtRcpdAmtOnPymntSchedule(approvedReceipts, fakeOldMap);
}

System.debug('Backfill complete.');
