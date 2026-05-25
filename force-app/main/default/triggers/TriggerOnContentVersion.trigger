trigger TriggerOnContentVersion on ContentVersion (before insert, after insert) {

    ContentVersionHandler cvh = new ContentVersionHandler();

    /*if(Trigger.isBefore && Trigger.isInsert){
        cvh.publicizeFiles(Trigger.new);
    }
    if(Trigger.isAfter && Trigger.isInsert){
        cvh.createConDocLink(Trigger.new);
    }*/
}