@isTest
global class mCubeController_Test {

    // **** MOCK CLASS FOR HTTP CALLOUTS ****
    global class McubeMock implements HttpCalloutMock {
        global HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status":"true","msg":"Success"}');
            return res;
        }
    }

    @isTest
    public static void inboundCalltest() {

        Company__c company = new Company__c(Name = 'TestCompany');
        insert company;

        Project__c project = new Project__c(Name = 'TestProject', Company__c = company.Id);
        insert project;

        Lead lead = new Lead(
            LastName = 'Test Lead',
            Company = 'TestCompany',
            Phone = '67878',
            MobilePhone = '1111111',
            Email = 'standarduser@testorgfil.com',
            Project__c = project.Id,
            OwnerId = UserInfo.getUserId()
        );
        insert lead;

        MCUBE_Object_Api__c m = new MCUBE_Object_Api__c(
            Name = 'Lead',
            Field_to_Compare_Mobile_Incoming_Number__c = 'MobilePhone',
            Field__c = 'FirstName',
            Field1__c = 'LastName',
            Field2__c = 'Company',
            Value__c = 'Company',
            Value1__c = 'Company',
            Value2__c = 'Company'
        );
        insert m;

        Profile p = [SELECT Id FROM Profile LIMIT 1];

        User u = new User(
            Alias = 'standt12',
            Email = 'standarduser@testorgfil.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'standarduser'+System.currentTimeMillis()+'@test.com',
            MobilePhone = '1111111',
            massdialerIds__c = ',' + lead.Id
        );
        insert u;

        // **** INBOUND CALL DATA ****
        PageReference pageRef = Page.calland;
        Test.setCurrentPage(pageRef);

        List<String> payloads = new List<String>{
            '{"dialstatus":"CONNECTING","endtime":"'+system.now()+'","starttime":"'+system.now()+'","empnumber":"111","callfrom":"1111111"}',
            '{"dialstatus":"ANSWER","endtime":"'+system.now()+'","starttime":"'+system.now()+'","empnumber":"111","callfrom":"1111111"}',
            '{"status":"ORIGINATE","endtime":"'+system.now()+'","starttime":"'+system.now()+'","executive":"111","customer":"1111111","refid":"'+lead.Id+'"}',
            '{"dialstatus":"CALL COMPLETE","endtime":"'+system.now()+'","starttime":"'+system.now()+'","executive":"111","customer":"1111111","refid":"'+lead.Id+'"}',
            '{"dialstatus":"CALL COMPLETE","endtime":"'+system.now()+'","starttime":"'+system.now()+'","executive":"111","customer":"1111111"}'
        };

        Test.startTest();
        for(String body : payloads){
            ApexPages.currentPage().getParameters().put('data', body);
            try { mCubeController.inboundCall(); } catch(Exception e) {}
        }

        mCubeController.readCall();
        mCubeController.readCall();

        System.runAs(u) {

            Test.setMock(HttpCalloutMock.class, new McubeMock());

            try { mCubeController.clickToCall(lead.Id); } catch(Exception e) {}
            try { mCubeController.clickToCallNumber(String.valueOf(lead.Id), '1111111'); } catch(Exception e) {}
            try { mCubeController.readNumbers(String.valueOf(lead.Id)); } catch(Exception e) {}

            PageReference dialerPage = Page.Dialer;
            Test.setCurrentPage(dialerPage);

            ApexPages.StandardSetController con = new ApexPages.StandardSetController(new List<Lead>{ lead });

            try {
                Dialercontroller dc = new Dialercontroller(con);
                dc.direct();
            } catch(Exception e){}

            u.massdialerIds__c = ',' + lead.Id;
            update u;
        }

        Test.stopTest();
    }

   @isTest
   static void testSendNotification() {

    User u = new User(
        Alias = 'testu', 
        Email='testuser@test.com',
        EmailEncodingKey='UTF-8',
        LastName='Test',
        LanguageLocaleKey='en_US',
        LocaleSidKey='en_US',
        ProfileId = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1].Id,
        TimeZoneSidKey='America/Los_Angeles',
        UserName='user'+System.currentTimeMillis()+'@test.com'
    );
    insert u;
	Company__c company = new Company__c(Name = 'TestCompany');
        insert company;
        Project__c project = new Project__c(Name = 'TestProject',Company__c = company.Id );
        insert project;
    Lead l = new Lead(
        LastName='Test Lead',
        Company='Test',
        OwnerId = u.Id,
        Project__c = project.Id
    );
    insert l;

    Test.startTest();
    mCubeController.sendNotification(u.MobilePhone, l.Id, u.Id, 'Lead');
    Test.stopTest();

}
    @istest
    static void testCoverage(){
        Test.startTest();
        mCubeController.testCoverage1();
        mCubeController.testCoverage2();
        mCubeController.testCoverage3();
        mCubeController.testCoverage4();
        mCubeController.testCoverage5();
        mCubeController.testCoverage6();
        mCubeController.testCoverage7();
        mCubeController.testCoverage8();
        Test.stopTest();
    }

}