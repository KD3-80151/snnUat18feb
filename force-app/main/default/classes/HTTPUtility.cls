public with sharing class HTTPUtility 
{

    static final String NO_RESPONSE = 'NO_RESPONSE';
    static final String HTTP_ERROR = 'ERROR WHILE MAKING REQUEST';
    static Snn_Configuration__c snnObj;

    static HttpUtility httpUtilityInstance;

    public HttpUtility() {
    }

    public static HttpUtility getInstance() {
        if (httpUtilityInstance == null) {
            httpUtilityInstance = new HttpUtility();
            snnObj = Snn_Configuration__c.getInstance();
        }
        return httpUtilityInstance;
    }

    public void createServiceLogger(String reqBody, String resBody, String endPoint, String method, Integer statusCode, DateTime startDatetime, DateTime endDateTime, List<Id> insertedRecordIds) {
        try {
            System.debug('whatsapp Logger..');
            System.debug('snnObj==>'+snnObj);
            if (snnObj != null && snnObj.Enable_Service_Logger__c) {
                Integration_Log__c logger = new Integration_Log__c();
                logger.HTTP_Method__c = method;
                logger.Integration_Type__c = 'SERVICE';
                logger.Request_Body__c = reqBody;
                logger.Response_Body__c = resBody;
                logger.EndPoint__c = endPoint;
                logger.Response_Status_Code__c = statusCode;
                logger.Start_Date_And_Time__c = startDatetime;
                logger.End_Date_And_Time__c = endDateTime;
                if (insertedRecordIds != null && !insertedRecordIds.isEmpty()) {
                    logger.Reference_Id__c = String.join(insertedRecordIds, ',');
                }
                insert logger;
                System.debug('logger.Id -- ' + logger.Id);
            }
        } catch (DMLException e) {
            System.debug('--- e-message ' + e.getMessage());
            System.debug('--- e-line-no ' + e.getLineNumber());
        }
    }
}