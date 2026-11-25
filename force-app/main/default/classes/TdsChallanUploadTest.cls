/**
 * Customer Portal Receipts tab (client, Nov 2026): only Tax Invoice receipts with their receipt number,
 * TDS Challan upload per booking into "TDS Uploaded Docs", and the owner notification.
 */
@isTest
private class TdsChallanUploadTest {

    private static final String HASH = 'tdsChallanTestHash';
    private static final String OTHER_HASH = 'otherCustomerHash';

    private class DriveMock implements HttpCalloutMock {
        public Integer folderCalls = 0;
        public Integer uploadCalls = 0;
        public Boolean failUpload = false;
        public HttpResponse respond(HttpRequest request) {
            HttpResponse res = new HttpResponse();
            String ep = request.getEndpoint();
            if (ep.contains('oauth2')) {
                res.setStatusCode(200);
                res.setBody('{"access_token": "mockToken", "expires_in": 3600}');
            } else if (ep.contains('uploadType=resumable')) {
                res.setStatusCode(200);
                res.setHeader('Location', 'https://mock-upload-location');
            } else if (ep.contains('mock-upload-location')) {
                uploadCalls++;
                res.setStatusCode(failUpload ? 500 : 200);
                res.setBody(failUpload ? '{"error": "boom"}' : '{"id": "ChallanFileId"}');
            } else if (ep.contains('/drive/v3/files')) {
                folderCalls++;
                res.setStatusCode(200);
                res.setBody('{"id": "TdsFolderId"}');
            } else {
                res.setStatusCode(200);
                res.setBody('{}');
            }
            return res;
        }
    }

    @testSetup
    static void setup() {
        Account customer = new Account(Name = 'Challan Customer');
        Account other = new Account(Name = 'Other Customer');
        insert new List<Account>{ customer, other };
        insert new List<Contact>{
            new Contact(LastName = 'Challan', AccountId = customer.Id, Login_Hash_Code__c = HASH),
            new Contact(LastName = 'Other', AccountId = other.Id, Login_Hash_Code__c = OTHER_HASH)
        };
        Opportunity opp = new Opportunity(Name = 'Challan Booking', StageName = 'Prospecting', CloseDate = System.today().addDays(30),
                                          AccountId = customer.Id, Document_Id__c = 'OppRootFolder');
        Opportunity otherOpp = new Opportunity(Name = 'Other Booking', StageName = 'Prospecting', CloseDate = System.today().addDays(30),
                                               AccountId = other.Id);
        insert new List<Opportunity>{ opp, otherOpp };
        insert new Pricing_Element_Master__c(Name = 'Club House');
        Id pe = [SELECT Id FROM Pricing_Element_Master__c LIMIT 1].Id;
        insert new List<Receipt__c>{
            new Receipt__c(Opportunity__c = opp.Id, Type__c = 'Tax Invoice', Amount__c = 1000),
            new Receipt__c(Opportunity__c = opp.Id, Type__c = 'Tax Invoice', Amount__c = 2000),
            new Receipt__c(Opportunity__c = opp.Id, Type__c = 'Credit', Amount__c = 300, Approval_Status__c = 'Sent', Pricing_Element_Master__c = pe),
            new Receipt__c(Opportunity__c = opp.Id, Type__c = 'Debit', Amount__c = 400, Approval_Status__c = 'Sent', Pricing_Element_Master__c = pe)
        };
    }

    private static Opportunity booking() {
        return [SELECT Id, Name FROM Opportunity WHERE Name = 'Challan Booking' LIMIT 1];
    }

    private static String pdfData() {
        return EncodingUtil.base64Encode(Blob.valueOf('%PDF-1.4 challan'));
    }

    @isTest
    static void receiptsTabShowsOnlyTaxInvoicesWithReceiptNumber() {
        Test.startTest();
        CustomerPortalController.InvoiceWrapper w = CustomerPortalController.getInvoiceDetails(HASH);
        Test.stopTest();

        System.assertEquals(1, w.oppList.size());
        List<Receipt__c> shown = w.oppList[0].Receipts__r;
        System.assertEquals(2, shown.size(), 'Credit and debit notes must not be listed');
        for (Receipt__c r : shown) {
            System.assert(r.isSet('Receipt_Number__c'), 'Receipt number must be returned');
            System.assert(!r.isSet('TDS_Approval_Status__c'), 'TDS approval status is no longer shown');
        }
        System.assertNotEquals(null, w.oppIdXTdsChallans);
        System.assert(w.oppIdXTdsChallans.isEmpty());
    }

    @isTest
    static void receiptsTabWithUnknownCustomerReturnsEmptyLists() {
        CustomerPortalController.InvoiceWrapper w = CustomerPortalController.getInvoiceDetails('no-such-hash');
        System.assertNotEquals(null, w.oppList);
        System.assert(w.oppList.isEmpty());
        System.assertNotEquals(null, w.oppIdXTdsChallans);
    }

    @isTest
    static void uploadStoresChallanInTdsFolderAndNotifiesOwner() {
        Opportunity opp = booking();
        DriveMock mock = new DriveMock();
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        CustomerPortalController.TdsChallanResult res =
            CustomerPortalController.uploadTdsChallan(HASH, opp.Id, 'Challan Oct.pdf', pdfData(), 'application/pdf');
        Test.stopTest();   // also delivers the platform event to its trigger

        System.assertEquals(true, res.success, res.message);
        System.assertEquals(false, res.alreadyUploaded);
        Document__c folder = [SELECT Id, Name, Document_Id__c, Status__c FROM Document__c
                              WHERE Opportunity__c = :opp.Id AND Name = :CustomerPortalController.TDS_CHALLAN_FOLDER];
        System.assertEquals('TdsFolderId', folder.Document_Id__c);
        System.assertEquals('Uploaded', folder.Status__c);
        Sub_Document__c file = [SELECT Name, File_URL__c, Description__c FROM Sub_Document__c WHERE Document__c = :folder.Id];
        System.assertEquals('Challan Oct.pdf', file.Name);
        System.assert(file.File_URL__c.contains('ChallanFileId'));
        System.assert(file.Description__c.startsWith('TDS Challan uploaded by the customer'));
        System.assertEquals(1, CustomerPortalController.tdsChallanEventsPublished, 'Booking owner notification must be raised');

        // The Receipts tab lists the uploaded challan under its booking
        CustomerPortalController.InvoiceWrapper w = CustomerPortalController.getInvoiceDetails(HASH);
        System.assertEquals(1, w.oppIdXTdsChallans.get(opp.Id).size());
        System.assertEquals('Challan Oct.pdf', w.oppIdXTdsChallans.get(opp.Id)[0].Name);
    }

    @isTest
    static void secondChallanReusesFolderAndRepeatIsIgnored() {
        Opportunity opp = booking();
        insert new Document__c(Name = CustomerPortalController.TDS_CHALLAN_FOLDER, Opportunity__c = opp.Id, Status__c = 'Uploaded', Document_Id__c = 'ExistingTdsFolder');
        DriveMock mock = new DriveMock();
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        CustomerPortalController.TdsChallanResult first =
            CustomerPortalController.uploadTdsChallan(HASH, opp.Id, 'challan.png', pdfData(), 'image/png');
        CustomerPortalController.TdsChallanResult repeat =
            CustomerPortalController.uploadTdsChallan(HASH, opp.Id, 'challan.png', pdfData(), 'image/png');
        Test.stopTest();

        System.assertEquals(true, first.success, first.message);
        System.assertEquals(true, repeat.success);
        System.assertEquals(true, repeat.alreadyUploaded, 'A repeat click must not store the file again');
        System.assertEquals(0, mock.folderCalls, 'Existing TDS folder must be reused');
        System.assertEquals(1, mock.uploadCalls);
        System.assertEquals(1, [SELECT COUNT() FROM Document__c WHERE Opportunity__c = :opp.Id AND Name = :CustomerPortalController.TDS_CHALLAN_FOLDER]);
        System.assertEquals(1, [SELECT COUNT() FROM Sub_Document__c WHERE Document__r.Opportunity__c = :opp.Id]);
        System.assertEquals(1, CustomerPortalController.tdsChallanEventsPublished, 'Owner is notified once');
    }

    @isTest
    static void uploadRefusesOtherCustomersBookingAndBadInput() {
        Opportunity opp = booking();
        Test.setMock(HttpCalloutMock.class, new DriveMock());

        Test.startTest();
        CustomerPortalController.TdsChallanResult otherCustomer =
            CustomerPortalController.uploadTdsChallan(OTHER_HASH, opp.Id, 'c.pdf', pdfData(), 'application/pdf');
        CustomerPortalController.TdsChallanResult noSession =
            CustomerPortalController.uploadTdsChallan('', opp.Id, 'c.pdf', pdfData(), 'application/pdf');
        CustomerPortalController.TdsChallanResult unknownSession =
            CustomerPortalController.uploadTdsChallan('nope', opp.Id, 'c.pdf', pdfData(), 'application/pdf');
        CustomerPortalController.TdsChallanResult noFile =
            CustomerPortalController.uploadTdsChallan(HASH, opp.Id, 'c.pdf', '', 'application/pdf');
        CustomerPortalController.TdsChallanResult wrongType =
            CustomerPortalController.uploadTdsChallan(HASH, opp.Id, 'c.exe', pdfData(), 'application/octet-stream');
        CustomerPortalController.TdsChallanResult badOpp =
            CustomerPortalController.uploadTdsChallan(HASH, 'not-an-id', 'c.pdf', pdfData(), 'application/pdf');
        Test.stopTest();

        for (CustomerPortalController.TdsChallanResult r : new List<CustomerPortalController.TdsChallanResult>{ otherCustomer, noSession, unknownSession, noFile, wrongType, badOpp }) {
            System.assertEquals(false, r.success);
            System.assert(String.isNotBlank(r.message));
        }
        System.assert(otherCustomer.message.contains('could not be found'), otherCustomer.message);
        System.assert(noSession.message.contains('session'), noSession.message);
        System.assert(wrongType.message.contains('PDF, JPG or PNG'), wrongType.message);
        System.assertEquals(0, [SELECT COUNT() FROM Sub_Document__c]);
        System.assertEquals(0, CustomerPortalController.tdsChallanEventsPublished);
    }

    @isTest
    static void failedDriveUploadSavesNothing() {
        Opportunity opp = booking();
        DriveMock mock = new DriveMock();
        mock.failUpload = true;
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        CustomerPortalController.TdsChallanResult res =
            CustomerPortalController.uploadTdsChallan(HASH, opp.Id, 'c.pdf', pdfData(), 'application/pdf');
        Test.stopTest();

        System.assertEquals(false, res.success);
        System.assertEquals('The file could not be uploaded. Please try again.', res.message);
        System.assertEquals(0, [SELECT COUNT() FROM Sub_Document__c]);
        System.assertEquals(0, [SELECT COUNT() FROM Document__c WHERE Name = :CustomerPortalController.TDS_CHALLAN_FOLDER]);
        System.assertEquals(0, CustomerPortalController.tdsChallanEventsPublished);
    }

    @isTest
    static void ownerIsNotifiedAndUnknownBookingIsSkipped() {
        Opportunity opp = [SELECT Id, Name, Account.Name FROM Opportunity WHERE Name = 'Challan Booking'];
        String body = TdsChallanNotificationService.buildBody(opp, 'Challan Oct.pdf');
        System.assert(body.startsWith('TDS Challan has been uploaded by customer Challan Customer for Challan Booking.'), body);
        System.assert(body.endsWith('Please verify and create a TDS Receipt.'), body);

        List<TDS_Challan_Upload__e> events = new List<TDS_Challan_Upload__e>{
            new TDS_Challan_Upload__e(Opportunity_Id__c = 'bad-id', File_Name__c = 'x.pdf'),
            new TDS_Challan_Upload__e(Opportunity_Id__c = opp.Id, File_Name__c = 'y.pdf')
        };
        Test.startTest();
        TdsChallanNotificationService.notifyOwners(events);
        TdsChallanNotificationService.notifyOwners(new List<TDS_Challan_Upload__e>());
        Test.stopTest();
        System.assertEquals(1, TdsChallanNotificationService.sentCount, 'Only the real booking owner is notified');
    }

    @isTest
    static void eventTriggerRunsTheNotification() {
        Opportunity opp = booking();
        Test.startTest();
        Database.SaveResult sr = EventBus.publish(new TDS_Challan_Upload__e(Opportunity_Id__c = opp.Id, File_Name__c = 'z.pdf'));
        Test.stopTest();   // delivers the event to TDSChallanUploadTrigger
        System.assert(sr.isSuccess());
    }
}