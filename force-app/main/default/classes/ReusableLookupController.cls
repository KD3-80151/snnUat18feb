public withOut sharing class ReusableLookupController {
    @AuraEnabled
    public static List<ResultWrapper> fetchRecords(SearchWrapper inputWrapper) {
        try {
            if(inputWrapper != null){
                String fieldsToQuery = 'SELECT Id, ';
                if(string.isNotBlank(inputWrapper.fieldApiName)){
                    fieldsToQuery = fieldsToQuery + inputWrapper.fieldApiName;
                }
                if(string.isNotBlank(inputWrapper.otherFieldApiName)){
                    fieldsToQuery = fieldsToQuery + ', ' + inputWrapper.otherFieldApiName;
                }
                String query = fieldsToQuery + ' FROM '+ inputWrapper.objectApiName;
                System.debug('query1 ==> ' + query);
                String filterCriteria = inputWrapper.fieldApiName + ' LIKE ' + '\'' + String.escapeSingleQuotes(inputWrapper.searchString.trim()) + '%\' LIMIT 10';
                System.debug('filterCriteria ===> ' + filterCriteria);
                // if (inputWrapper.objectApiName == 'Unit__c' && inputWrapper.fieldApiName == 'Unit_Name__c') {
                //     filterCriteria = 'Status__c != \'Sold\' AND ' + filterCriteria;
                // }
                if(String.isNotBlank(inputWrapper.selectedRecordId)) {
                    query += ' WHERE Id = \''+ inputWrapper.selectedRecordId + '\'';
                }else if(String.isNotBlank(inputWrapper.parentFieldApiName) && String.isNotBlank(inputWrapper.parentRecordId)){
                    query += ' WHERE '+ inputWrapper.parentFieldApiName+ ' = \''+ String.escapeSingleQuotes(inputWrapper.parentRecordId) + '\'';
                    if(String.isNotBlank(inputWrapper.firstFieldFilterApiName) && String.isNotBlank(inputWrapper.firstFieldFilterValue)){
                        query += ' AND ' + getExclusionClause(inputWrapper.firstFieldFilterApiName, inputWrapper.firstFieldFilterValue);
                    }
                    query += ' AND ' + filterCriteria;
                }else if((String.isNotBlank(inputWrapper.firstFieldFilterApiName)) || (String.isNotBlank(inputWrapper.secondFieldFilterApiName)) || (String.isNotBlank(inputWrapper.thirdFieldFilterApiName))){
                    if((String.isNotBlank(inputWrapper.firstFieldFilterValue)) || (String.isNotBlank(inputWrapper.secondFieldFilterValue)) || (String.isNotBlank(inputWrapper.thirdFieldFilterValue))){
                        query += ' WHERE ';
                    }
                    if((String.isNotBlank(inputWrapper.firstFieldFilterApiName)) && (String.isNotBlank(inputWrapper.firstFieldFilterValue))){
                        query += getExclusionClause(inputWrapper.firstFieldFilterApiName, inputWrapper.firstFieldFilterValue);
                    }
                    if((String.isNotBlank(inputWrapper.secondFieldFilterApiName)) && (String.isNotBlank(inputWrapper.secondFieldFilterValue))){
                        query += inputWrapper.secondFieldFilterApiName+ ' = \''+ inputWrapper.secondFieldFilterValue + '\'';
                    }
                    if((String.isNotBlank(inputWrapper.thirdFieldFilterApiName)) && (String.isNotBlank(inputWrapper.thirdFieldFilterValue))){
                        query += ' AND '+ inputWrapper.thirdFieldFilterApiName+ ' = \''+ inputWrapper.thirdFieldFilterValue + '\'';
                    }
                    if((String.isNotBlank(inputWrapper.firstFieldFilterValue)) || (String.isNotBlank(inputWrapper.secondFieldFilterValue)) || (String.isNotBlank(inputWrapper.thirdFieldFilterValue))){
                        query += ' AND ' + filterCriteria;
                    }
                }else {
                    query += ' WHERE '+ filterCriteria;
                }
                System.debug('filterCriteria ===> ' + filterCriteria);
                System.debug('query ===> ' + query);
                List<ResultWrapper> returnWrapperList = new List<ResultWrapper>();
                for(SObject s : Database.query(query)) {
                    ResultWrapper wrap = new ResultWrapper();
                    // wrap.mainField = (String)s.get(inputWrapper.fieldApiName);
                    // wrap.subField = (String)s.get(inputWrapper.otherFieldApiName);
                    wrap.mainField = getFieldValue(s, inputWrapper.fieldApiName);
                    wrap.subField  = getFieldValue(s, inputWrapper.otherFieldApiName);
                    wrap.id = (String)s.get('id');
                    returnWrapperList.add(wrap);
                }
                System.debug('returnWrapperList ===> ' + returnWrapperList);
                return returnWrapperList;
            }
            return null;
        } catch (Exception e) {
            system.debug('Error Message: ' + e.getMessage() + ' at Line Number: ' + e.getLineNumber());
            return null;
        }
    }

    public class ResultWrapper{
        @AuraEnabled public String mainField{get;set;}
        @AuraEnabled public String subField{get;set;}
        @AuraEnabled public String id{get;set;}
    }

    public class SearchWrapper {
        @AuraEnabled public String objectApiName{get;set;}
        @AuraEnabled public String fieldApiName{get;set;}
        @AuraEnabled public String otherFieldApiName{get;set;}
        @AuraEnabled public String searchString{get;set;}
        @AuraEnabled public String selectedRecordId{get;set;}
        @AuraEnabled public String parentRecordId{get;set;}
        @AuraEnabled public String parentFieldApiName{get;set;}
        @AuraEnabled public String firstFieldFilterApiName{get;set;}
        @AuraEnabled public String firstFieldFilterValue{get;set;}
        @AuraEnabled public String secondFieldFilterApiName{get;set;}
        @AuraEnabled public String secondFieldFilterValue{get;set;}
        @AuraEnabled public String thirdFieldFilterApiName{get;set;}
        @AuraEnabled public String thirdFieldFilterValue{get;set;}
    }
    // comma separated values are excluded together, e.g. "Sold,Management Blocked"
    private static String getExclusionClause(String fieldApiName, String fieldValue) {
        if (!fieldValue.contains(',')) {
            return fieldApiName + ' != \'' + fieldValue + '\'';
        }
        List<String> excludedValues = new List<String>();
        for (String val : fieldValue.split(',')) {
            if (String.isNotBlank(val)) {
                excludedValues.add('\'' + String.escapeSingleQuotes(val.trim()) + '\'');
            }
        }
        return fieldApiName + ' NOT IN (' + String.join(excludedValues, ',') + ')';
    }
    // helper to handle relationship fields (like Account.Name)
  private static String getFieldValue(SObject record, String fieldPath) {
    if (String.isBlank(fieldPath)) return null;

    if (fieldPath.contains('.')) {
        // split relationship path
        List<String> parts = fieldPath.split('\\.');
        SObject parentObj = record.getSObject(parts[0]);
        if (parentObj != null) {
            return (String)parentObj.get(parts[1]);
        }
        return null;
    } else {
        return (String)record.get(fieldPath);
    }
}

}