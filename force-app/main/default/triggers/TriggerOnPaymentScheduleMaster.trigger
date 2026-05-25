trigger TriggerOnPaymentScheduleMaster on Payment_Schedule_Master__c (before insert, before update) {

    if (Trigger.isBefore) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            PaymentScheduleMasterController.checkUniqueName(Trigger.new, Trigger.oldMap);
        }
    }

}