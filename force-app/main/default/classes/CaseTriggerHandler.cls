public without sharing class CaseTriggerHandler {

    private static Id unitTransferRecordTypeId {
        get {
            if (unitTransferRecordTypeId == null) {
                Schema.RecordTypeInfo rt = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Unit_Transfer');
                unitTransferRecordTypeId = rt != null ? rt.getRecordTypeId() : null;
            }
            return unitTransferRecordTypeId;
        }
        set;
    }

    /**
     * Unit Transfer case:
     *  - Client point 3: not allowed while the current booking has credit/debit notes that are not cancelled
     *    (checked when the case is created, approved, and when the new booking is tagged).
     *  - Client point 4: the new booking (To Opportunity) must have a finalised cost sheet and a generated
     *    payment schedule before it is tagged, because the receipts are moved onto that schedule.
     */
    public static void validateUnitTransfer(List<Case> cases, Map<Id, Case> oldMap) {
        if (unitTransferRecordTypeId == null || cases == null) return;

        List<Case> checkNotes = new List<Case>();
        List<Case> checkNewBooking = new List<Case>();
        Set<Id> fromOppIds = new Set<Id>();
        Set<Id> toOppIds = new Set<Id>();

        for (Case c : cases) {
            if (c.RecordTypeId != unitTransferRecordTypeId) continue;
            Case old = oldMap == null ? null : oldMap.get(c.Id);
            Boolean isNew = old == null;

            Boolean toOppTagged = c.To_Opportunity__c != null && (isNew || c.To_Opportunity__c != old.To_Opportunity__c);
            Boolean approvedNow = c.Approval_Status__c == 'Approved' && (isNew || old.Approval_Status__c != 'Approved');
            Boolean bookingChanged = !isNew && c.Opportunity__c != old.Opportunity__c;

            if (c.Opportunity__c != null && (isNew || toOppTagged || approvedNow || bookingChanged)) {
                checkNotes.add(c);
                fromOppIds.add(c.Opportunity__c);
            }
            if (toOppTagged) {
                checkNewBooking.add(c);
                toOppIds.add(c.To_Opportunity__c);
            }
        }

        if (!checkNotes.isEmpty()) {
            Map<Id, List<Receipt__c>> openNotes = CreditDebitNoteService.openNotesByOpportunity(fromOppIds);
            for (Case c : checkNotes) {
                List<Receipt__c> notes = openNotes.get(c.Opportunity__c);
                if (notes == null || notes.isEmpty()) continue;
                List<String> labels = new List<String>();
                for (Receipt__c r : notes) {
                    labels.add(CreditDebitNoteService.entryType(r) + ' ' + (String.isNotBlank(r.Receipt_Number__c) ? r.Receipt_Number__c : r.Name));
                }
                c.addError('Unit transfer is not allowed: this booking has credit/debit notes that are not cancelled ('
                    + String.join(labels, ', ') + '). Cancel them first, then raise the unit transfer.');
            }
        }

        if (!checkNewBooking.isEmpty()) {
            Map<Id, Opportunity> toOpps = new Map<Id, Opportunity>([
                SELECT Id, Name,
                       (SELECT Id FROM Cost_Sheets__r WHERE finalize_CostSheet__c = true LIMIT 1),
                       (SELECT Id FROM Payment_Schedules__r WHERE Installment_Sequence__c != null LIMIT 1)
                FROM Opportunity WHERE Id IN :toOppIds
            ]);
            for (Case c : checkNewBooking) {
                Opportunity o = toOpps.get(c.To_Opportunity__c);
                if (o == null) continue;
                Boolean finalised = !o.Cost_Sheets__r.isEmpty();
                Boolean hasSchedule = !o.Payment_Schedules__r.isEmpty();
                if (!finalised || !hasSchedule) {
                    c.addError('The payment schedule is not generated for the new unit\'s booking "' + o.Name + '"'
                        + (finalised ? '' : ' (its cost sheet is not finalised)')
                        + '. Finalise the cost sheet and generate the payment schedule on that opportunity first, then tag it on this case.');
                }
            }
        }
    }
}