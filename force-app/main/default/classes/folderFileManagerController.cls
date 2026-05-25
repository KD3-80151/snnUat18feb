public without sharing class folderFileManagerController {

   @AuraEnabled
    public static Boolean createFolder(String folderName, Id oppId){
        try {
            if(folderName != null){
                Document__c doc = new Document__c(
                    Name = folderName,
                    Opportunity__c = oppId
                );
                insert doc;

                if(doc != null){
                    GoogleDriveAPI.createFolder(doc.Id);
                    return true;
                }
                return false;
            }
            return false;
        } catch (Exception e) {
            system.debug('Error in uploadFileUnderDocument ==> ' + e.getMessage());
            System.debug('line number ===> ' + e.getLineNumber());
            return false;
        }
    }
    

    // public class wrapperForResponse{
    //     @AuraEnabled public Boolean is308Response{get;set;}
    //     @AuraEnabled public String locationValue{get;set;}
    // }

   // public class fileUploadWrapper{
     //   @AuraEnabled public String startByte{get;set;}
     //  @AuraEnabled public String endByte{get;set;}
     //   @AuraEnabled public String chunkIndex{get;set;}
     //   @AuraEnabled public String fileName{get;set;}
     //   @AuraEnabled public String fileType{get;set;}
     //   @AuraEnabled public String folderId{get;set;}
     //   @AuraEnabled public String fileData{get;set;}
     //   @AuraEnabled public String totalChunks{get;set;}
    //  @AuraEnabled public String locationValue{get;set;}
    //}

    // @AuraEnabled
    // public static void uploadFileUnderDocument(String fileName, String fileType, String folderId, String fileData, String docId){
    //     try {
    //         if(fileData != null && fileType != null && fileName != null){
    //             GoogleDriveAPI.uploadFileToGoogleDrive(fileName, fileType, folderId, fileData, docId);
    //         }
    //     } catch (Exception e) {
    //         system.debug('Error in uploadFileUnderDocument ==> ' + e.getMessage());
    //         System.debug('line number ===> ' + e.getLineNumber());
    //     }
    // }
    
     @AuraEnabled(cacheable=false)
    public static List<Document__c> getDocuments(Id oppId){
        try {
            System.debug('oppId ===> ' + oppId);
            List<Document__c> documentList = [SELECT Id,Name,Opportunity__c,Document_Id__c, (SELECT Id,Document__c,File_URL__c,Name from Sub_Documents__r) from Document__c where Opportunity__c =:oppId];
            System.debug('size ==> ' + documentList.size());
            if(!documentList.isEmpty()){
                return documentList;
            }
            return null;
        } catch (Exception e) {
            system.debug('Error ===> ' + e.getMessage());
            system.debug('line ===> ' + e.getLineNumber());
            return null;
        }
    }
    
    // public static void createProjectFolder(List<Project__c> projectRec){
        
    //     if(!projectRec.isEmpty()){
            
    //         for(Project__c prj : projectRec){
                
    //             GoogleDriveAPI.createProjectFolder(prj.Id);
    //         }
    //     }	
        
    // }
    
    // public static void createEventFolder(List<Event__c> EventRec){
        
    //     if(!EventRec.isEmpty()){
            
    //         for(Event__c evt : EventRec){
                
    //             GoogleDriveAPI.createEventFolder(evt.Id);
    //         }
    //     }	  
    // }
    
    // public static void createBlogFolder(List<Blogs__c> BlogRec){
        
    //     if(!BlogRec.isEmpty()){
            
    //         for(Blogs__c blg : BlogRec){
                
    //             GoogleDriveAPI.createBlogFolder(blg.Id);
    //         }
    //     }	  
    // }
    
    // public static void createMarketingFolder(List<Marketing__c> MarketingRec){
        
    //     if(!MarketingRec.isEmpty()){
            
    //         for(Marketing__c mar : MarketingRec){
                
    //             GoogleDriveAPI.createMarketingFolder(mar.Id);
    //         }
    //     }	  
    // }
    
    // public static void createProjectUpdateFolder(List<Project_Updates__c> ProjectUpdateRec){
        
    //     if(!ProjectUpdateRec.isEmpty()){
            
    //         for(Project_Updates__c prjUpd : ProjectUpdateRec){
                
    //             ProjectUpdateHandler.updateProjectUpdateFolderId(prjUpd.Project__c);
    //         }
    //     }	  
    // }

    //Rams Method Starts here
    public static void createFolderOnGDrive(List<sObject> sbjRec){
        
        if(!sbjRec.isEmpty()){
            
            for(sObject sbj : sbjRec){
                
                GoogleDriveAPI.createGDriveFolder(sbj.Id);
            }
        }	  
    }
}