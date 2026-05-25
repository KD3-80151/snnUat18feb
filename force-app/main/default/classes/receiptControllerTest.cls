@isTest
public class receiptControllerTest {

    @testSetup
    static void setupData() {
       
        Account acc = new Account(Name = 'Test Account');
        insert acc;

         Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            CloseDate = Date.today().addDays(10),
            StageName = 'Prospecting',
            AccountId = acc.Id
        );
        insert opp;
        Unit__c unit = new Unit__c(
            Account__c = acc.Id,
            Total__c = 1000,
            Balance__c = 500,
            Total_Tax__c = 100,
            Allocated_Tax__c = 50,
            Balance_Tax__c = 50,
            Allocated__c = 500
        );
        insert unit;

        Receipt__c rec = new Receipt__c(
            Account__c = acc.Id,
            Unit__c = unit.Id,
            Amount__c = 200,
            Opportunity__c = opp.Id,
            Receipt_Date__c = Date.today()
        );
        insert rec;
    }

    @isTest
    static void testFetchReceipts() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];

        Test.startTest();
        List<Receipt__c> receipts = receiptController.fetchReceipts(acc.Id, unit.Id);
        Test.stopTest();

        System.assertNotEquals(null, receipts, 'Receipts should not be null');
        System.assert(!receipts.isEmpty(), 'Receipts should be returned');
    }

    @isTest
    static void testCreateReceipt() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];

        Receipt__c rec = new Receipt__c(
            Account__c = acc.Id,
            Unit__c = unit.Id,
            Amount__c = 300,
            Receipt_Date__c = Date.today()
        );

        Test.startTest();
        String receiptId = receiptController.createReceipt(rec);
        Test.stopTest();

        System.assertNotEquals(null, receiptId, 'Receipt Id should be returned');
    }

    @isTest
    static void testGetUnitDetailsByAccId() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        Unit__c unit = receiptController.getUnitDetails(acc.Id, null);
        Test.stopTest();

        System.assertNotEquals(null, unit, 'Unit should be returned when accId is passed');
    }

    @isTest
    static void testGetUnitDetailsByUnitId() {
        Unit__c unitRec = [SELECT Id FROM Unit__c LIMIT 1];

        Test.startTest();
        Unit__c unit = receiptController.getUnitDetails(null, unitRec.Id);
        Test.stopTest();

        System.assertNotEquals(null, unit, 'Unit should be returned when unitId is passed');
    }

    @isTest
    static void testGetAllPickListVal() {
        Map<String, String> inputMap = new Map<String, String>{
            'StageName' => 'Opportunity'
        };

        Test.startTest();
        Map<String, List<String>> result = receiptController.getAllPickListVal(inputMap);
        Test.stopTest();

        System.assert(result.containsKey('StageName'), 'StageName should exist in result');
        System.assert(!result.get('StageName').isEmpty(), 'StageName picklist values should not be empty');
    }

    @isTest
    static void testGetPicklistValuesDirect() {
        Test.startTest();
        List<String> values = receiptController.getPicklistValues('Opportunity', 'StageName');
        Test.stopTest();

        System.assert(!values.isEmpty(), 'Picklist values should be returned for Opportunity.StageName');
    }
}