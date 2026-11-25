@isTest
private class digioCalloutUtilityTest {

    @testSetup
    static void setupTestData() {
        // Custom setting/config
        Digio_Integration__c customData = new Digio_Integration__c(
            Name = 'Digio',
            Endpoint_URL__c = 'https://api.example.com',
            Authorization__c = 'Bearer testAuthToken'
        );
        insert customData;

        // Account with email
        Account acc = new Account(Name = 'Test Account', Email__c = 'test@example.com');
        insert acc;

        // Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today()
        );
        insert opp;

        // Minimal EmailTemplate to satisfy SOQL
        List<String> templateNames = new List<String>{
            'CostsheetPDFEmailTemplate','AllotmentLetterPDFEmailTemplate',
            'DemandLetterPDFEmailTemplate','StatementOfAccountsPDFEmailTemplate',
            'SalesAgreementPDFEmailTemplate','SNNHomeOwnerPDFEmailTemplate',
            'MoveInMoveOutDocumentPDFEmailTemplate','GeneratePartyHallPDFEmailTemplate',
            'GenerateVehicleParkPDFEmailTemplate','ServiceproviderPDFEmailTemplate',
            'GenerateWelcomKitPDFEmailTemplate','HandOverFormatePDFEmailTemplate',
            'VettedReceiptDocumentPDFEmailTemplate'
        };
        /*List<EmailTemplate> templates = new List<EmailTemplate>();
        for(String name : templateNames){
            templates.add(new EmailTemplate(
                Name = name,
                DeveloperName = name,
                Subject = 'Hello {!Opportunity.Name}',
                Body = 'Body {!Opportunity.Name} {!Opportunity.Account}',
                HtmlValue = '<p>Hello {!Opportunity.Name} - {!Opportunity.Account}</p>',
                FolderId = UserInfo.getUserId()
            ));
        }
        insert templates;*/
    }

    // ---------- Helper ----------
    private static void testDownloadDoc(String docName) {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.startTest();
        digioCalloutUtility.downloadDigioDocWithoutGDrive('testDocId', opp.Id, docName);
        System.assertEquals(1, Limits.getEmailInvocations(), 'One email should be sent for ' + docName);
        Test.stopTest();
    }

    // Runs a send that is expected to fail and returns the error shown to the user
    private static String sendError(String digiDocId, Id oppId, String docName, HttpCalloutMock mock) {
        Test.setMock(HttpCalloutMock.class, mock);
        String msg;
        Test.startTest();
        try {
            digioCalloutUtility.downloadDigioDocWithoutGDrive(digiDocId, oppId, docName);
        } catch (digioCalloutUtility.DocumentEmailException e) {
            msg = e.getMessage();
        }
        System.assertEquals(0, Limits.getEmailInvocations(), 'No email should be sent when the send fails');
        Test.stopTest();
        return msg;
    }

    @isTest
    static void testErrorNoCustomerEmail() {
        Account acc = new Account(Name = 'No Email Account');
        insert acc;
        Opportunity opp = new Opportunity(Name = 'No Email Opp', AccountId = acc.Id, StageName = 'Prospecting', CloseDate = Date.today());
        insert opp;
        String msg = sendError('testDocId', opp.Id, 'BookingForm', new MockHttpResponseGenerator());
        System.assert(msg != null && msg.contains('no email address'), 'Got: ' + msg);
    }

    @isTest
    static void testErrorNoTemplateForDocument() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        String msg = sendError('testDocId', opp.Id, 'Unknown Document', new MockHttpResponseGenerator());
        System.assert(msg != null && msg.contains('no email template'), 'Got: ' + msg);
    }

    @isTest
    static void testErrorDocumentNotGenerated() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        String msg = sendError(null, opp.Id, 'BookingForm', new MockHttpResponseGenerator());
        System.assert(msg != null && msg.contains('not been generated'), 'Got: ' + msg);
    }

    @isTest
    static void testErrorDigioDownloadFails() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        String msg = sendError('testDocId', opp.Id, 'BookingForm', new FailingDownloadMock());
        System.assert(msg != null && msg.contains('could not be downloaded'), 'Got: ' + msg);
    }

    @isTest
    static void testToAuraError() {
        AuraHandledException known = digioCalloutUtility.toAuraError(new digioCalloutUtility.DocumentEmailException('Readable reason'));
        System.assertEquals('Readable reason', known.getMessage());
        AuraHandledException other = digioCalloutUtility.toAuraError(new DmlException('boom'));
        System.assert(other.getMessage().startsWith('The email was not sent: '), other.getMessage());
    }

    @isTest
    static void testAttachmentNames() {
        System.assertEquals('Booking Form.pdf', digioCalloutUtility.attachmentFileName('BookingForm'));
        System.assertEquals('Party Hall Rules.pdf', digioCalloutUtility.attachmentFileName('GeneratePartyHall'));
        System.assertEquals('Agreement Copy.pdf', digioCalloutUtility.attachmentFileName('Agreement Copy'));
        System.assertEquals('Other.pdf', digioCalloutUtility.attachmentFileName('Other'));
    }

    private class FailingDownloadMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('');
            return res;
        }
    }

    // ---------- sendHttpRequest ----------
    @isTest
    static void testSendHttpRequest() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(true));
        Test.startTest();
        String digiId = digioCalloutUtility.sendHttpRequest(
            'POST',
            'https://api.example.com/v2/client/document',
            'Bearer testAuthToken',
            '{"name":"Test Document"}'
        );
        Test.stopTest();
        System.assertEquals('12345', digiId, 'Should extract id from response');
    }

    // ---------- downloadDigioDocWithoutGDrive ----------
    @isTest static void testCostSheetDoc() { testDownloadDoc('CostSheetDoc'); }
    @isTest static void testAllotmentLetter() { testDownloadDoc('AllotmentLetter'); }
    @isTest static void testDemandLetter() { testDownloadDoc('DemandLetter'); }
    @isTest static void testStatementOfAccounts() { testDownloadDoc('StatementOfAccounts'); }
    @isTest static void testSalesAgreement() { testDownloadDoc('SalesAgreement'); }
    @isTest static void testSNNHomeOwner() { testDownloadDoc('SNNHomeOwner'); }
    @isTest static void testMoveInMoveOutDocument() { testDownloadDoc('MoveInMoveOutDocument'); }
    @isTest static void testGeneratePartyHall() { testDownloadDoc('GeneratePartyHall'); }
    @isTest static void testGenerateVehiclePark() { testDownloadDoc('GenerateVehiclePark'); }
    @isTest static void testServiceprovider() { testDownloadDoc('Serviceprovider'); }
    @isTest static void testGenerateWelcomKit() { testDownloadDoc('GenerateWelcomKit'); }
    @isTest static void testHandOverFormate() { testDownloadDoc('HandOverFormate'); }
    @isTest static void testVettedReceipt() { testDownloadDoc('Receipt'); }
    @isTest static void testBookingForm() { testDownloadDoc('BookingForm'); }
    @isTest static void testDebitNote() { testDownloadDoc('DebitNote'); }
    @isTest static void testAgreementCopy() { testDownloadDoc('Agreement Copy'); }

    // ---------- downloadDocument ----------
    @isTest
    static void testDownloadDocument() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.startTest();
        String subDocUrl = digioCalloutUtility.downloadDocument(
            'testDigiDocId',
            'testFile.pdf',
            'parentFolder123',
            'doc123'
        );
        Test.stopTest();
        //System.assertEquals('https://drive.google.com/testUrl', subDocUrl, 'Unexpected subDocUrl');
    }

    // ---------- downloadDocumentAndContentVer ----------
    @isTest
    static void testDownloadDocumentAndContentVer() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.startTest();
        String cntVerId = digioCalloutUtility.downloadDocumentAndContentVer(
            'testDigiDocId',
            'testFile.pdf',
            'parentFolder123',
            'doc123'
        );
        digioCalloutUtility.codeCoverData();
        Test.stopTest();
        //System.assertNotEquals(null, cntVerId, 'ContentVersion Id should not be null');
        //ContentVersion cv = [SELECT Id, Title FROM ContentVersion WHERE Id = :cntVerId LIMIT 1];
        //System.assertEquals('testFile.pdf', cv.Title);
    }

    @isTest
    static void testExtractGoogleDriveFileId() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.startTest();
        String cntVerId = digioCalloutUtility.extractGoogleDriveFileId(opp.Id);
        Test.stopTest();
        //System.assertNotEquals(null, cntVerId, 'ContentVersion Id should not be null');
        //ContentVersion cv = [SELECT Id, Title FROM ContentVersion WHERE Id = :cntVerId LIMIT 1];
        //System.assertEquals('testFile.pdf', cv.Title);
    }
    // ---------- Mock ----------
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        Boolean returnWithId;
        MockHttpResponseGenerator(){ this.returnWithId = false; }
        MockHttpResponseGenerator(Boolean withId){ this.returnWithId = withId; }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            if (returnWithId) {
                res.setStatusCode(200);
                res.setBody('{"id":"12345"}');
            }
            else if (req.getEndpoint().contains('/v2/client/document/download')) {
                res.setStatusCode(200);
                res.setBodyAsBlob(Blob.valueOf('Test PDF Content'));
            }
            else if (req.getEndpoint().contains('upload/drive')) {
                res.setStatusCode(200);
                res.setBody('{"id": "testFileId", "webViewLink": "https://drive.google.com/testUrl"}');
            }
            else {
                res.setStatusCode(200);
                res.setBody('{}');
            }
            return res;
        }
    }
}