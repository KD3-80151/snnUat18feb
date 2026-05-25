public without sharing class ProjectUpdateHandler {
    
    public static String REFRESH_TOKEN;
    public static String CLIENT_ID;
    public static String CLIENT_SECRET;
    public static String REDIRECT_URI;

    // Get access token from Google using the refresh token
    public static String getAccessToken() {
        // Fetch the Google Drive Integration configuration from custom settings
        GoogleDriveIntegration__c googleDrive = GoogleDriveIntegration__c.getValues('GDrive');
        if (googleDrive != null) {
            REFRESH_TOKEN = googleDrive.Refresh_Token__c != null ? googleDrive.Refresh_Token__c : null;
            CLIENT_ID = googleDrive.Client_Id__c != null ? googleDrive.Client_Id__c : null;
            CLIENT_SECRET = googleDrive.Client_Secret__c != null ? googleDrive.Client_Secret__c : null;
            REDIRECT_URI = googleDrive.Redirect_URI__c != null ? googleDrive.Redirect_URI__c : null;
        }

        
        System.debug('Refresh Token: ' + REFRESH_TOKEN);
        System.debug('Client ID: ' + CLIENT_ID);
        System.debug('Client Secret: ' + CLIENT_SECRET);
        System.debug('Redirect URI: ' + REDIRECT_URI);

        HttpRequest req = new HttpRequest(); 
        req.setEndpoint('https://www.googleapis.com/oauth2/v4/token');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        String messageBody = 'client_id=' + CLIENT_ID + '&client_secret=' + CLIENT_SECRET + '&refresh_token=' + REFRESH_TOKEN + '&redirect_uri=' + REDIRECT_URI + '&grant_type=refresh_token';
        req.setHeader('Content-length', String.valueOf(messageBody.length()));
        req.setBody(messageBody);
        req.setTimeout(60 * 1000); // 60 seconds
        
        // Send request to Google API
        HTTP http = new HTTP();
        HttpResponse res = http.send(req);
        String responseBody = res.getBody();

        System.debug('Google API Response Status Code: ' + res.getStatusCode());
        System.debug('Google API Response Body: ' + responseBody);

        if (res.getStatusCode() == 200) {
            // Parse and extract access token
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            String accessToken = (String) responseMap.get('access_token');
            return accessToken;
        } else {
            System.debug('Error: ' + res.getBody());
            return null;
        }
    }
    
    @Future(callout=true)
    public static void updateProjectUpdateFolderId(String projectId) {
        
        List<Project_Updates__c> projectUpdates = [SELECT Id, Name, Project__c FROM Project_Updates__c WHERE Project__c = :projectId ORDER BY CreatedDate DESC LIMIT 1];
    
        if (projectUpdates.isEmpty()) {
            System.debug('No Project Update found for Project ID: ' + projectId);
            return;
        }
    
        Project_Updates__c newUpdate = projectUpdates[0];
    
        List<Project__c> projects = [SELECT Id, FolderId__c FROM Project__c WHERE Id = :projectId LIMIT 1];
    
        if (projects.isEmpty()) {
            System.debug('No Project found for ID: ' + projectId);
            return;
        }
    
        String projectFolderId = projects[0].FolderId__c;
    
        if (String.isEmpty(projectFolderId)) {
            System.debug('No Folder ID found for Project ID: ' + projectId);
            return;
        }
    
        String projectUpdateName = newUpdate.Name;
        String subfolderName = projectUpdateName + ' - ' + newUpdate.Id;
    
        String subfolderId = createSubfolderInDrive(projectFolderId, subfolderName);
    
        if (subfolderId != null) {
            newUpdate.FolderId__c = subfolderId;
            update newUpdate;
            System.debug('Subfolder ID created: ' + subfolderId);
        } else {
            System.debug('Failed to create subfolder for Project Update: ' + newUpdate.Name);
        }
    }

    private static String createSubfolderInDrive(String parentFolderId, String subfolderName) {
        try {
            String accessToken = getAccessToken();
            if (accessToken == null) {
                System.debug('Access Token is null');
                return null;
            }

            String requestBody = '{"name": "' + subfolderName + '", "mimeType": "application/vnd.google-apps.folder", "parents": ["' + parentFolderId + '"]}';

            String url = 'https://www.googleapis.com/drive/v3/files';
            
            System.debug('Google Drive API URL: ' + url);
            System.debug('Request Body: ' + requestBody);
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(url);
            req.setMethod('POST');
            req.setHeader('Authorization', 'Bearer ' + accessToken);
            req.setHeader('Content-Type', 'application/json');
            req.setBody(requestBody);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            System.debug('Google Drive API Response Status Code: ' + res.getStatusCode());
            System.debug('Google Drive API Response Body: ' + res.getBody());

            if (res.getStatusCode() == 200) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                return (String) responseMap.get('id');
            } else {
                System.debug('Error: ' + res.getStatusCode() + ' - ' + res.getBody());
            }
        } catch (Exception e) {
            System.debug('Error while creating subfolder: ' + e.getMessage());
        }

        return null;
    }
}