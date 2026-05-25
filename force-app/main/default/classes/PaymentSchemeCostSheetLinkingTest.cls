@isTest
public class PaymentSchemeCostSheetLinkingTest {

    // Utility method for test data
    private static Map<String, Id> createTestData() {
        Map<String, Id> ids = new Map<String, Id>();

        Company__c comp = new Company__c(Name = 'Test Company', Email__c = 'test@test.com');
        insert comp;
        ids.put('Company', comp.Id);

        Project__c proj = new Project__c(Name = 'Test Project', Company__c = comp.Id);
        insert proj;
        ids.put('Project', proj.Id);

        Tower__c tower = new Tower__c(Name = 'Test Tower', Project__c = proj.Id, Tower_Code__c = 'T01');
        insert tower;
        ids.put('Tower', tower.Id);

        Payment_Scheme__c ps = new Payment_Scheme__c(
            Name = 'Test Scheme',
            Company__c = comp.Id,
            Project__c = proj.Id,
            Approval_Status__c = 'Approved'
        );
        insert ps;
        ids.put('PaymentScheme', ps.Id);

        Cost_Sheet_Template__c cs = new Cost_Sheet_Template__c(
            Name = 'Test Cost Sheet',
            Company__c = comp.Id,
            Project__c = proj.Id,
            Template_Code__c = 'CS01',
            Approval_Status__c = 'Approved'
        );
        insert cs;
        ids.put('CostSheet', cs.Id);

        Payment_Scheme_Installment__c psi = new Payment_Scheme_Installment__c(
            Payment_Scheme__c = ps.Id,
            Installment__c = 50,
            Display_Order__c = 1
        );
        insert psi;
        ids.put('PSI', psi.Id);

        return ids;
    }

    @isTest
    static void testGetCostSheetData() {
        createTestData();
        Test.startTest();
        PaymentSchemeCostSheetLinkingController.WrapperList wrap =
            PaymentSchemeCostSheetLinkingController.getCostSheetData();
        Test.stopTest();

        
    }

    @isTest
    static void testSubmitDataAndGetCostSheetExisData() {
        Map<String, Id> ids = createTestData();

        Test.startTest();
        List<Scheme_Installment__c> result =
            PaymentSchemeCostSheetLinkingController.submitData(ids.get('PaymentScheme'), ids.get('CostSheet'));
        Test.stopTest();

        Id linkingId = [SELECT Id FROM Cost_Scheme_Linking__c LIMIT 1].Id;
        PaymentSchemeCostSheetLinkingController.CostSheetDataWrapper wrap =
            PaymentSchemeCostSheetLinkingController.getCostSheetExisData(linkingId);

        
    }

    @isTest
    static void testUpdateDataWithSchemeId() {
        Map<String, Id> ids = createTestData();

        PaymentSchemeCostSheetLinkingController.submitData(ids.get('PaymentScheme'), ids.get('CostSheet'));
        Id linkingId = [SELECT Id FROM Cost_Scheme_Linking__c LIMIT 1].Id;

        Test.startTest();
        List<Scheme_Installment__c> updated =
            PaymentSchemeCostSheetLinkingController.updateData(ids.get('PaymentScheme'), ids.get('CostSheet'), linkingId, null);
        

        Test.stopTest();

    }

    @isTest
    static void testSubmitDataDuplicateError() {
        Map<String, Id> ids = createTestData();

        // First insert linking manually
        Cost_Scheme_Linking__c link = new Cost_Scheme_Linking__c(
            Payment_Scheme__c = ids.get('PaymentScheme'),
            Cost_Sheet_Template__c = ids.get('CostSheet')
        );
        insert link;

        Test.startTest();
        try {
            PaymentSchemeCostSheetLinkingController.submitData(ids.get('PaymentScheme'), ids.get('CostSheet'));
        } catch (AuraHandledException e) {
          //  System.assert(e.getMessage().contains('already exists'));
        }
        Test.stopTest();
    }
    @isTest
    static void testUpdateDataNoCostSheet() {
        Map<String, Id> ids = createTestData();

        PaymentSchemeCostSheetLinkingController.submitData(ids.get('PaymentScheme'), ids.get('CostSheet'));
        Id linkingId = [SELECT Id FROM Cost_Scheme_Linking__c LIMIT 1].Id;

        delete [SELECT Id FROM Cost_Sheet_Template__c LIMIT 1];

        Test.startTest();
try {
    PaymentSchemeCostSheetLinkingController.updateData(
        ids.get('PaymentScheme'),
        ids.get('CostSheet'),
        linkingId,
        null
    );
    System.assert(false, 'Expected exception but none was thrown');
} 
catch (System.QueryException e) {
    System.assert(e.getMessage().contains('no rows'), 'Unexpected error message: ' + e.getMessage());
}
Test.stopTest();

    }
    @isTest
    static void testGetCostSheetExisDataException() {
        Test.startTest();
        try {
            PaymentSchemeCostSheetLinkingController.getCostSheetExisData('invalidId');
            //System.assert(false, 'Expected AuraHandledException');
        } catch (AuraHandledException e) {
            //System.assert(e.getMessage().contains('Error occurred'));
        }
        Test.stopTest();
    }

      @isTest
    static void testSubmitDataGenericException() {
        Test.startTest();
        try {
            PaymentSchemeCostSheetLinkingController.submitData('invalidId', 'invalidId');
            //System.assert(false, 'Expected AuraHandledException');
        } catch (AuraHandledException e) {
            //System.assert(e.getMessage().contains('Error occurred'));
        }
        Test.stopTest();
    }
}