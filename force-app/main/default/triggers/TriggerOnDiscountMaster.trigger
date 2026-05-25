trigger TriggerOnDiscountMaster on Discount_Master__c (before Insert, before Update,after Update) {
    
   /* if (Trigger.isBefore && Trigger.isInsert) {
        DiscountMasterTriggerHandler.checkActiveDiscountMaster(Trigger.new, null);
    }
    
    if (Trigger.isBefore && Trigger.isUpdate) {
        DiscountMasterTriggerHandler.checkActiveDiscountMaster(Trigger.new, Trigger.old);
    }
*/
    if (Trigger.isBefore && Trigger.isInsert) {
        DiscountMasterTriggerHandler.showValidationForSameDiscountMaster(Trigger.new );
    }
    if (Trigger.isAfter && Trigger.isUpdate) {
        DiscountMasterTriggerHandler.showValidationForSameDiscountMasterAfterActive(Trigger.new, Trigger.oldMap );
    }

}