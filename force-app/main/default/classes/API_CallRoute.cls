@RestResource(urlMapping='/CallRoute')
global without sharing class API_CallRoute {

    global class ResponseWrapper {
        public String Status;
        public String LeadId;
        public String LeadOwner;
        public String LeadOwnerNumber;
        public String Message;

        public ResponseWrapper(String status, String message) {
            this.Status = status;
            this.Message = message;
        }

        public ResponseWrapper(String status, Id leadId, String leadOwner, String leadOwnerNumber) {
            this.Status = status;
            this.LeadId = leadId;
            this.LeadOwner = leadOwner;
            this.LeadOwnerNumber = leadOwnerNumber;
        }
    }

    @HttpPost
    global static void getLeadOwner() {
        DateTime currentDateTime = System.now();
        RestRequest req            = RestContext.request;
        Blob body                  = req.requestBody;
        String requestString       = body.toString();
        ResponseWrapper responseWrap;
        Integer statusCode;
        Id matchedLeadId;

        try {
            Map<String, Object> requestWrap = (Map<String, Object>) JSON.deserializeUntyped(requestString);
            String phone = requestWrap.containsKey('Phone') ? (String) requestWrap.get('Phone') : null;

            if (String.isBlank(phone)) {
                responseWrap = new ResponseWrapper('Failed', 'Phone is a mandatory field.');
                statusCode = 400;
            } else {
                List<Lead> matchedLeads = [
                    SELECT Id, OwnerId
                    FROM Lead
                    WHERE (Phone = :phone OR Alternate_Phone__c = :phone) AND IsConverted = false
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                ];

                if (matchedLeads.isEmpty()) {
                    responseWrap = new ResponseWrapper('Failed', 'Lead not found.');
                    statusCode = 404;
                } else {
                    Lead matchedLead = matchedLeads[0];
                    matchedLeadId = matchedLead.Id;

                    if (matchedLead.OwnerId.getSObjectType() != User.SObjectType) {
                        responseWrap = new ResponseWrapper('Failed', 'Lead is currently assigned to a queue, not a user.');
                        statusCode = 404;
                    } else {
                        List<User> ownerUsers = [SELECT Id, Name, MobilePhone FROM User WHERE Id = :matchedLead.OwnerId LIMIT 1];
                        User ownerUser = ownerUsers.isEmpty() ? null : ownerUsers[0];

                        responseWrap = new ResponseWrapper('Success', matchedLead.Id, ownerUser?.Name, ownerUser?.MobilePhone);
                        statusCode = 200;
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error in API_CallRoute ===> ' + e.getMessage());
            System.debug('Line ===> ' + e.getLineNumber());
            responseWrap = new ResponseWrapper('Failed', 'Error: ' + e.getMessage());
            statusCode = 500;
        }

        String responseBody = JSON.serialize(responseWrap, true);
        RestContext.response.statusCode = statusCode;
        RestContext.response.responseBody = Blob.valueOf(responseBody);

        List<Id> loggedIds = matchedLeadId != null ? new List<Id>{ matchedLeadId } : null;
        HTTPUtility.getInstance().createServiceLogger(requestString, responseBody, '/CallRoute', 'POST', statusCode, currentDateTime, System.now(), loggedIds);
    }
}
