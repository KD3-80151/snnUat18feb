trigger MarketingTrigger on Marketing__c (After insert) {

    If(Trigger.isAfter && Trigger.isInsert) {
        
        folderFileManagerController.createFolderOnGDrive(Trigger.new);
    }
}