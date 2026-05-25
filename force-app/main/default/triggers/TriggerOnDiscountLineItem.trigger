trigger TriggerOnDiscountLineItem on Discount_LineItem__c (before insert, before Update) {
    
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
        
        DiscountLineItemTriggerHandler.handleDiscountLineItemRole(Trigger.new, Trigger.old);
    }

}