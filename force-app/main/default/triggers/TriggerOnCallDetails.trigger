trigger TriggerOnCallDetails on Call_Detail__c (before insert, before update, after insert, after update) {

    if(trigger.isAfter && trigger.isInsert){
            CallDetailsTaskHandler.createCallDetailsTask(trigger.new);
    }

}