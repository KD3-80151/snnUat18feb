@isTest
public class HTTPUtility_Test {

    @testSetup
    static void setupTestData() {
        Snn_Configuration__c snnConfig = new Snn_Configuration__c(
            Enable_Service_Logger__c = true
        );
        insert snnConfig;
    }

    @isTest
    static void testCreateServiceLogger() {
        HTTPUtility utility = HTTPUtility.getInstance();
        
        String reqBody = '{ "message": "Test Request" }';
        String resBody = '{ "message": "Test Response" }';
        String endPoint = 'https://api.example.com/test';
        String method = 'POST';
        Integer statusCode = 200;
        DateTime startDatetime = DateTime.now();
        DateTime endDateTime = DateTime.now().addSeconds(1);

        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        List<Id> insertedRecordIds = new List<Id> { testAccount.Id };
        
        Test.startTest();
        utility.createServiceLogger(reqBody, resBody, endPoint, method, statusCode, startDatetime, endDateTime, insertedRecordIds);
        Test.stopTest();

        List<Integration_Log__c> logs = [SELECT HTTP_Method__c, Integration_Type__c, Request_Body__c, Response_Body__c, EndPoint__c, 
                                         Response_Status_Code__c, Start_Date_And_Time__c, End_Date_And_Time__c, Reference_Id__c 
                                         FROM Integration_Log__c];
        
        Integration_Log__c log = logs[0];
    }

    @isTest
    static void testServiceLoggerDisabled() {
        Snn_Configuration__c snnConfig = [SELECT Id FROM Snn_Configuration__c LIMIT 1];
        snnConfig.Enable_Service_Logger__c = false;
        update snnConfig;

        HTTPUtility utility = HTTPUtility.getInstance();
        
        Test.startTest();
        utility.createServiceLogger('Test Request', 'Test Response', 'https://api.example.com/test', 'GET', 200, DateTime.now(), DateTime.now(), null);
        Test.stopTest();
        
        Integer logCount = [SELECT count() FROM Integration_Log__c];
    }
}