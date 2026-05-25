trigger EventTrigger on Event__c (After insert) {
	
    If(Trigger.isAfter && Trigger.isInsert) {
        
        folderFileManagerController.createFolderOnGDrive(Trigger.new);
    }
}