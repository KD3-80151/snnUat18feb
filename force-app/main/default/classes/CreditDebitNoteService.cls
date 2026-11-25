/**
 * Credit / Debit notes (Receipt__c with Type__c = 'Credit' or 'Debit').
 *
 * Client points (21 Nov 2026):
 *  2. A credit/debit note can be cancelled; when it is cancelled the payment schedule is adjusted back.
 *  3. A unit transfer is blocked while the booking has credit/debit notes that are not cancelled.
 *
 * What an approved note did to the payment schedule (receiptTriggerHandler):
 *  - Debit:  created a payment schedule line "Debit Note : <pricing element>" (Debit_Note__c = the note)
 *            and, from 21 Nov, its GST / tax invoice.
 *  - Credit: added the credit to Total Received Amount of unpaid instalments (recorded per instalment in
 *            Credit_Note_Allocation__c) and, when GST was selected, created tax invoices.
 * Cancelling reverses exactly that.
 */
public without sharing class CreditDebitNoteService {

    public static final String STATUS_CANCELLED = 'Cancelled';

    public class NoteException extends Exception {}

    public class NoteSummary {
        @AuraEnabled public Id recordId;
        @AuraEnabled public String entryNumber;
        @AuraEnabled public String entryType;
        @AuraEnabled public Decimal amount;
        @AuraEnabled public Decimal tax;
        @AuraEnabled public String status;
        @AuraEnabled public String paymentSchedule;
        @AuraEnabled public String pricingElement;
        @AuraEnabled public Boolean canCancel = false;
        @AuraEnabled public String message;
        @AuraEnabled public List<String> effects = new List<String>();
    }

    // ---------------------------------------------------------------- queries

    private static Receipt__c loadNote(Id noteId) {
        List<Receipt__c> notes = [
            SELECT Id, Name, Receipt_Number__c, Type__c, Status__c, Approval_Status__c, Amount__c,
                   Total_Credit_Debit_Gst__c, Opportunity__c, Opportunity__r.Name, Payment_Schedule__r.Name,
                   Pricing_Element_Master__c, Pricing_Element_Master__r.Name, Tax_Invoice_Included__c, CreatedDate
            FROM Receipt__c WHERE Id = :noteId LIMIT 1
        ];
        return notes.isEmpty() ? null : notes[0];
    }

    private static Boolean isNote(Receipt__c r) {
        return r != null && (r.Type__c == 'Credit' || r.Type__c == 'Debit');
    }

    public static String entryType(Receipt__c r) {
        return r == null ? '' : (r.Type__c == 'Credit' ? 'Credit Note' : (r.Type__c == 'Debit' ? 'Debit Note' : String.valueOf(r.Type__c)));
    }

    private static String rupees(Decimal amount) {
        return 'Rs. ' + DocumentDataHelper.formatIndianAmount(amount == null ? 0 : amount);
    }

    /** The payment schedule line created when this debit note was approved. */
    @TestVisible
    private static Payment_Schedule__c findDebitSchedule(Receipt__c note) {
        List<Payment_Schedule__c> linked = [
            SELECT Id, Name, Total_Received_Amount__c, Agreement_Value__c, Tax_Amount__c
            FROM Payment_Schedule__c WHERE Debit_Note__c = :note.Id ORDER BY CreatedDate ASC LIMIT 1
        ];
        if (!linked.isEmpty()) return linked[0];

        // Debit notes approved before 21 Nov 2026 have no link: match the line the approval created
        String expectedName = 'Debit Note : ' + (note.Pricing_Element_Master__r != null && note.Pricing_Element_Master__r.Name != null ? note.Pricing_Element_Master__r.Name : '');
        Decimal amount = note.Amount__c == null ? 0 : note.Amount__c;
        List<Payment_Schedule__c> candidates = [
            SELECT Id, Name, Total_Received_Amount__c, Agreement_Value__c, Tax_Amount__c
            FROM Payment_Schedule__c
            WHERE Opportunity__c = :note.Opportunity__c AND Debit_Payment_Schedule__c = true
              AND Debit_Note__c = null AND Agreement_Value__c = :amount AND CreatedDate >= :note.CreatedDate
            ORDER BY CreatedDate ASC
        ];
        for (Payment_Schedule__c ps : candidates) {
            if (ps.Name == expectedName) return ps;
        }
        return candidates.isEmpty() ? null : candidates[0];
    }

    /** Instalments this credit note was added to: payment schedule Id => amount added. */
    @TestVisible
    private static Map<Id, Decimal> creditAllocation(Receipt__c note) {
        Map<Id, Decimal> result = new Map<Id, Decimal>();
        String key = String.valueOf(note.Id);
        for (Payment_Schedule__c ps : [SELECT Id, Credit_Note_Allocation__c FROM Payment_Schedule__c
                                       WHERE Opportunity__c = :note.Opportunity__c]) {
            if (String.isBlank(ps.Credit_Note_Allocation__c)) continue;
            Map<String, Object> alloc = readAllocation(ps.Credit_Note_Allocation__c);
            if (alloc.containsKey(key)) {
                result.put(ps.Id, toDecimal(alloc.get(key)));
            }
        }
        if (!result.isEmpty()) return result;

        // Credit notes approved before 21 Nov 2026: the tax invoices hold the amount added per instalment
        for (Tax_Invoice__c inv : [SELECT Payment_Schedule__c, Received_Amount__c FROM Tax_Invoice__c
                                   WHERE Receipt__c = :note.Id AND Payment_Schedule__c != null]) {
            Decimal prev = result.containsKey(inv.Payment_Schedule__c) ? result.get(inv.Payment_Schedule__c) : 0;
            result.put(inv.Payment_Schedule__c, prev + (inv.Received_Amount__c == null ? 0 : inv.Received_Amount__c));
        }
        return result;
    }

    // ---------------------------------------------------------------- allocation bookkeeping

    public static Map<String, Object> readAllocation(String raw) {
        if (String.isBlank(raw)) return new Map<String, Object>();
        try {
            return (Map<String, Object>) JSON.deserializeUntyped(raw);
        } catch (Exception e) {
            return new Map<String, Object>();
        }
    }

    private static Decimal toDecimal(Object value) {
        return value == null ? 0 : Decimal.valueOf(String.valueOf(value));
    }

    /** Called by receiptTriggerHandler when an approved credit note adds an amount to an instalment. */
    public static void addCreditAllocation(Payment_Schedule__c ps, Id noteId, Decimal amountAdded) {
        if (ps == null || noteId == null || amountAdded == null || amountAdded == 0) return;
        Map<String, Object> alloc = readAllocation(ps.Credit_Note_Allocation__c);
        String key = String.valueOf(noteId);
        alloc.put(key, toDecimal(alloc.get(key)) + amountAdded);
        ps.Credit_Note_Allocation__c = JSON.serialize(alloc);
    }

    // ---------------------------------------------------------------- unit transfer check (client point 3)

    /** Credit/debit notes on these bookings that are neither cancelled nor rejected. */
    public static Map<Id, List<Receipt__c>> openNotesByOpportunity(Set<Id> oppIds) {
        Map<Id, List<Receipt__c>> result = new Map<Id, List<Receipt__c>>();
        if (oppIds == null || oppIds.isEmpty()) return result;
        for (Receipt__c r : [SELECT Id, Name, Receipt_Number__c, Type__c, Opportunity__c FROM Receipt__c
                             WHERE Opportunity__c IN :oppIds AND Type__c IN ('Credit', 'Debit')
                             AND Status__c != :STATUS_CANCELLED AND Approval_Status__c != 'Rejected'
                             ORDER BY CreatedDate ASC]) {
            if (!result.containsKey(r.Opportunity__c)) result.put(r.Opportunity__c, new List<Receipt__c>());
            result.get(r.Opportunity__c).add(r);
        }
        return result;
    }

    // ---------------------------------------------------------------- cancel (client point 2)

    @AuraEnabled
    public static NoteSummary getNoteSummary(Id recordId) {
        NoteSummary s = new NoteSummary();
        s.recordId = recordId;
        Receipt__c note = loadNote(recordId);
        if (!isNote(note)) {
            s.message = 'Only a credit note or a debit note can be cancelled here.';
            return s;
        }
        s.entryNumber = note.Receipt_Number__c;
        s.entryType = entryType(note);
        s.amount = note.Amount__c;
        s.tax = note.Total_Credit_Debit_Gst__c;
        s.status = note.Status__c == STATUS_CANCELLED ? STATUS_CANCELLED : note.Approval_Status__c;
        s.paymentSchedule = note.Payment_Schedule__r != null ? note.Payment_Schedule__r.Name : '';
        s.pricingElement = note.Pricing_Element_Master__r != null ? note.Pricing_Element_Master__r.Name : '';
        try {
            s.effects = plan(note).effects;
            s.canCancel = true;
        } catch (NoteException e) {
            s.message = e.getMessage();
        }
        return s;
    }

    @AuraEnabled
    public static String cancelNote(Id recordId, String reason) {
        if (String.isBlank(reason)) {
            throw auraError('Please enter the reason for cancelling.');
        }
        Receipt__c note = loadNote(recordId);
        Savepoint sp = Database.setSavepoint();
        try {
            CancelPlan p = plan(note);

            if (!p.taxInvoicesToDelete.isEmpty()) delete p.taxInvoicesToDelete;
            if (!p.schedulesToUpdate.isEmpty()) update p.schedulesToUpdate;
            if (p.debitScheduleToDelete != null) delete p.debitScheduleToDelete;

            // A note still waiting for approval: take it out of the approver's queue
            if (note.Approval_Status__c != 'Approved' && note.Approval_Status__c != 'Rejected') {
                removePendingApproval(note.Id);
            }

            update new Receipt__c(
                Id = note.Id,
                Status__c = STATUS_CANCELLED,
                Cancellation_Reason__c = reason.left(255),
                Cancelled_Date__c = System.today(),
                Cancelled_By__c = UserInfo.getUserId()
            );
            return entryType(note) + ' ' + note.Receipt_Number__c + ' is cancelled.';
        } catch (NoteException e) {
            Database.rollback(sp);
            throw auraError(e.getMessage());
        } catch (Exception e) {
            Database.rollback(sp);
            throw auraError('The note was not cancelled: ' + e.getMessage());
        }
    }

    private class CancelPlan {
        List<String> effects = new List<String>();
        List<Tax_Invoice__c> taxInvoicesToDelete = new List<Tax_Invoice__c>();
        List<Payment_Schedule__c> schedulesToUpdate = new List<Payment_Schedule__c>();
        Payment_Schedule__c debitScheduleToDelete;
    }

    private static CancelPlan plan(Receipt__c note) {
        if (!isNote(note)) throw new NoteException('Only a credit note or a debit note can be cancelled.');
        if (note.Status__c == STATUS_CANCELLED) throw new NoteException('This ' + entryType(note) + ' is already cancelled.');

        CancelPlan p = new CancelPlan();
        if (note.Approval_Status__c != 'Approved') {
            p.effects.add('The note is not approved, so the payment schedule has not been changed by it. It is only marked as Cancelled'
                + (note.Approval_Status__c == 'Rejected' ? '.' : ' and removed from the approval queue.'));
            return p;
        }

        List<Tax_Invoice__c> invoices = [SELECT Id, Name, GST_Paid__c, Payment_Schedule__c FROM Tax_Invoice__c WHERE Receipt__c = :note.Id];
        for (Tax_Invoice__c inv : invoices) {
            if (inv.GST_Paid__c) {
                throw new NoteException('GST on this ' + entryType(note) + ' is already marked as paid (tax invoice ' + inv.Name
                    + '), so it cannot be cancelled. Please raise a ' + (note.Type__c == 'Debit' ? 'credit' : 'debit') + ' note instead.');
            }
        }

        if (note.Type__c == 'Debit') {
            Payment_Schedule__c ps = findDebitSchedule(note);
            if (ps == null) {
                p.effects.add('No payment schedule line was found for this debit note; it is only marked as Cancelled.');
            } else {
                Decimal received = ps.Total_Received_Amount__c == null ? 0 : ps.Total_Received_Amount__c;
                if (received > 0) {
                    throw new NoteException(rupees(received) + ' has already been received against this debit note (' + ps.Name
                        + '). Move or refund that payment first, then cancel the debit note.');
                }
                Integer pending = [SELECT COUNT() FROM Receipt__c WHERE Payment_Schedule__c = :ps.Id AND Id != :note.Id
                                   AND Approval_Status__c IN ('Pending', 'Sent') AND Status__c != :STATUS_CANCELLED];
                if (pending > 0) {
                    throw new NoteException('A receipt against this debit note is waiting for approval. Approve or reject it first.');
                }
                p.debitScheduleToDelete = ps;
                Decimal total = (ps.Agreement_Value__c == null ? 0 : ps.Agreement_Value__c) + (ps.Tax_Amount__c == null ? 0 : ps.Tax_Amount__c);
                p.effects.add('The payment schedule line "' + ps.Name + '" (' + rupees(total) + ') is removed.');
            }
            // Its tax invoices are child records of that line, so they go with it
            for (Tax_Invoice__c inv : invoices) {
                if (p.debitScheduleToDelete == null || inv.Payment_Schedule__c != p.debitScheduleToDelete.Id) {
                    p.taxInvoicesToDelete.add(inv);
                }
            }
            if (!invoices.isEmpty()) p.effects.add('Its GST / tax invoice is removed.');
        } else {
            Map<Id, Decimal> alloc = creditAllocation(note);
            if (alloc.isEmpty()) {
                p.effects.add('This credit note did not change any instalment, so only its status changes.');
            } else {
                Map<Id, Payment_Schedule__c> schedules = new Map<Id, Payment_Schedule__c>([
                    SELECT Id, Name, Total_Received_Amount__c, Credit_Note_Allocation__c
                    FROM Payment_Schedule__c WHERE Id IN :alloc.keySet()
                ]);
                String key = String.valueOf(note.Id);
                for (Id psId : alloc.keySet()) {
                    Payment_Schedule__c ps = schedules.get(psId);
                    if (ps == null) continue; // instalment no longer exists (schedule regenerated)
                    Decimal received = ps.Total_Received_Amount__c == null ? 0 : ps.Total_Received_Amount__c;
                    Decimal back = alloc.get(psId);
                    ps.Total_Received_Amount__c = Math.max(0, received - back);
                    Map<String, Object> a = readAllocation(ps.Credit_Note_Allocation__c);
                    a.remove(key);
                    ps.Credit_Note_Allocation__c = a.isEmpty() ? null : JSON.serialize(a);
                    p.schedulesToUpdate.add(ps);
                    p.effects.add(rupees(back) + ' is taken back from "' + ps.Name + '" (received amount ' + rupees(received)
                        + ' becomes ' + rupees(ps.Total_Received_Amount__c) + ').');
                }
            }
            p.taxInvoicesToDelete.addAll(invoices);
            if (!invoices.isEmpty()) p.effects.add('Its GST / tax invoice' + (invoices.size() > 1 ? 's are' : ' is') + ' removed.');
        }
        return p;
    }

    private static void removePendingApproval(Id noteId) {
        for (ProcessInstanceWorkitem wi : [SELECT Id FROM ProcessInstanceWorkitem
                                           WHERE ProcessInstance.TargetObjectId = :noteId AND ProcessInstance.Status = 'Pending']) {
            Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
            req.setWorkitemId(wi.Id);
            req.setComments('Credit/Debit note cancelled');
            try {
                req.setAction('Removed');
                Approval.process(req);
            } catch (Exception recallFailed) {
                try {
                    req.setAction('Reject');
                    Approval.process(req);
                } catch (Exception rejectFailed) {
                    // The approver may still see it; approving a cancelled note changes nothing (receiptTriggerHandler skips it)
                    System.debug('Approval request left open for cancelled note ' + noteId + ': ' + rejectFailed.getMessage());
                }
            }
        }
    }

    private static AuraHandledException auraError(String msg) {
        AuraHandledException e = new AuraHandledException(msg);
        e.setMessage(msg);
        return e;
    }
}