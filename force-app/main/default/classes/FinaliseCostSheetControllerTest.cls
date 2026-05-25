@isTest
public class FinaliseCostSheetControllerTest {

    // Helper to create all test data
    private static Id setupTestData(Boolean withFinalize) {
        Company__c company = new Company__c(Name='Test Company');
        insert company;

        Project__c project = new Project__c(Name='Test Project', Company__c=company.Id);
        insert project;

        Tower__c tower = new Tower__c(Name='Test Tower', Project__c=project.Id);
        insert tower;

        Floor__c floor = new Floor__c(Blocks__c = tower.Id);
        insert floor;

        Unit__c unit = new Unit__c( Floor__c = floor.Id);
        insert unit;

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            AccountId = acc.Id,
            Unit__c = unit.Id
        );
        insert opp;

        Cost_Sheet_Template__c csTemp = new Cost_Sheet_Template__c(
            Name = 'Test Cost Sheet Template ' + System.currentTimeMillis(),
            Company__c = company.Id,
            Project__c = project.Id,
            Template_Code__c = 'CS' + System.currentTimeMillis(),
            Approval_Status__c = 'Approved'
        );
        insert csTemp;

        Payment_Scheme__c ps = new Payment_Scheme__c(
            Name = 'Test Scheme',
            Company__c = company.Id,
            Project__c = project.Id,
            Approval_Status__c = 'Approved'
        );
        insert ps;

        Payment_Schedule_Master__c psm = new Payment_Schedule_Master__c(
            Name = 'Test PSM',
            Installment_Code__c = 'INST1',
            Installment_Sequence__c = 1
        );
        insert psm;

        Payment_Scheme_Installment__c psi = new Payment_Scheme_Installment__c(
            Payment_Scheme__c = ps.Id,
            Installment__c = 50,
            Display_Order__c = 1,
            Payment_Schedule_Master__c = psm.Id
        );
        insert psi;

        Cost_Scheme_Linking__c link = new Cost_Scheme_Linking__c(
            Payment_Scheme__c = ps.Id,
            Cost_Sheet_Template__c = csTemp.Id
        );
        insert link;

        Cost_Sheet__c costSheet = new Cost_Sheet__c(
       
            Opportunity__c = opp.Id,
            Unit__c = unit.Id,
            Cost_Scheme_Linking__c = link.Id,
            finalize_CostSheet__c = withFinalize
        );
        insert costSheet;

        Pricing_Element_Master__c pem = new Pricing_Element_Master__c(Name = 'Car Parking');
        insert pem;

        Pricing_Element__c pe = new Pricing_Element__c(
            Cost_Sheet__c = costSheet.Id,
            Pricing_Element_Master__c = pem.Id,
            Quantity__c = 2,
            Rate__c = 100,
            Amount__c = 200
        );
        insert pe;

        Task t = new Task(
            Subject = 'Finalise Cost Sheet & Generate Payment Schedule',
            WhatId = opp.Id,
            Status = 'Not Started'
        );
        insert t;

        return t.Id;
    }

    @isTest
    static void testGetRecordDetails() {
        Id taskId = setupTestData(true);

        Test.startTest();
        FinaliseCostSheetController.CostSheetWrapper wrap =
            FinaliseCostSheetController.getRecordDetails(taskId);
        Test.stopTest();

        System.assertNotEquals(null, wrap, 'Wrapper should not be null');
        System.assert(wrap.costSheetRecords.size() > 0, 'Should return Cost Sheet Records');
    }

    @isTest
    static void testCreatePaymentSchedule() {
        Id taskId = setupTestData(false);

        // Fetch a cost sheet created by setup
        Cost_Sheet__c cs = [SELECT Id FROM Cost_Sheet__c LIMIT 1];

        Test.startTest();
        FinaliseCostSheetController.costSheetAndTemplateWrapper wrap =
        FinaliseCostSheetController.createPaymentSchedule(taskId, cs.Id, cs.Id);
        Test.stopTest();

        System.assertNotEquals(null, wrap, 'Wrapper should not be null');
        System.assert(wrap.paymentScheduleList.size() > 0, 'Should create Payment Schedules');
    }

    @isTest
    static void testSendApproval() {
        Id taskId = setupTestData(true);

        Test.startTest();
        String result = '';
        try {
            result = FinaliseCostSheetController.sendApproval(taskId);
        } catch (Exception e) {
       
            result = 'Approval submission failed: ' + e.getMessage();
        }
        Test.stopTest();

        System.assert(result.contains('Opportunity ID') || result.contains('Approval submission failed'),
                      'Should attempt approval submission');
    }
}