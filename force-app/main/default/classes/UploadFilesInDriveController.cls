public withOut sharing class UploadFilesInDriveController {

    public static String REFRESH_TOKEN;
    public static String CLIENT_ID;
    public static String CLIENT_SECRET;
    public static String REDIRECT_URI;

    @AuraEnabled(cacheable=true)
    public static String getFolderId(String recordId) {
        try {
            if (recordId != null) {
                String prefix = recordId.substring(0, 3);
                List<ObjectPrefixMapping__mdt> mdtRecords = [SELECT MasterLabel, Prefix__c, ObjectName__c FROM ObjectPrefixMapping__mdt];
                String folderId = null;
                String objectName = null;
                for (ObjectPrefixMapping__mdt mdtRecord : mdtRecords) {
                    if (mdtRecord.Prefix__c == prefix) {
                        objectName = mdtRecord.ObjectName__c;
                        break;
                    }
                }

                if (objectName != null) {
                    String folderIdField = 'folderId__c';
                    String queryString = 'SELECT ' + folderIdField + ' FROM ' + objectName + ' WHERE Id = :recordId LIMIT 1';
                    List<SObject> results = Database.query(queryString);

                    if (!results.isEmpty()) {
                        folderId = (String) results[0].get(folderIdField);
                    }

                    if (String.isNotEmpty(folderId)) {
                        System.debug('Found folder ID: ' + folderId);
                        return folderId;
                    } else {
                        System.debug('Error: Folder ID is empty or not found for the provided recordId');
                        return 'Error: Folder ID is empty or not found for the provided recordId';
                    }
                } else {
                    System.debug('Error: No matching object found for the provided recordId prefix');
                    return 'Error: No matching object found for the provided recordId prefix';
                }
            } else {
                System.debug('Error: Invalid record ID (null or empty)');
                return 'Error: Invalid record ID (null or empty)';
            }
        } catch (QueryException e) {
            System.debug('Error: SOQL query failed - ' + e.getMessage());
            return 'Error: SOQL query failed - ' + e.getMessage();
        } catch (Exception e) {
            System.debug('Error: Unexpected error - ' + e.getMessage());
            return 'Error: Unexpected error - ' + e.getMessage();
        }
    }

    public static String getAccessToken() {
        GoogleDriveIntegration__c googleDrive = GoogleDriveIntegration__c.getValues('GDrive');
        if (googleDrive != null) {
            REFRESH_TOKEN = googleDrive.Refresh_Token__c != null ? googleDrive.Refresh_Token__c : null;
            CLIENT_ID = googleDrive.Client_Id__c != null ? googleDrive.Client_Id__c : null;
            CLIENT_SECRET = googleDrive.Client_Secret__c != null ? googleDrive.Client_Secret__c : null;
            REDIRECT_URI = googleDrive.Redirect_URI__c != null ? googleDrive.Redirect_URI__c : null;
        }

        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://www.googleapis.com/oauth2/v4/token');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        String messageBody = 'client_id=' + CLIENT_ID + '&client_secret=' + CLIENT_SECRET + '&refresh_token=' + REFRESH_TOKEN + '&redirect_uri' + '&grant_type=refresh_token';
        req.setHeader('Content-length', String.valueOf(messageBody.length()));
        req.setBody(messageBody);
        req.setTimeout(60 * 1000);

        HTTP http = new HTTP();
        HttpResponse res = http.send(req);
        String responseBody = res.getBody();
        if (res.getStatusCode() == 200) {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            String accessToken = (String) responseMap.get('access_token');
            System.debug('Access token retrieved: ' + accessToken);
            return accessToken;
        } else {
            System.debug('Failed to get access token: ' + res.getStatusCode() + ' - ' + res.getBody());
            return null;
        }
    }

    @AuraEnabled
    public static wrapperForResponse uploadFileToGoogleDrive(String fileName, String fileType, String folderId, String fileData, String contentRange, String docId) {
        try {
            System.debug('Starting uploadFileToGoogleDrive with fileName: ' + fileName + ', fileType: ' + fileType + ', folderId: ' + folderId);

            String locationValue = '';
            Map<String, String> prefixToObjectNameMap = new Map<String, String>();
            List<ObjectPrefixMapping__mdt> mdtRecords = [SELECT Prefix__c, ObjectName__c FROM ObjectPrefixMapping__mdt];
            for (ObjectPrefixMapping__mdt mdtRecord : mdtRecords) {
                prefixToObjectNameMap.put(mdtRecord.Prefix__c, mdtRecord.ObjectName__c);
            }

            if (fileName != null && fileData != null) {
                String accessToken = getAccessToken();
                System.debug('Retrieved access token: ' + accessToken);

                String checkFileEndpoint = 'https://www.googleapis.com/drive/v3/files?q=name+%3D+%22' + EncodingUtil.urlEncode(fileName, 'UTF-8') + '%22+and+%27' + folderId + '%27+in+parents&fields=files(id,name)';
                System.debug('Checking if file exists at endpoint: ' + checkFileEndpoint);

                Http http = new Http();
                HttpRequest checkFileRequest = new HttpRequest();
                checkFileRequest.setMethod('GET');
                checkFileRequest.setEndpoint(checkFileEndpoint);
                checkFileRequest.setHeader('Authorization', 'Bearer ' + accessToken);
                checkFileRequest.setHeader('Content-Type', 'application/json');

                HttpResponse checkFileResponse = http.send(checkFileRequest);
                Map<String, Object> checkFileResponseMap = (Map<String, Object>) JSON.deserializeUntyped(checkFileResponse.getBody());
                List<Object> files = (List<Object>) checkFileResponseMap.get('files');

                if (files != null && files.size() > 0) {
                    System.debug('File already exists: ' + fileName);
                    wrapperForResponse wrp = new wrapperForResponse();
                    wrp.locationValue = 'File already exists';
                    return wrp;
                }

                List<String> folderList = (folderId != null || folderId != '') ? new List<String>{folderId} : new List<String>();
                Map<String, Object> jsonData = new Map<String, Object>();
                jsonData.put('name', fileName);
                if (!folderList.isEmpty()) {
                    jsonData.put('parents', folderList);
                }
                String jsonString = JSON.serialize(jsonData);
                Integer jsonStringLength = jsonString.length();
                System.debug('JSON for file upload: ' + jsonString);
                System.debug('JSON string length: ' + jsonStringLength);

                String endpoint = 'https://www.googleapis.com/upload/drive/v3/files?uploadType=resumable';
                HttpRequest req = new HttpRequest();
                req.setMethod('POST');
                req.setEndpoint(endpoint);
                req.setHeader('Authorization', 'Bearer ' + accessToken);
                req.setHeader('Content-Type', 'application/json; charset=UTF-8');
                req.setHeader('Content-Length', String.valueOf(jsonStringLength));
                req.setBody(jsonString);

                HttpResponse res = http.send(req);
                locationValue = res.getHeader('Location') != null ? res.getHeader('Location') : null;
                System.debug('Received Location header: ' + locationValue);

                if (locationValue != null) {
                    Blob fileBlob = EncodingUtil.base64Decode(fileData);
                    Integer fileDataStringLength = fileBlob.size();
                    System.debug('File data size (in bytes): ' + fileDataStringLength);

                    HttpRequest uploadRequest = new HttpRequest();
                    uploadRequest.setMethod('PUT');
                    uploadRequest.setEndpoint(locationValue);
                    uploadRequest.setHeader('Content-Type', fileType);
                    uploadRequest.setHeader('Content-Length', String.valueOf(fileDataStringLength));
                    uploadRequest.setHeader('Content-Range', contentRange);
                    uploadRequest.setBodyAsBlob(fileBlob);

                    System.debug('Uploading file: Content-Range = ' + contentRange + ', Content-Length = ' + fileDataStringLength);
                    HttpResponse uploadResponse = http.send(uploadRequest);
                    System.debug('Upload response status: ' + uploadResponse.getStatusCode());
                    System.debug('Upload response body: ' + uploadResponse.getBody());

                    if (uploadResponse.getStatusCode() == 200 || uploadResponse.getStatusCode() == 201) {
                        Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(uploadResponse.getBody());
                        if (responseBody != null) {
                            String fileId = (String) responseBody.get('id');
                            String fileUrl = 'https://drive.google.com/file/d/' + fileId + '/preview?usp=drivesdk';
                            Sub_Document__c file = new Sub_Document__c();
                            file.Name = fileName;
                            file.File_URL__c = fileUrl;

                            String recordPrefix = docId != null && docId.length() > 3 ? docId.substring(0, 3) : null;
                            if (recordPrefix != null && prefixToObjectNameMap.containsKey(recordPrefix)) {
                                String lookupObject = prefixToObjectNameMap.get(recordPrefix);
                                file.put(lookupObject, docId);
                                insert file;
                            }
                        }
                    }

                    wrapperForResponse wrp = new wrapperForResponse();
                    wrp.locationValue = locationValue;
                    wrp.is308Response = uploadResponse.getStatusCode() == 308 ? true : false;
                    wrp.rangeValue = uploadResponse.getHeader('Range');
                    return wrp;
                }
            }
            return null;
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
            return null;
        }
    }

    public class wrapperForResponse {
        @AuraEnabled public Boolean is308Response{get; set; }
        @AuraEnabled public String locationValue{get; set; }
        @AuraEnabled public String rangeValue{get; set; }
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
                file.Name = fileName;
                file.File_URL__c = fileUrl;
                
                Map<String, String> prefixToObjectNameMap = new Map<String, String>();
                List<ObjectPrefixMapping__mdt> mdtRecords = [SELECT Prefix__c, ObjectName__c FROM ObjectPrefixMapping__mdt];
                for (ObjectPrefixMapping__mdt mdtRecord : mdtRecords) {
                    prefixToObjectNameMap.put(mdtRecord.Prefix__c, mdtRecord.ObjectName__c);
                }

                String recordPrefix = docId != null && docId.length() > 3 ? docId.substring(0, 3) : null;
                String lookupObject = null;
                if (recordPrefix != null && prefixToObjectNameMap.containsKey(recordPrefix)) {
                    lookupObject = prefixToObjectNameMap.get(recordPrefix);
                }

                if (lookupObject != null) {
                    file.put(lookupObject, docId);
                    insert file;
                } else {
                    System.debug('No matching recordId prefix found in custom metadata.');
                }
            }
        }
        return is308Response;
    } catch(Exception e){
        system.debug('error ===> ' + e.getMessage());
        return false;
    }
}

}