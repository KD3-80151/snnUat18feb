trigger ProjectTrigger on Project__c (After insert) {
	
    If(Trigger.isAfter && Trigger.isInsert) {
        
        folderFileManagerController.createFolderOnGDrive(Trigger.new);
    }
}