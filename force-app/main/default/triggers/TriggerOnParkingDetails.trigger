trigger TriggerOnParkingDetails on Parking_Details__c (before insert) {
    if(trigger.isBefore && trigger.isInsert){
        parkingDetailsTriggerHandler.validateBeforeInsert(trigger.new);
    }
}