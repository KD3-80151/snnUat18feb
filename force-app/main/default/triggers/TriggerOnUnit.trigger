trigger TriggerOnUnit on Unit__c (before insert,before update,after insert,after update) {
    
    // DocumentCreationHandler dCH = new DocumentCreationHandler();
   
//    if(Trigger.isAfter && Trigger.isInsert) {
//        dCH.CreateDocuments(Trigger.new);
//    }
   if(Trigger.isBefore && Trigger.isUpdate){
       UnitTriggerHandler.preventEditsOnSoldUnits(Trigger.new, Trigger.oldMap);
   }

}