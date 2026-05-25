trigger TriggerOnReceipt on Receipt__c (after update) {
    if(Trigger.isAfter && Trigger.isUpdate){
        System.debug('After Update...');
        receiptTriggerHandler.generateDoc(Trigger.new, Trigger.oldMap);
        receiptTriggerHandler.updtRcpdAmtOnPymntSchedule(Trigger.new, Trigger.oldMap);
    }
}