trigger BlogTrigger on Blogs__c (After insert) {
	
    If(Trigger.isAfter && Trigger.isInsert) {
        folderFileManagerController.createFolderOnGDrive(Trigger.new);
    }
}