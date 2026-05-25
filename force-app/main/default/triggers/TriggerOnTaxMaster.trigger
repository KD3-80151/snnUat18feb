trigger TriggerOnTaxMaster on Tax_Master__c (before insert, before update) {
    if(Trigger.isBefore){
        if(trigger.isInsert || trigger.isUpdate){
            TaxMasterController.checkUniqueName(trigger.new, trigger.oldMap);
        }
    }
}