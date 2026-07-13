@IsTest
public class QueueableToGenerateWelcomeLetterTest {

    private class MultiCalloutMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);

            String ep = req.getEndpoint() == null ? '' : req.getEndpoint().toLowerCase();

            if (ep.contains('token')) {
                res.setBody('{"access_token":"TEST_ACCESS_TOKEN","token_type":"Bearer","expires_in":3600}');
                return res;
            }

            if (ep.contains('googleapis.com/drive')) {
                res.setBody('{"id":"TEST_FOLDER_ID"}');
                return res;
            }
            
            if (ep.contains('digio') || ep.contains('create_sign_request')) {
                res.setBody('{"id":"TEST_DIGIO_DOC_ID"}');
                return res;
            }

            res.setBody('{"status":"ok"}');
            return res;
        }
    }

    @testSetup
    static void setupData() {
        Account acc = new Account(Name = 'Test Account');
        try { acc.put('Email__c', 'test@example.com'); } catch (Exception e) {}
        try { acc.put('Salutation__c', 'Mr'); } catch (Exception e) {}
        insert acc;

        Contact con = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = acc.Id
        );
        try { con.put('FolderId__c', 'EXISTING_CONTACT_FOLDER'); } catch (Exception e) {}
        insert con;

        Company__c comp = new Company__c(Name = 'Test Company');
        insert comp;

        Project__c project = new Project__c(
            Name = 'Test Project',
            Company__c = comp.Id
        );
        try { project.put('Account_Name__c', '1234567890'); } catch (Exception e) {}
        try { project.put('Project_Address__c', '123 Street'); } catch (Exception e) {}
        try { project.put('Bank_Name__c', 'Bank of Test'); } catch (Exception e) {}
        try { project.put('IFSC_Code__c', 'TEST0001'); } catch (Exception e) {}
        try { project.put('Bank_Address__c', 'Bank Address'); } catch (Exception e) {}
        try { project.put('Account_Number__c', '0011223344'); } catch (Exception e) {}
        insert project;

        Tower__c tower = new Tower__c(Name = 'Tower A');
        insert tower;

        Floor__c floor = new Floor__c();
        try { floor.put('Tower__c', tower.Id); } catch (Exception e) {}
        insert floor;

        Unit__c unit = new Unit__c();
        try { unit.put('Unit_Name__c', 'Unit 101'); } catch (Exception e) {}
        try { unit.put('Floor__c', floor.Id); } catch (Exception e) {}
        insert unit;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = System.today().addDays(10)
        );
        try { opp.put('Email__c', 'test.opportunity@example.com'); } catch (Exception e) {}
        try { opp.put('Project__c', project.Id); } catch (Exception e) {}
        try { opp.put('Unit__c', unit.Id); } catch (Exception e) {}
        try { opp.put('Document_Id__c', 'EXISTING_OPP_FOLDER'); } catch (Exception e) {}
        insert opp;

        Applicant__c applicant = new Applicant__c();
        try { applicant.put('Account__c', acc.Id); } catch (Exception e) {}
        try { applicant.put('Opportunity__c', opp.Id); } catch (Exception e) {}
        insert applicant;

        Document__c rootDoc = new Document__c();
        rootDoc.Name = 'Root Folder';
        try { rootDoc.put('Opportunity__c', opp.Id); } catch (Exception e) {}
        try { rootDoc.put('Document_Id__c', 'ROOT_FOLDER_ID'); } catch (Exception e) {}
        insert rootDoc;

        Digio_Integration__c digi = new Digio_Integration__c(Name = 'Digio');
        try { digi.put('Authorization__c', 'Bearer xyz123'); } catch (Exception e) {}
        try { digi.put('Endpoint_URL__c', 'https://api.digio.in'); } catch (Exception e) {}
        try { digi.put('Welcome_Letter__c', 'TEMPLATE_KEY'); } catch (Exception e) {}
        insert digi;

        ContentVersion cv = new ContentVersion(
            Title = 'Dummy',
            PathOnClient = 'Dummy.pdf',
            VersionData = Blob.valueOf('PDF'),
            FirstPublishLocationId = opp.Id
        );
        insert cv;
    }

    @IsTest
    static void test_execute_nullOpportunityId() {
        Test.startTest();
        System.enqueueJob(new QueueableToGenerateWelcomeLetter(null));
        Test.stopTest();
    }

    @IsTest
    static void test_generateWelcomeLetterDocument_blankRecordId() {
        QueueableToGenerateWelcomeLetter.docwrpperClass res =
            QueueableToGenerateWelcomeLetter.generateWelcomeLetterDocument('');
        System.debug('res => ' + res);
    }

    @IsTest
    static void test_execute_validOpportunity_withMocks() {
        Test.setMock(HttpCalloutMock.class, new MultiCalloutMock());

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        System.enqueueJob(new QueueableToGenerateWelcomeLetter(opp.Id));
        Test.stopTest();
    }
}