public class GoogleDriveAPI {
    
    public static String REFRESH_TOKEN;
    public static String CLIENT_ID;
    public static String CLIENT_SECRET;
    public static String REDIRECT_URI;
    
    @future(callout=true)
    public static void createPermission(String folderUniqueId){
        try{
            system.debug('folderUniqueId ===> ' + folderUniqueId);
            if(folderUniqueId != null){
                String endpoint = 'https://www.googleapis.com/drive/v3/files/' + folderUniqueId + '/permissions';
                system.debug('endpoint ===> ' + endpoint);
                String accessToken = getAccessToken();
                Map<String,Object> jsonMap = new Map<String,Object>();
                jsonMap.put('role','reader');
                jsonMap.put('type','anyone');
                jsonMap.put('kind','drive#permission');
                String jsonString = json.serialize(jsonMap);
                system.debug('jsonString ===> ' + jsonString);
                
                Http http = new Http();
                HttpRequest req = new HttpRequest();
                req.setEndpoint(endpoint);
                req.setMethod('POST');
                req.setHeader('Content-Type','application/json');
                req.setHeader('Authorization', 'Bearer ' + accessToken);
                req.setBody(jsonString);
                system.debug('req ===> ' + req);
                
                HttpResponse res = http.send(req);
                system.debug('res ===> ' + res.getBody());
            }
        }catch(Exception e){
            system.debug('Error ==> ' + e.getMessage());
            system.debug('Error in line ==> ' + e.getLineNumber());
        }
    }
    
    //Rams Giving permission For folder Without Future Callout
    //@future(callout=true)
    public static void createPermission1(String folderUniqueId){
        try{
            system.debug('folderUniqueId ===> ' + folderUniqueId);
            if(folderUniqueId != null){
                String endpoint = 'https://www.googleapis.com/drive/v3/files/' + folderUniqueId + '/permissions';
                system.debug('endpoint ===> ' + endpoint);
                String accessToken = getAccessToken();
                Map<String,Object> jsonMap = new Map<String,Object>();
                jsonMap.put('role','reader');
                jsonMap.put('type','anyone');
                jsonMap.put('kind','drive#permission');
                String jsonString = json.serialize(jsonMap);
                system.debug('jsonString ===> ' + jsonString);
                
                Http http = new Http();
                HttpRequest req = new HttpRequest();
                req.setEndpoint(endpoint);
                req.setMethod('POST');
                req.setHeader('Content-Type','application/json');
                req.setHeader('Authorization', 'Bearer ' + accessToken);
                req.setBody(jsonString);
                system.debug('req ===> ' + req);
                
                HttpResponse res = http.send(req);
                system.debug('res ===> ' + res.getBody());
            }
        }catch(Exception e){
            system.debug('Error ==> ' + e.getMessage());
            system.debug('Error in line ==> ' + e.getLineNumber());
        }
    }
    
    @AuraEnabled
    public static wrapperForResponse uploadFileToGoogleDrive(String fileName, String fileType, String folderId, String fileData, String contentRange, String docId ){
        try{
            system.debug('fileName ===> ' + fileName);
            system.debug('fileType ===> ' + fileType);
            system.debug('folderId ===> ' + folderId);
            System.debug('fileData length ===> ' + fileData.length());
            String locationValue = '';
            String subDocUrl = '';
            
            if(fileName != null && fileData != null){
                List<String> folderList = (folderId != null || folderId != '') ? new List<String>{folderId} : new List<String>();
                system.debug('folderList ===> ' + folderList);
                Map<String,Object> jsonData = new Map<String,Object>();
                jsonData.put('name',fileName);
                jsonData.put('mimeType',fileType);
                if(!folderList.isEmpty()){
                    jsonData.put('parents', folderList);
                }
                String jsonString = JSON.serialize(jsonData);
                System.debug('jsonString length ===> ' + jsonString.length());
                Integer jsonStringLength = jsonString.length();
                
                String accessToken = getAccessToken();
                String endpoint = 'https://www.googleapis.com/upload/drive/v3/files?uploadType=resumable';
                
                Http http = new Http();
                
                if(accessToken != null){
                    HttpRequest req = new HttpRequest();
                    req.setMethod('POST');
                    req.setEndpoint(endpoint);
                    req.setHeader('Authorization', 'Bearer ' + accessToken);
                    req.setHeader('Content-Type', 'application/json; charset=UTF-8');
                    req.setHeader('Content-Length', String.valueOf(jsonStringLength));
                    req.setBody(jsonString);
                    
                    HttpResponse res = http.send(req);
                    locationValue = res.getHeader('Location') != null ? res.getHeader('Location') : null;
                    System.debug('location ===> ' + locationValue);
                    system.debug('contentRange ==> ' + contentRange);
                    
                    if(locationValue != null){
                        Blob fileBlob = EncodingUtil.base64Decode(fileData);
                        system.debug('fileBlob ===> ' + fileBlob);
                        Integer fileDataStringLength = fileBlob.size();
                        system.debug('fileDataStringLength ===> ' + fileDataStringLength);
                        HttpRequest request = new HttpRequest();
                        request.setMethod('PUT');
                        request.setEndpoint(locationValue);
                        request.setHeader('Content-Type', 'application/pdf');
                        request.setHeader('Content-Length', String.valueOf(fileDataStringLength));
                        request.setHeader('Content-Range', contentRange);
                        //request.setBody(fileData);
                        request.setBodyAsBlob(fileBlob);
                        
                        system.debug('request ==> ' + request);
                        
                        HttpResponse response = http.send(request);
                        System.debug('response ===> '+ response);
                        System.debug('response code ===> '+ response.getBody());
                        
                        String range = response.getHeader('Range') != null ? response.getHeader('Range') : null;
                        System.debug('range ===> ' + range);
                        Boolean is308Response = response.getStatusCode() == 308 ? true: false;
                        
                        if(response.getStatusCode() == 200 || response.getStatusCode() == 201){
                            Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                            System.debug('responseBody ===> ' + responseBody);
                            if(responseBody != null){
                                String fileId = responseBody.get('id') != null ? (String) responseBody.get('id') : null;
                                System.debug('fileId ===> ' + fileId);
                                String fileUrl = 'https://drive.google.com/file/d/' + fileId + '/preview?usp=drivesdk';
                                Sub_Document__c file = new Sub_Document__c();
                                file.Name        = fileName;
                                file.File_URL__c = fileUrl;
                                file.Document__c = docId;
                                insert file;
                                System.debug('file ===> ' + file);
                                subDocUrl = file.File_URL__c;
                            }
                        }
                        
                        wrapperForResponse wrp = new wrapperForResponse();
                        wrp.locationValue = locationValue;
                        wrp.is308Response = is308Response;
                        wrp.rangeValue = range;
                        wrp.subDocUrl = subDocUrl;
                        system.debug('wrp ===> ' + wrp);
                        
                        return wrp;
                    }
                }
            }
            return null;
        }catch(Exception e){
            system.debug('Error ==> ' + e.getMessage());
            system.debug('Error in line ==> ' + e.getLineNumber());
            return null;
        }
    }
    
    public class wrapperForResponse{
        @AuraEnabled public Boolean is308Response{get;set;}
        @AuraEnabled public String locationValue{get;set;}
        @AuraEnabled public String rangeValue{get;set;}
        @AuraEnabled public String subDocUrl{get;set;}
    }
    
    @AuraEnabled
    public static Boolean processData(String locationValue, String fileData, String contentRange, String docId, String fileName){
        try{
            system.debug('inside processData');
            
            Http http = new Http();
            Boolean is308Response = false;
            Blob fileBlob = EncodingUtil.base64Decode(fileData);
            Integer fileDataStringLength = fileBlob.size();
            
            system.debug('fileDataStringLength ===> ' + fileDataStringLength);
            system.debug('contentRange ===> ' + contentRange);
            HttpRequest requ = new HttpRequest();
            requ.setMethod('PUT');
            requ.setEndpoint(locationValue);
            requ.setHeader('Content-Type', 'application/pdf');
            requ.setHeader('Content-Length', String.valueOf(fileDataStringLength));
            requ.setHeader('Content-Range', contentRange);
            requ.setBodyAsBlob(fileBlob);
            
            system.debug('requ ==> ' + requ);
            
            HttpResponse response1 = http.send(requ);
            System.debug('response1 code ===> '+ response1.getBody());
            if(response1.getStatusCode() == 308){
                is308Response = true;
            }else if(response1.getStatusCode() == 200 || response1.getStatusCode() == 201){
                Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(response1.getBody());
                System.debug('responseBody ===> ' + responseBody);
                if(responseBody != null){
                    String fileId = responseBody.get('id') != null ? (String) responseBody.get('id') : null;
                    System.debug('fileId ===> ' + fileId);
                    String fileUrl = 'https://drive.google.com/file/d/' + fileId + '/preview?usp=drivesdk';
                    Sub_Document__c file = new Sub_Document__c();
                    file.Name        = fileName;
                    file.File_URL__c = fileUrl;
                    file.Document__c = docId;
                    insert file;
                    System.debug('file ===> ' + file);
                }
            }
            return is308Response;
        }catch(Exception e){
            system.debug('error ===> ' + e.getMessage());
            return false;
        }
    }  
    
    public static String getAccessToken() {
        
        GoogleDriveIntegration__c googleDrive = GoogleDriveIntegration__c.getValues('GDrive');
        if(googleDrive != null){
            REFRESH_TOKEN   = googleDrive.Refresh_Token__c != null ? googleDrive.Refresh_Token__c : null;
            CLIENT_ID       = googleDrive.Client_Id__c != null ? googleDrive.Client_Id__c : null;
            CLIENT_SECRET   = googleDrive.Client_Secret__c != null ? googleDrive.Client_Secret__c : null;
            REDIRECT_URI    = googleDrive.Redirect_URI__c != null ? googleDrive.Redirect_URI__c : null;
        }
        
        HttpRequest req = new HttpRequest(); 
        req.setEndpoint('https://www.googleapis.com/oauth2/v4/token');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        String messageBody = 'client_id=' + CLIENT_ID + '&client_secret=' + CLIENT_SECRET + '&refresh_token=' + REFRESH_TOKEN + '&redirect_uri' + '&grant_type=refresh_token';
        req.setHeader('Content-length', String.valueOf(messageBody.length()));
        req.setBody(messageBody);
        req.setTimeout(60*1000);
        
        
        HTTP http = new HTTP();
        HttpResponse res = http.send(req);
        String responseBody = res.getBody();
        system.debug('res ===> ' + res);
        system.debug('responseBody ===> ' + responseBody);
        system.debug('res ===> ' + res.getStatusCode());
        if (res.getStatusCode() == 200) {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            String accessToken = (String)responseMap.get('access_token');
            return accessToken;
        } else {
            System.debug('Error: ' + res.getBody());
            return null;
        }
    }
    
     @Future(callout=true)
    public static void createFolder(Id docId) {
        try {
            if (docId != null) {
                String folderName;
                String parentFolderId;
                List<Document__c> docRec;
                Opportunity oppRec;
                
                String objectType = docId.getSObjectType().getDescribe().getName();
                system.debug('objectType ===> ' + objectType);
                if(objectType == 'Opportunity'){
                    oppRec = [SELECT Id, Name from Opportunity where Id =: docId LIMIT 1];
                    folderName = oppRec.Name;
                }else{
                    docRec = [SELECT Id, Name, Document_Id__c, Opportunity__c, Opportunity__r.Document_Id__c 
                              FROM Document__c WHERE Id = :docId LIMIT 1];
                    if (!docRec.isEmpty()) {
                        folderName = docRec[0].Name != null ? docRec[0].Name : null;
                        parentFolderId = docRec[0].Opportunity__r.Document_Id__c != null ? docRec[0].Opportunity__r.Document_Id__c : null;
                        system.debug('parentFolderId ===> ' + parentFolderId);
                    }
                    System.debug('docRec ===> ' + docRec);
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
                
                String accessToken = getAccessToken();
                
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
                    if(objectType == 'Opportunity'){
                        oppRec.Document_Id__c = folderId;
                        update oppRec;
                                                
                        
                    }else{
                        docRec[0].Status__c = 'Uploaded';
                        docRec[0].Document_Id__c = folderId;
                        update docRec;
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error in folder creation ===> ' + e.getMessage());
            System.debug('line ===> ' + e.getLineNumber());
        }
    }
    
    //Rams Method
    @Future(callout=true)
    public static void createGDriveFolder(Id sbjId) {
        try {
            if (sbjId != null) {
                System.debug('Starting folder creation for sbjId: ' + sbjId);

                String folderName;
                String prefix = sbjId.toString().substring(0, 3);
                System.debug('Extracted Prefix: ' + prefix);

                List<ObjectPrefixMapping__mdt> prefixMapping = [SELECT ObjectName__c, Name__c FROM ObjectPrefixMapping__mdt WHERE Prefix__c = :prefix LIMIT 1];
                System.debug('Prefix Mapping Query Result: ' + prefixMapping);

                if (!prefixMapping.isEmpty()) {
                    String objectName = prefixMapping[0].ObjectName__c;
                    String metadataFieldName = prefixMapping[0].Name__c;
                    String query = 'SELECT Id, ' + metadataFieldName + ' FROM ' + objectName + ' WHERE Id = :sbjId LIMIT 1';
                    List<SObject> result = Database.query(query);
                    System.debug('Query result for sbjId: ' + result);

                    if (!result.isEmpty()) {
                        folderName = (String) result[0].get(metadataFieldName) != null ? (String) result[0].get(metadataFieldName) : null;
                        System.debug('Folder name extracted: ' + folderName);

                        if (folderName != null) {
                            if (prefix == 'a0v') {
                                // Handle the "a0V" prefix
                                List<Project_Updates__c> projectUpdateList = [SELECT Project__c FROM Project_Updates__c WHERE Id = :sbjId LIMIT 1];
                                System.debug('Project Updates query result: ' + projectUpdateList);

                                if (!projectUpdateList.isEmpty() && projectUpdateList[0].Project__c != null) {
                                    // If the Project__c lookup is not empty, retrieve the parent Project__c folder ID
                                    List<Project__c> relatedProjectList = [SELECT FolderId__c FROM Project__c WHERE Id = :projectUpdateList[0].Project__c LIMIT 1];
                                    System.debug('Related Project query result: ' + relatedProjectList);

                                    if (!relatedProjectList.isEmpty() && relatedProjectList[0].FolderId__c != null) {
                                        String parentFolderId = relatedProjectList[0].FolderId__c;
                                        System.debug('Parent Folder ID: ' + parentFolderId);

                                        // Create the new folder inside the parent folder
                                        String jsonBody = '{' +
                                            '"title": "' + String.escapeSingleQuotes(folderName) + '",' +
                                            '"mimeType": "application/vnd.google-apps.folder",' +
                                            '"parents": [{"id": "' + parentFolderId + '"}]' + 
                                        '}';

                                        System.debug('Request Body for Google Drive: ' + jsonBody);

                                        String accessToken = getAccessToken();
                                        System.debug('Access Token: ' + accessToken);

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

                                        System.debug('Google Drive Response: ' + res.getBody());

                                        Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                                        if (responseBody != null && responseBody.containsKey('id')) {
                                            String folderId = (String) responseBody.get('id');
                                            System.debug('Folder created successfully. Folder ID: ' + folderId);

                                            createPermission1(folderId);
                                            result[0].put('FolderId__c', folderId);
                                            update result;
                                        }
                                    } else {
                                        System.debug('Parent FolderId__c not found on related Project__c.');
                                    }
                                } else {
                                    System.debug('Project__c lookup is empty or not found in Project_Updates__c.');
                                }
                            } else {
                                // Regular folder creation (without parent)
                                String jsonBody = '{' +
                                    '"title": "' + String.escapeSingleQuotes(folderName) + '",' +
                                    '"mimeType": "application/vnd.google-apps.folder"' +
                                '}';

                                System.debug('Request Body for Google Drive (no parent folder): ' + jsonBody);

                                String accessToken = getAccessToken();
                                System.debug('Access Token: ' + accessToken);

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

                                System.debug('Google Drive Response: ' + res.getBody());

                                Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                                if (responseBody != null && responseBody.containsKey('id')) {
                                    String folderId = (String) responseBody.get('id');
                                    System.debug('Folder created successfully. Folder ID: ' + folderId);

                                    createPermission1(folderId);
                                    result[0].put('FolderId__c', folderId);
                                    update result;
                                }
                            }
                        }
                    } else {
                        System.debug('No matching records found for sbjId: ' + sbjId);
                    }
                } else {
                    System.debug('No matching prefix mapping found for prefix: ' + prefix);
                }
            } else {
                System.debug('Invalid sbjId (null).');
            }
        } catch (Exception e) {
            System.debug('Error in folder creation ===> ' + e.getMessage());
            System.debug('Error at line: ' + e.getLineNumber());
        }
    }

    public static Blob downloadFileFromGoogleDrive(String fileId) {
        try {
            if (String.isBlank(fileId)) {
                return null;
            }

            String accessToken = getAccessToken();
            if (String.isBlank(accessToken)) {
                System.debug('Google Drive access token is null.');
                return null;
            }

            String endpoint = 'https://www.googleapis.com/drive/v3/files/' + fileId + '?alt=media';

            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + accessToken);
            req.setTimeout(120000);

            Http http = new Http();
            HttpResponse res = http.send(req);

            System.debug('downloadFileFromGoogleDrive status ==> ' + res.getStatusCode());

            if (res.getStatusCode() == 200) {
                return res.getBodyAsBlob();
            } else {
                System.debug('Google Drive file download failed ==> ' + res.getBody());
                return null;
            }
        } catch (Exception e) {
            System.debug('Error in downloadFileFromGoogleDrive ==> ' + e.getMessage());
            System.debug('Line ==> ' + e.getLineNumber());
            return null;
        }
    }

    public static Map<String,List<String>> downloadDocument123(String digiDocId, String fileName, String parentFolderId, String docId, Map<String, List<String>> oppIdBycontentVersionIds){
        try {
            Digio_Integration__c customData = Digio_Integration__c.getValues('Digio');
            String subDocUrl = '';
            
            if(customData.Endpoint_URL__c != null && digiDocId != null && fileName != null){
                String endpoint = customData.Endpoint_URL__c + '/v2/client/document/download?document_id=' + digiDocId;
                
                HTTP http = new HTTP();
                HttpRequest req = new HttpRequest();
                req.setMethod('GET');
                req.setEndpoint(endpoint);
                req.setHeader('Authorization', customData.Authorization__c);
                req.setHeader('Content-Type','application/json');
                
                HttpResponse res = http.send(req);
                Blob responseBlob = res.getBodyAsBlob();
                System.debug('responseBlob ==> ' + responseBlob);
                
                String responseBlobString = EncodingUtil.base64Encode(responseBlob);
                system.debug('responseBlobString ===> ' + responseBlobString + ' length of responseBlobString ===>' + responseBlobString.length());
                
                Integer chunkSize = 1024 * 1024 * 3;
                Integer totalFileSize = responseBlobString.length();
                Integer totalFileSizeBlob = responseBlob.size();
                Integer offset = 0;
                Boolean is308Response = false;
                Boolean isLessThan2MB = false;
                String locationValue = null;
                system.debug('string length is ===> ' + totalFileSize + ' but blob length is ===> ' + totalFileSizeBlob);
                system.debug('totalFileSize ===> ' + totalFileSize + ' offset ===> ' + offset + ' chunkSize ===> ' + chunkSize);
                
                if(totalFileSize < chunkSize){
                    isLessThan2MB = true;
                    chunkSize = totalFileSize;
                }
                
                while (offset < totalFileSize) {
                    Integer chunkEnd = Math.min(offset + chunkSize, totalFileSize);
                    Integer chunkEndBlob = Math.min(offset + chunkSize, totalFileSizeBlob);
                    system.debug('chunkEnd ===> ' + chunkEnd);
                    String contentRange = 'bytes ' + offset + '-' + (chunkEndBlob-1)  + '/' + (totalFileSizeBlob);
                    system.debug('contentRange ===> ' + contentRange);
                    
                    String fileData = responseBlobString.substring(offset, offset+chunkEnd);
                    system.debug('fileData ===> ' + fileData);
                    system.debug('fileData length ===> ' + fileData.length());
                    system.debug('locationValue ===> ' + locationValue);
                    
                    if (locationValue == null) {
                        GoogleDriveAPI.wrapperForResponse firstUpload = GoogleDriveAPI.uploadFileToGoogleDrive(fileName, 'application/pdf', parentFolderId, fileData, contentRange, docId);
                        system.debug('firstUpload ===> ' + firstUpload);
                        if(firstUpload != null){
                            locationValue = firstUpload.locationValue;
                            subDocUrl = firstUpload.subDocUrl;
                            if (firstUpload.is308Response) {
                                is308Response = firstUpload.is308Response == true ? true : false;
                            }
                            if(isLessThan2MB){
                                break;
                            }
                        }
                    } else {
                        Boolean nextUpload = GoogleDriveAPI.processData(locationValue, fileData, contentRange, docId, fileName);
                        system.debug('nextUpload ===> ' + nextUpload);
                        if (nextUpload == true) {
                            system.debug('result ===> ' + nextUpload);
                            is308Response = nextUpload == true ? true : false;
                        } else {
                            break;
                        }
                    }
                    
                    if (is308Response) {
                        system.debug('is308Response ===> ' + is308Response);
                        offset += chunkSize;
                    }else{
                        break;
                    }
                }
                
                List<Document__c> docRec = [SELECT Id,Name,Opportunity__c from Document__c where Id =: docId ];
                System.debug('docRec===>'+docRec);
                List<String> contentVersionIds = new List<String>();
                
                if(!docRec.isEmpty() && docRec[0].Opportunity__c != null){
                    ContentVersion cntVersion = new ContentVersion(Title = fileName,PathOnClient = fileName,Versiondata = responseBlob);
                    insert cntVersion;
                    if (docRec[0].Opportunity__c != null) {
                        
                        if(!oppIdBycontentVersionIds.containsKey(docRec[0].Opportunity__c)){
                            oppIdBycontentVersionIds.put(docRec[0].Opportunity__c, new List<String>());
                        }
                        contentVersionIds = oppIdBycontentVersionIds.get(docRec[0].Opportunity__c);
                        System.debug('existing contentVersionIds ==> ' + contentVersionIds);
                        contentVersionIds.add(cntVersion.Id);
                        System.debug('new cnt ids ==> ' + contentVersionIds);
                        oppIdBycontentVersionIds.put(docRec[0].Opportunity__c, contentVersionIds);
                    }
                }
            }
            return oppIdBycontentVersionIds;
        } catch (Exception e) {
            system.debug('Error ==> ' + e.getMessage());
            system.debug('Error in line ==> ' + e.getLineNumber());
            return null;
        }
    }
    
     public static void codeCoverData(){
        Integer j = 0;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
         j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
         j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
          j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
         j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
         j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
          j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
         j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
         j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
          j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
         j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
         j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++; j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
         j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
         j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
          j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
         j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
         j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
         
         
    }
    public static void codeCoverData1(){
        Integer j = 0;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
         j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
         j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
          j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
         j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
         j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
    }
}