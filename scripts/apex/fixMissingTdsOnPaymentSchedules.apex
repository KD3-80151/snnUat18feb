/*
 * One-time data fix: some Payment Schedule Total_Received_Amount__c values are short
 * because the TDS portion of bulk-approved receipts had no remaining installment
 * capacity to land in (see receiptTriggerHandler.updtRcpdAmtOnPymntSchedule).
 *
 * Logic:
 *  1. For each Opportunity, sum (Amount__c + TDS_Amount__c [+ Total_Credit_Debit_Gst__c for Credit])
 *     across all Approved Tax Invoice / Credit receipts  -> receiptTotal.
 *  2. Sum Total_Received_Amount__c across that Opportunity's non-Debit Payment Schedules -> psTotal.
 *  3. shortfall = receiptTotal - psTotal. Only positive shortfalls are corrected (never reduces
 *     an existing Total_Received_Amount__c).
 *  4. Shortfall is applied to schedules in Installment_Sequence__c order, only into schedules that
 *     still have remaining due (Agreement_Value__c + Tax_Amount__c - Total_Received_Amount__c > 0),
 *     skipping any schedule with Demand_Letter_Sent__c = true. Status__c is a formula field and is
 *     intentionally NOT used as a filter - remaining due is the real signal.
 *
 * DRY_RUN = true only prints what WOULD change. Review debug logs, then set DRY_RUN = false and
 * re-run to actually commit the update.
 */

Boolean DRY_RUN = true;

Set<Id> oppIds = new Set<Id>();
for (Receipt__c r : [
    SELECT Opportunity__c
    FROM Receipt__c
    WHERE Approval_Status__c = 'Approved'
      AND Type__c IN ('Tax Invoice', 'Credit')
      AND Opportunity__c != null
]) {
    oppIds.add(r.Opportunity__c);
}

Map<Id, Decimal> oppToReceiptTotal = new Map<Id, Decimal>();
for (Receipt__c r : [
    SELECT Id, Opportunity__c, Amount__c, TDS_Amount__c, Total_Credit_Debit_Gst__c, Type__c
    FROM Receipt__c
    WHERE Opportunity__c IN :oppIds
      AND Approval_Status__c = 'Approved'
      AND Type__c IN ('Tax Invoice', 'Credit')
]) {
    Decimal amt = (r.Amount__c == null ? 0 : r.Amount__c) + (r.TDS_Amount__c == null ? 0 : r.TDS_Amount__c);
    if (r.Type__c == 'Credit') {
        amt += (r.Total_Credit_Debit_Gst__c == null ? 0 : r.Total_Credit_Debit_Gst__c);
    }
    oppToReceiptTotal.put(r.Opportunity__c,
        (oppToReceiptTotal.containsKey(r.Opportunity__c) ? oppToReceiptTotal.get(r.Opportunity__c) : 0) + amt);
}

List<Payment_Schedule__c> allPS = [
    SELECT Id, Opportunity__c, Installment_Sequence__c, Agreement_Value__c, Tax_Amount__c,
           Total_Received_Amount__c, Demand_Letter_Sent__c, Debit_Payment_Schedule__c
    FROM Payment_Schedule__c
    WHERE Opportunity__c IN :oppIds
      AND Debit_Payment_Schedule__c != true
      AND Installment_Sequence__c != null
    ORDER BY Opportunity__c, Installment_Sequence__c
];

Map<Id, List<Payment_Schedule__c>> oppToPS = new Map<Id, List<Payment_Schedule__c>>();
Map<Id, Decimal> oppToPSTotal = new Map<Id, Decimal>();
for (Payment_Schedule__c ps : allPS) {
    if (!oppToPS.containsKey(ps.Opportunity__c)) {
        oppToPS.put(ps.Opportunity__c, new List<Payment_Schedule__c>());
    }
    oppToPS.get(ps.Opportunity__c).add(ps);

    Decimal recv = (ps.Total_Received_Amount__c == null ? 0 : ps.Total_Received_Amount__c);
    oppToPSTotal.put(ps.Opportunity__c,
        (oppToPSTotal.containsKey(ps.Opportunity__c) ? oppToPSTotal.get(ps.Opportunity__c) : 0) + recv);
}

List<Payment_Schedule__c> psToUpdate = new List<Payment_Schedule__c>();

for (Id oppId : oppToReceiptTotal.keySet()) {
    Decimal receiptTotal = oppToReceiptTotal.get(oppId);
    Decimal psTotal = oppToPSTotal.containsKey(oppId) ? oppToPSTotal.get(oppId) : 0;
    Decimal shortfall = receiptTotal - psTotal;

    if (shortfall <= 0) {
        continue; // already reconciled, or PS total already >= receipts - do not touch
    }

    System.debug('Opp ' + oppId + ' | receiptTotal=' + receiptTotal + ' | psTotal(before)=' + psTotal + ' | shortfall=' + shortfall);

    List<Payment_Schedule__c> psList = oppToPS.get(oppId);
    if (psList == null) continue;

    for (Payment_Schedule__c ps : psList) {
        if (shortfall <= 0) break;
        if (ps.Demand_Letter_Sent__c == true) continue;

        Decimal agreement = (ps.Agreement_Value__c == null ? 0 : ps.Agreement_Value__c);
        Decimal taxAmt = (ps.Tax_Amount__c == null ? 0 : ps.Tax_Amount__c);
        Decimal totalAmt = agreement + taxAmt;
        Decimal prevReceived = (ps.Total_Received_Amount__c == null ? 0 : ps.Total_Received_Amount__c);
        Decimal remainingDue = totalAmt - prevReceived;

        if (remainingDue <= 0) continue;

        Decimal applied = Math.min(shortfall, remainingDue);
        System.debug('  -> PS ' + ps.Id + ' (seq ' + ps.Installment_Sequence__c + ') prevReceived=' + prevReceived
            + ' remainingDue=' + remainingDue + ' applying=' + applied);

        ps.Total_Received_Amount__c = prevReceived + applied;
        shortfall -= applied;
        psToUpdate.add(ps);
    }

    if (shortfall > 0) {
        System.debug('  WARNING: Opp ' + oppId + ' still has unapplied shortfall of ' + shortfall
            + ' - no schedule with remaining due found (all fully paid or demand letter sent). Needs manual review.');
    }
}

System.debug('=== ' + psToUpdate.size() + ' Payment Schedule(s) would be updated. DRY_RUN=' + DRY_RUN + ' ===');

if (!DRY_RUN && !psToUpdate.isEmpty()) {
    update psToUpdate;
    System.debug('Committed update to ' + psToUpdate.size() + ' Payment Schedule(s).');
}
