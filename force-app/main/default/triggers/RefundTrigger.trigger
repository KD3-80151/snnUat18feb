trigger RefundTrigger on Refund__c (before insert, before update, after insert, after update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            RefundHandler.handleBefore(Trigger.new, Trigger.isInsert);
        }
    }

    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            RefundHandler.handleAfterInsert(Trigger.new);
        }

        if (Trigger.isUpdate) {
            RefundHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}