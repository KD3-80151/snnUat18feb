trigger TriggerOnCostSheet on Cost_Sheet__c (before insert, after update) {
    if(trigger.isAfter && trigger.isUpdate){
        costSheetTriggerHandler.afterUpdate(trigger.newMap, trigger.oldMap);
    }
}