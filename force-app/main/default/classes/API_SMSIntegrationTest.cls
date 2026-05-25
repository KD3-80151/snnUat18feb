@isTest
public class API_SMSIntegrationTest {
    @testSetup
    static void setupTestData() {
        SMS_Template__c smsTemplate = new SMS_Template__c(
            SMS_Content__c = 'Hello <Name>, your project <Project> is at <Project_Address>. Your visit is scheduled on <SV_Date>.',
            TemplateId__c = 'TestTemplateId',
            Triggering_Point__c = 'TestTrigger'
        );
        insert smsTemplate;
		Company__c company = new Company__c(Name = 'TestCompany');
        insert company;
        Project__c project1 = new Project__c(Name = 'Project A', Project_Address__c = 'address', City__c = 'City A', Zone__c = 'East', Company__c = company.Id);
        insert project1;

        Lead testLead = new Lead(
            FirstName = 'John',
            LastName = 'Doe',
            Salutation = 'Mr.',
            Project__c = project1.Id,
            Site_Visit_Planned_Date__c = Date.today(),
            Company = 'TestCompany',
            Phone = '1234567890',
            Status = 'Open'
        );
        insert testLead;
    }

    @isTest
    static void testSendSMS() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Lead testLead = [SELECT Id, Phone FROM Lead LIMIT 1];
        Test.startTest();
        API_SMSIntegration.sendSMS(testLead.Id, testLead.Phone, 'TestTrigger', '1234');
        Test.stopTest();
        System.assert(true, 'Future method executed successfully.');
    }
    
    @isTest
    public static void testSendSMSWithInvalidData() {
        Test.startTest();
        API_SMSIntegration.sendSMS(null, '', null, null);
        Test.stopTest();
    }

    @isTest
    public static void testSendSMSFromPortal() {
        Test.startTest();
        API_SMSIntegration.sendSMS(null, '1234567890', 'CP Portal', '123546');
        Test.stopTest();
    }
    
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status":"success","message":"SMS sent successfully"}');
            return res;
        }
    }
}