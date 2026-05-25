trigger TriggerOnPricingElementMaster on Pricing_Element_Master__c (before insert, before update, before delete, after insert, after update, after delete) {
    if (trigger.isBefore) {
        if (trigger.isInsert || trigger.isUpdate) {
            PricingElementMasterController.checkUniqueName(trigger.new, trigger.oldMap);
        }
        
    }

    //TriggerManager.handle(new PricingElementMasterHandler());
}