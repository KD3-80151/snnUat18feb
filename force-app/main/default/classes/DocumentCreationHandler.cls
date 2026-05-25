public without sharing class DocumentCreationHandler {
    
    /*Vamsi Krishna Reddy Gontu*/
    public void CreateDocuments(List<SObject> triggerNew){
        try {
            System.debug('triggerNew==>'+triggerNew); 
            List<Document__c> documentsToInsert = new List<Document__c>();
            List<String> docIds = new List<String>();
            Map<String,List<Document_category__c>> getAllData = new Map<String,List<Document_category__c>>();
            
            List<Document_category__c> getAllDocumentCategorys  = [select id,Name,Document_Master__r.Name, Document_Master__c from Document_category__c];
            for(Document_category__c docCat : getAllDocumentCategorys){
                String docMasterName = docCat.Document_Master__r.Name;
                if (!getAllData.containsKey(docMasterName)) {
                    getAllData.put(docMasterName, new List<Document_category__c>());
                }
                getAllData.get(docMasterName).add(docCat);
            }
            System.debug('getAllData==>'+getAllData);
            
            for (SObject record : triggerNew){
                String recordName = record.getSObjectType().getDescribe().getLabel(); 
                System.debug('recordName==>'+recordName);
                if (getAllData.containsKey(recordName)){
                    List<Document_category__c> relatedCategories = getAllData.get(recordName);          
                    for (Document_category__c category : relatedCategories) {
                        Document__c newDoc = new Document__c();
                        newDoc.Name = category.Name;
                        if(recordName == 'Opportunity'){
                            newDoc.Opportunity__c = record.Id;  
                        }else if(recordName == 'Unit'){
                            newDoc.Unit__c = record.Id;   
                        }else if(recordName == 'Project'){
                            newDoc.Project__c = record.Id;
                        }
                        documentsToInsert.add(newDoc);
                    }
                }
                if(recordName == 'Account'){
                    Account acc = (Account) record;
                    Account acc1 = [SELECT Id,Name, RecordTypeId FROM Account WHERE Id = :acc.Id LIMIT 1];
                    String recordType = Schema.SObjectType.Account.getRecordTypeInfosById().get(acc1.RecordTypeId).getName();
                    System.debug('recordType==>'+recordType);
                    if (getAllData.containsKey(recordType)){
                        String docName = 'Primary Applicant - ' + acc1.Name;
                        List<Document__c> docList = [SELECT Id,Name,Document_Id__c, Parent_Document__c from Document__c where Name LIKE: docName and Document_Id__c != null Order by CreatedDate Desc LIMIT 1];
                        List<Document_category__c> relatedCategories = getAllData.get(recordType);
                        for (Document_category__c category : relatedCategories) {
                            Document__c newDoc = new Document__c();
                            newDoc.Name = category.Name;
                            if(recordType == 'Channel Partner'){
                                newDoc.Account__c = record.Id;  
                            }else if(recordType == 'Customer' && !docList.isEmpty()){
                                newDoc.Parent_Document__c = docList[0].Id;
                            }
                            documentsToInsert.add(newDoc);
                        }
                    }
                }else if(recordName == 'Document'){
                    Document__c doc = (Document__c) record;
                    Document__c docRec = [SELECT Id,Name,Account__c,Account__r.Name, Account__r.RecordTypeId FROM Document__c WHERE Id = :doc.Id LIMIT 1];
                    String recordType = Schema.SObjectType.Account.getRecordTypeInfosById().get(docRec.Account__r.RecordTypeId).getName();
                    System.debug('recordType==>'+recordType);
                    if (getAllData.containsKey(recordType)){
                        List<Document_category__c> relatedCategories = getAllData.get(recordType);
                        for (Document_category__c category : relatedCategories) {
                            if(recordType == 'Customer'){
                                Document__c newDoc = new Document__c();
                                newDoc.Name = category.Name;
                                newDoc.Parent_Document__c = record.Id;
                                documentsToInsert.add(newDoc);
                            }
                        }
                    }
                }else if(recordName == 'Applicant'){
                    Applicant__c applicant = (Applicant__c) record;
                    Account acc1 = [SELECT Id, RecordTypeId FROM Account WHERE Id = :applicant.Account__c LIMIT 1];
                    String record_Type = Schema.SObjectType.Account.getRecordTypeInfosById().get(acc1.RecordTypeId).getName();
                    
                    if (record_Type == 'Customer') {
                        List<Document_category__c> relatedCategories = getAllData.get('Customer');
                        for (Document_category__c category : relatedCategories) {
                            Document__c newDoc = new Document__c();
                            newDoc.Name = category.Name;
                            newDoc.Applicant__c = record.Id;
                            documentsToInsert.add(newDoc);
                        }
                    }
                }                
                System.debug('documentsToInsert==>'+documentsToInsert);
            }
            // for (SObject record : triggerNew){
            //     System.debug('record==>'+record);
            //     record = (Account)record;
            //     String recordType = Schema.SObjectType.Account.getRecordTypeInfosById().get(record.RecordTypeId).getName();
            //     System.debug('recordType==>'+recordType);
            //     if (getAllData.containsKey(recordType)){
            //         List<Document_category__c> relatedCategories = getAllData.get(recordType);          
            //         for (Document_category__c category : relatedCategories) {
            //             Document__c newDoc = new Document__c();
            //             newDoc.Name = category.Name;
            //             if(recordType == 'Channel Partner'){
            //                 newDoc.Account__c = record.Id;  
            //             }else if(recordType == 'Customer'){
            //                 newDoc.Account__c = record.Id;   
            //             }
            //             documentsToInsert.add(newDoc);
            //         }
            //     }
            //     System.debug('documentsToInsert==>'+documentsToInsert);
            // }
            insert documentsToInsert;
            for(Document__c doc : documentsToInsert){
                docIds.add(doc.Id);
            }
            
            if(docIds.size() > 0){
                System.enqueueJob(new QueueableCreateFolderGDrive(docIds));
            }
            
        } catch (Exception e) {
            System.debug('Error in Creating Documents: ' + e.getMessage() + ' at line: ' + e.getLineNumber());
        } 
    }

    public class ReceiptFolderWrapper {
        @InvocableVariable(required=true)
        public Receipt__c subFolder;
    }

    @InvocableMethod(label='createTdsSubFolder' description='Cresting Document Folder inside TDS Folder of parent Opportunity')
    public static void createTdsSubFolder(List<ReceiptFolderWrapper> wrap) {
        List<Document__c> documentsToInsert = new List<Document__c>();
        List<String> docIds = new List<String>();
        try {
            System.debug('wrap[0].subFolder.Opportunity__c ---> ' + wrap[0].subFolder.Opportunity__c);
            if(Receipt__c.Opportunity__c == null) {
                return;
            }
            List <Opportunity> opp = [SELECT Id, Name, (SELECT Id, Name, Document_Id__c FROM Documents__r WHERE Name = 'TDS' LIMIT 1) FROM Opportunity WHERE Id = :wrap[0].subFolder.Opportunity__c LIMIT 1];
            Document__c newDoc = new Document__c();
            newDoc.Name = wrap[0].subFolder.Name;
            if(opp[0].Documents__r == null || opp[0].Documents__r.isEmpty()) {
                throw new AuraHandledException('TDS Folder not found in Opportunity');
            }
            newDoc.Parent_Document__c = opp[0].Documents__r[0].Id;
            documentsToInsert.add(newDoc);
            if(!documentsToInsert.isEmpty()) {
                insert documentsToInsert;
                for(Document__c doc : documentsToInsert){
                    docIds.add(doc.Id);
                }
                if(docIds.size() > 0){
                    queueReceiptSubFolderCreation(docIds);
                }
            }
        } catch (Exception e) {
            System.debug('Error in Creating Documents: ' + e.getMessage() + ' at line: ' + e.getLineNumber());
        }
    }

    public static void queueReceiptSubFolderCreation(List<String> docIds){
        System.debug('docIds--->' + docIds);
        System.enqueueJob(new QueueableCreateFolderGDrive(docIds));
    }
    
    
}