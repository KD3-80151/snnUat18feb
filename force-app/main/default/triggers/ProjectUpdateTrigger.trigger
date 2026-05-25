trigger ProjectUpdateTrigger on Project_Updates__c (After insert) {

    If(Trigger.isAfter && Trigger.isInsert) {
        
        folderFileManagerController.createFolderOnGDrive(Trigger.new);
    }
}