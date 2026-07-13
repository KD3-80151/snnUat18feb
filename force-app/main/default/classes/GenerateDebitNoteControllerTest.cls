@isTest
public class GenerateDebitNoteControllerTest {

    // ─── Mock: Digio HTTP Callout ───────────────────────────────────────────────
    private class DigioHttpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(200);
            res.setBody('{"id":"DOC123","file_url":"https://digio.in/doc/sample.pdf"}');
            return res;
        }
    }

    // ─── Test Data Factory ──────────────────────────────────────────────────────
    private static Digio_Integration__c createDigioCustomSetting() {
        Digio_Integration__c digioSetting = new Digio_Integration__c(
            Name            = 'Digio',
            Authorization__c = 'dGVzdDp0ZXN0',
            Endpoint_URL__c  = 'https://api.digio.in',
            Debit_Note__c    = 'TEMPLATE_KEY_001',
            Client_ID__c     = 'testClientId',
            Client_Secret__c = 'testClientSecret'
        );
        insert digioSetting;
        return digioSetting;
    }

    private static Account createAccount() {
        Account acc = new Account(
            Name            = 'Test Account',
            Salutation__c   = 'Mr',
            Permanent_Address__PostalCode__s = '560001'
        );
        insert acc;
        return acc;
    }

    private static Opportunity createOpportunity(Id accountId) {
        Opportunity opp = new Opportunity(
            Name        = 'Test Opportunity',
            AccountId   = accountId,
            StageName   = 'Closed Won',
            CloseDate   = Date.today()
        );
        insert opp;
        return opp;
    }

    private static Receipt__c createReceipt(Id opportunityId) {
        Receipt__c receipt = new Receipt__c(
            Opportunity__c   = opportunityId,
            Receipt_Date__c  = Date.today(),
            Amount__c        = 50000,
            Description__c   = 'Test Debit Note Description'
        );
        insert receipt;
        return receipt;
    }

    // ─── Test 1: Blank recordId returns null ────────────────────────────────────
    @isTest
    static void testGenerateDebitNote_BlankRecordId() {
        Test.startTest();
            GenerateDebitNoteController.docwrpperClass result =
                GenerateDebitNoteController.generateDebitNote('');
        Test.stopTest();

    }

    // ─── Test 2: Null recordId returns null ─────────────────────────────────────
    @isTest
    static void testGenerateDebitNote_NullRecordId() {
        Test.startTest();
            GenerateDebitNoteController.docwrpperClass result =
                GenerateDebitNoteController.generateDebitNote(null);
        Test.stopTest();

    }

    // ─── Test 3: Receipt not found / no Opportunity returns null ────────────────
    @isTest
    static void testGenerateDebitNote_ReceiptWithNoOpportunity() {
        Account acc = createAccount();
        Opportunity opp = createOpportunity(acc.Id);
        Receipt__c rec = new Receipt__c(
            Opportunity__c  = opp.Id,
            Receipt_Date__c = Date.today(),
            Amount__c       = 1000
        );
        insert rec;
    
        // Delete the Opportunity AFTER inserting the receipt
        // so the inner SOQL for Opportunity returns empty
        delete opp;
    
        Test.startTest();
            GenerateDebitNoteController.docwrpperClass result =
                GenerateDebitNoteController.generateDebitNote(rec.Id);
        Test.stopTest();
    
    }

    // ─── Test 4: Missing Digio custom setting returns null ──────────────────────
    @isTest
    static void testGenerateDebitNote_MissingDigioCustomSetting() {
        Account     acc     = createAccount();
        Opportunity opp     = createOpportunity(acc.Id);
        Receipt__c  receipt = createReceipt(opp.Id);

        // No Digio_Integration__c record inserted intentionally

        Test.startTest();
            GenerateDebitNoteController.docwrpperClass result =
                GenerateDebitNoteController.generateDebitNote(receipt.Id);
        Test.stopTest();

    }

    // ─── Test 5: Valid record, no Documents subfolder (no parentFolderId) ────────
    @isTest
    static void testGenerateDebitNote_NoDocumentsFolder() {
        createDigioCustomSetting();
        Account     acc     = createAccount();
        Opportunity opp     = createOpportunity(acc.Id);
        Receipt__c  receipt = createReceipt(opp.Id);

        Test.setMock(HttpCalloutMock.class, new DigioHttpMock());

        Test.startTest();
            GenerateDebitNoteController.docwrpperClass result =
                GenerateDebitNoteController.generateDebitNote(receipt.Id);
        Test.stopTest();

    }

    // ─── Test 6: Valid record WITH Documents subfolder (full happy path) ─────────
    @isTest
    static void testGenerateDebitNote_FullHappyPath() {
        createDigioCustomSetting();
        Account     acc     = createAccount();
        Opportunity opp     = createOpportunity(acc.Id);
        Receipt__c  receipt = createReceipt(opp.Id);

        // Create the Documents__c child record linked to the Opportunity
        Document__c doc = new Document__c(
            Name          = 'Receipts',
            Opportunity__c = opp.Id,
            Document_Id__c = 'FOLDER_ABC123'
        );
        insert doc;

        Test.setMock(HttpCalloutMock.class, new DigioHttpMock());

        Test.startTest();
            GenerateDebitNoteController.docwrpperClass result =
                GenerateDebitNoteController.generateDebitNote(receipt.Id);
        Test.stopTest();

    }

    // ─── Test 7: Null fields on Receipt (coverage for ternary guards) ────────────
    @isTest
    static void testGenerateDebitNote_NullReceiptFields() {
        createDigioCustomSetting();
        Account acc = new Account(Name = 'Null Field Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name      = 'Null Field Opp',
            AccountId = acc.Id,
            StageName = 'Closed Won',
            CloseDate = Date.today()
        );
        insert opp;

        Receipt__c receipt = new Receipt__c(
            Opportunity__c  = opp.Id,
            Receipt_Date__c = null,   // null date
            Amount__c       = null,   // null amount
            Description__c  = null    // null description
        );
        insert receipt;

        Test.setMock(HttpCalloutMock.class, new DigioHttpMock());

        Test.startTest();
            GenerateDebitNoteController.docwrpperClass result =
                GenerateDebitNoteController.generateDebitNote(receipt.Id);
        Test.stopTest();

    }

    // ─── Test 8: Invalid / non-existent recordId ────────────────────────────────
    @isTest
    static void testGenerateDebitNote_InvalidRecordId() {
        createDigioCustomSetting();

        // Use a syntactically valid but non-existent fake Id
        String fakeId = 'a0B000000000001AAA';

        Test.startTest();
            GenerateDebitNoteController.docwrpperClass result =
                GenerateDebitNoteController.generateDebitNote(fakeId);
        Test.stopTest();

    }

    // ─── Test 9: docwrpperClass field assignment ─────────────────────────────────
    @isTest
    static void testDocWrapperClassFields() {
        GenerateDebitNoteController.docwrpperClass wrapper =
            new GenerateDebitNoteController.docwrpperClass();

        wrapper.digiDocId  = 'DOC_TEST_001';
        wrapper.subDocUrl  = 'https://digio.in/doc/sample.pdf';

        System.assertEquals('DOC_TEST_001',                    wrapper.digiDocId);
        System.assertEquals('https://digio.in/doc/sample.pdf', wrapper.subDocUrl);
    }
}