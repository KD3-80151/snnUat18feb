trigger TriggerOnTask on Task (before insert, before update, after insert, after update, after delete) {

    if(Trigger.isBefore && Trigger.isUpdate){
        TaskTriggerHandler.handleActivitiesBeforeAnyUpdate(Trigger.NEW, Trigger.OldMap);
    }

    //for platform event
    if (Trigger.isAfter) {
        if (Trigger.isInsert || Trigger.isUpdate || Trigger.isDelete) {
            System.debug('trigger is fired for Task--');
            TaskTriggerHandler.processTaskEvents(Trigger.new, Trigger.old, Trigger.isInsert, Trigger.isUpdate, Trigger.isDelete);
            TaskTriggerHandler.createUnitTransferNotes(Trigger.new, Trigger.oldMap);
             System.debug('again trigger is fired for Task--');
        }
    }
}