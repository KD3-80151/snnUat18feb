/**
* @author Vamsi Krishna
* @date 24-05-2024
* @lastModified 02-07-2024(Vamsi Krishna)
* @description This class handles the uploading of Lead Records from a CSV file.
*/

public class LeadDetailsCSVUploadController {
    
    @AuraEnabled
    public static Boolean checkProfile() {
        try {
            String ownerId = UserInfo.getUserId();
            List<User> userRecord = [
                SELECT Id, Name FROM User  WHERE Id = :ownerId ];
            if (!userRecord.isEmpty()) {
                return true;
            } else {
                return false;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    public class CustomValidationException extends Exception {}

    public class UploadResult {
        @AuraEnabled
        public Lead leadrecord;
        @AuraEnabled
        public String status;         
    }
    
    @AuraEnabled
    public static String uploadLeadRecords(String fileData, List<String> fields){  
        System.debug('fileData==>'+fileData);
        
        System.debug('fields===>'+fields);
        String message = 'Success';
        try{
            String finalResult  = saveLeads(fileData,fields);
            return finalResult;
        }catch(Exception e){
            System.debug('Exception @ ' + e.getLineNumber());
            throw new CustomValidationException(e.getMessage());
        }
        
    }
    
    private static String saveLeads(String fileData, List<String> fields){
        try{
            System.debug('fileData==>'+fileData);
            system.debug('fields ===> ' + fields);
            
            String[] fileLines = fileData.split('\n');
            List<Lead> LeadsToInsert = new List<Lead>();
            
            
            
            for (Integer i = 0; i < fileLines.size(); i++) {
                String[] inputValues = fileLines[i].split(',');
                System.debug('inputValues ===> ' + inputValues);
                
                UploadResult result = createLead(inputValues, fields);
                system.debug('result ===> ' + result);
                
                if(result.status == 'Success'){
                    System.debug('result.leadrecord==>'+result.leadrecord);
                    LeadsToInsert.add(result.leadrecord);
                    
                }else{
                    return result.status ;
                }
            }
            if (!LeadsToInsert.isEmpty()) {
                insert LeadsToInsert;
            }
            return 'Success';
        }catch(Exception e){
            String error = e.getMessage();
            system.debug('Error ===> ' + e.getMessage());
            System.debug(e.getLineNumber());
            return error;
            
        }
    }
    
    
    
    
    private static UploadResult createLead(String[] inputValues, List<String> fields) {
        Lead li = new Lead();
        System.debug('inputValues===>'+inputValues);
        System.debug('fields===>'+fields);
        System.debug('fields.size()===>'+fields.size());
        try{
			List<Project__c> projectList = [SELECT Id, Name FROM Project__c];
            Map<String, String> projectXidMap = new Map<String, String>();
            if(!projectList.isEmpty()){
                for(Project__c proj : projectList){
                    if(!projectXidMap.containsKey(proj.Name)){
                        projectXidMap.put(proj.Name,proj.Id);
                    }
                }
            }
            for (Integer k = 0; k < fields.size(); k++) {
                if(k < inputValues.size()){
                    System.debug('inputValues[k].length()==>'+inputValues[k].length());
                    String value = inputValues[k].length() > 255 ? inputValues[k].substring(0, 254) : inputValues[k];
                    System.debug('value==>'+value);
                    if (fields[k] == 'Name' && String.isNotBlank(value)) {
                        li.LastName = value;
                    } else if (fields[k] == 'Email' && String.isNotBlank(value)) {
                        li.Email = value;
                    } else if (fields[k] == 'Phone' && String.isNotBlank(value) && value.length() >= 10) {
                        li.Phone = '+91' + value.substring(value.length() - 10);
                    } else if (fields[k] == 'Project' && String.isNotBlank(value)) {
                        li.Project__c = projectXidMap.get(value);
                    } else if (fields[k] == 'Lead_Source' && String.isNotBlank(value)) {
                        li.LeadSource = value;
                    } else if (fields[k] == 'Lead_Sub_Source' && String.isNotBlank(value)) {
                        li.Lead_Sub_Source__c = value;
                    }
                    li.Lead_Type__c = 'Channel Partner';
                }else{
                    System.debug('inputValues['+k+'] is not provided.');
                }
            }
            li.OwnerId = UserInfo.getUserId();
            li.Company = li.LastName;
            UploadResult result = validateLead(li);
            return result;

        }catch(Exception e){
            System.debug(e.getMessage());
            System.debug(e.getLineNumber());
            
            // Return an instance of UploadResult indicating an error
        UploadResult errorResult = new UploadResult();
        
        errorResult.status = e.getMessage();
        
        return errorResult;
        }
        
    }
    
    private static UploadResult validateLead(Lead li) {
        
        UploadResult wrap = new UploadResult();
        String message;
        if (String.isBlank(li.LastName)) {
            message = 'Mandatory field LastName missing for lead with name '+ li.LastName;
            wrap.status = message;
            wrap.leadrecord = null;
            return wrap;
        }
        if (String.isBlank(li.Email) || String.isBlank(li.Phone) ) {
            message =  'Mandatory fields Email or Phone missing for lead with name '+ li.LastName;
            wrap.status = message;
            wrap.leadrecord = null;
            return wrap;
        }
        if (String.isBlank(li.Project__c)) {
            message = 'Mandatory field project missing for lead with name '+ li.LastName;
            wrap.status = message;
            wrap.leadrecord = null;
            return wrap;
        }
        wrap.status = 'Success';
        wrap.leadrecord = li;
        return wrap;    
    }
}