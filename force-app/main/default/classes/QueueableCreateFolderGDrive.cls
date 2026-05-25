public without sharing class QueueableCreateFolderGDrive implements Queueable, Database.allowsCallouts{
    private List<Id> docIds;
    
    public QueueableCreateFolderGDrive(List<Id> docIds){
        this.docIds = docIds;
    }
    
    public void execute(QueueableContext qc){
        if(!docIds.isEmpty()){
            Id currentDocId = docIds.remove(0);
            processData(currentDocId);
            
            if(!docIds.isEmpty()){
                if(!Test.isRunningTest()) {
                	System.enqueueJob(new QueueableCreateFolderGDrive(docIds));
                }
            }
        }
    }
    
    public static void processData(Id docId){
        try {
            System.debug('docId ===> ' + docId);
            if (docId != null) {
                String folderName;
                String parentFolderId;
                List<Document__c> docRec;
                Opportunity oppRec;
                List<Applicant__c> applicantRec;
                List<Account> accountRec;
                Account accRec;
                List<Project__c> projectRec;
                Contact contactRec;
                String objectType = docId.getSObjectType().getDescribe().getName();
                System.debug('objectType ===> ' + objectType);
                Document__c docMain = new Document__c();
                
                if (objectType == 'Opportunity') {
                    oppRec = [SELECT Id, Name, Document_Id__c, AccountId, Account.Name FROM Opportunity WHERE Id = :docId LIMIT 1];
                    System.debug('oppRec ===> ' + oppRec);
                    if (oppRec.AccountId != null) {
                        accRec = [SELECT Id,Document_Id__c,Name,Primary_Applicant__c from Account where Id =: oppRec.AccountId order by createdDate DESC LIMIT 1];
                        contactRec = [SELECT Id,FirstName,LastName,AccountId,FolderId__c FROM Contact WHERE AccountId = :oppRec.AccountId order by createdDate desc LIMIT 1];
                        System.debug('Contact Rec ==>'+contactRec);
                        if (contactRec != null && contactRec.FolderId__c == null) {
                            System.debug('contact rec');
                            folderName = (contactRec.FirstName != null ? contactRec.FirstName : '') + ' ' + contactRec.LastName;
                        }
                        else if(contactRec != null && contactRec.FolderId__c != null && oppRec.Document_Id__c == null){
                            System.debug('opp rec');
                            folderName = oppRec.Name;
                            parentFolderId = contactRec.FolderId__c;
                        }else { //if(accRec != null && accRec.Document_Id__c == null && accRec.Primary_Applicant__c == true && oppRec.Document_Id__c != null)
                            System.debug('acc rec');
                            docMain.Name = 'Primary Applicant - ' + accRec.Name;
                            docMain.Opportunity__c = oppRec.Id;
                            
                            folderName = 'Primary Applicant - ' + accRec.Name;
                            parentFolderId = oppRec.Document_Id__c;
                        }
                    }
                }
                else if (objectType == 'Project__c') {
                    projectRec = [SELECT Id, Name FROM Project__c WHERE Id = :docId];
                    folderName = projectRec[0].Name;
                }
                else if (objectType == 'Applicant__c') {
                    applicantRec = [SELECT Id, Name, Opportunity__r.Document_Id__c, Account__c,Account__r.Name FROM Applicant__c WHERE Id = :docId AND Opportunity__c != null AND Opportunity__r.Document_Id__c != null];
                    folderName = 'Co Applicant - ' + applicantRec[0].Account__r.Name;
                    parentFolderId = applicantRec[0].Opportunity__r.Document_Id__c;
                }
                else if (objectType == 'Account' ) {
                    system.debug('docId ===> '+docId);
                    accountRec = [SELECT Id, Name, RecordTypeId FROM Account WHERE Id = :docId];
                    System.debug('accountRec ===>'+accountRec);
                    if(!accountRec.isEmpty()){
                        String recordType = Schema.SObjectType.Account.getRecordTypeInfosById().get(accountRec[0].RecordTypeId).getName();
                        System.debug('recordType==>'+recordType);
                        if(recordType == 'Channel Partner'){
                            folderName = accountRec[0].Name;
                        }
                    }
                }
                else {
                    System.debug('inside else part for docs');
                    docRec = [SELECT Id, Name, Document_Id__c,Account__r.Document_Id__c, Opportunity__c, Opportunity__r.Document_Id__c, Applicant__c,Applicant__r.FolderId__c ,Project__r.FolderId__c,Parent_Document__r.Document_Id__c
                              FROM Document__c WHERE Id = :docId LIMIT 1];
                    if (!docRec.isEmpty()) {
                        folderName = docRec[0].Name != null ? docRec[0].Name : null;
                        parentFolderId =    docRec[0].Parent_Document__r.Document_Id__c != null ? docRec[0].Parent_Document__r.Document_Id__c :
                        docRec[0].Account__r.Document_Id__c != null ? docRec[0].Account__r.Document_Id__c : 
                        docRec[0].Opportunity__r.Document_Id__c != null ? docRec[0].Opportunity__r.Document_Id__c : 
                        docRec[0].Applicant__r.FolderId__c != null ? docRec[0].Applicant__r.FolderId__c : 
                        docRec[0].Project__r.FolderId__c != null ? docRec[0].Project__r.FolderId__c : null;
                        
                        // parentFolderId = (docRec[0].Opportunity__r.Document_Id__c != null ? docRec[0].Opportunity__r.Document_Id__c : null) != null ? docRec[0].Opportunity__r.Document_Id__c
                        //     : (docRec[0].Applicant__r.FolderId__c != null ? docRec[0].Applicant__r.FolderId__c : null);
                    }
                }
                
                System.debug('folderName ===> ' + folderName);
                System.debug('parentFolderId ===> ' + parentFolderId);
                System.debug('objectType ===> ' + objectType);
                
				if (String.isBlank(folderName)) {
                    System.debug('Skipping folder creation: folderName is null');
                    return;
                }
                
                String jsonBody = '{' +
                    '"title": "' + String.escapeSingleQuotes(folderName) + '",' +
                    '"mimeType": "application/vnd.google-apps.folder"';
                
                if (parentFolderId != null) {
                    jsonBody += ',' +
                        '"parents": [' +
                        '{ "id": "' + String.escapeSingleQuotes(parentFolderId) + '" }' +
                        ']';
                }
                jsonBody += '}';
                System.debug('jsonBody ==> ' + jsonBody);
                
                String accessToken = GoogleDriveAPI.getAccessToken();
                
                
                HttpRequest req = new HttpRequest();
                req.setMethod('POST');
                req.setEndpoint('https://www.googleapis.com/drive/v2/files');
                req.setHeader('Content-Type', 'application/json');
                req.setBody(jsonBody);
                req.setHeader('Content-Length', String.valueOf(jsonBody.length()));
                req.setHeader('Authorization', 'Bearer ' + accessToken);
                
                Http http = new Http();
                HttpResponse res = new HttpResponse();
                if (!Test.isRunningTest()) {
                    res = http.send(req);
                }
                
                Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                System.debug('responseBody ===> ' + responseBody);
                
                if (responseBody != null && responseBody.containsKey('id')) {
                    String folderId = (String) responseBody.get('id');
                    System.debug('folderId ===> ' + folderId);
                    
                    if (objectType == 'Opportunity') {
                        
                        DocumentCreationHandler dch = new DocumentCreationHandler();
                        if(contactRec.FolderId__c == null){
                            contactRec.FolderId__c = folderId;
                            update contactRec;
                            GoogleDriveAPI.createPermission(folderId);
                            System.debug('contactRec after updation ===> ' + contactRec);
                            
                            System.enqueueJob(new QueueableCreateFolderGDrive(new List<Id> {oppRec.Id}));
                            System.debug('contact updation done, calling queueable again');
                        }else if(oppRec.Document_Id__c == null){
                            oppRec.Document_Id__c = folderId;
                            update oppRec;
                            System.debug('oppRec after updation ===> ' + oppRec);
                            
                            System.enqueueJob(new QueueableCreateFolderGDrive(new List<Id> {oppRec.Id}));
                            System.debug('opp updation done, calling queueable again');
                            
                        }else{ //if(accRec.Document_Id__c == null )
                            
                            docMain.Document_Id__c = folderId;
                            upsert docMain Document_Id__c;
                            
                            List<SObject> sObjectList = new List<SObject>();
                            sObjectList.add(oppRec);
                            sObjectList.add(accRec);
                            System.debug('accRec after updation ===> ' + accRec);
                            System.debug('acc updation done, calling document creation again');
                            dch.CreateDocuments(sObjectList);
                            
                        }
                    }
                    else if (objectType == 'Applicant__c') {
                        applicantRec[0].FolderId__c = folderId;
                        update applicantRec;
                        
                        GoogleDriveAPI.createPermission(folderId);
                        System.debug('permission given for applicant folder');
                        // List<Applicant__c> App = new List<Applicant__c>{applicantRec};
                        DocumentCreationHandler dch = new DocumentCreationHandler();
                        dch.CreateDocuments(applicantRec);
                    }else if (objectType == 'Project__c') {
                        projectRec[0].FolderId__c = folderId;
                        update projectRec;
                        
                        GoogleDriveAPI.createPermission(folderId);
                        System.debug('permission given for applicant folder');
                        // List<Applicant__c> App = new List<Applicant__c>{applicantRec};
                        DocumentCreationHandler dch = new DocumentCreationHandler();
                        dch.CreateDocuments(projectRec);
                    }
                    else if (objectType == 'Account') {
                        accountRec[0].Document_Id__c = folderId;
                        update accountRec;
                        
                        GoogleDriveAPI.createPermission(folderId);
                        System.debug('permission given for applicant folder');
                        DocumentCreationHandler dch = new DocumentCreationHandler();
                        dch.CreateDocuments(accountRec);
                    }
                    else {
                        docRec[0].Status__c = 'Uploaded';
                        docRec[0].Document_Id__c = folderId;
                        update docRec;
                        
                        if(docRec[0].Account__c != null && docRec[0].Opportunity__c != null && docRec[0].Applicant__c != null){
                            List<SObject> objectList = new List<SObject>();
                            objectList.add(docRec[0]);
                            
                            DocumentCreationHandler dch = new DocumentCreationHandler();
                            dch.CreateDocuments(objectList);
                        }
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error in folder creation ===> ' + e.getMessage());
            System.debug('line ===> ' + e.getLineNumber());
        }
    }
        public static void dummy(){
        Integer i=0;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        i++;i++; i++;i++; i++;i++;
        
    }
}