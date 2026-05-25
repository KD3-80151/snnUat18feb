@isTest
public class bulkUpdateDueDateControllerTest {

    @testSetup
    static void setupTestData() {
        
        Company__c company = new Company__c(Name = 'Test Company');
        insert company;

        
        Project__c project = new Project__c(Name = 'Test Project', Company__c = company.Id);
        insert project;

        
        Tower__c tower = new Tower__c(Name = 'Test Tower', Project__c = project.Id);
        insert tower;

        
        Payment_Scheme__c paymentScheme = new Payment_Scheme__c(Name = 'Test Payment Scheme', Company__c = company.Id, Project__c = project.Id, Block__c = tower.Id);
        insert paymentScheme;

        Opportunity opp = new Opportunity(Name = 'Test Opportunity', StageName = 'Prospecting', CloseDate = Date.today(), Project__c = project.Id, Payment_Scheme__c = paymentScheme.Id);
        insert opp;

        Payment_Schedule__c schedule1 = new Payment_Schedule__c(Name = 'Installment 1', Opportunity__c = opp.Id, Due_Date__c = Date.today(), Pay_Date__c = Date.today().addDays(10));
        Payment_Schedule__c schedule2 = new Payment_Schedule__c(Name = 'Installment 2', Opportunity__c = opp.Id, Due_Date__c = Date.today().addDays(5), Pay_Date__c = Date.today().addDays(15));
        insert new List<Payment_Schedule__c>{schedule1, schedule2};
    }

    @isTest
    static void testGetAllCompanies() {
        Test.startTest();
        List<Company__c> companies = bulkUpdateDueDateController.getAllCompanies();
        Test.stopTest();


    }

    @isTest
    static void testGetProjects() {
        Company__c company = [SELECT Id FROM Company__c LIMIT 1];

        Test.startTest();
        List<Project__c> projects = bulkUpdateDueDateController.getProjects(company.Id);
        Test.stopTest();

    }

    @isTest
    static void testGetBlocks() {
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];

        Test.startTest();
        List<Tower__c> blocks = bulkUpdateDueDateController.getBlocks(project.Id);
        Test.stopTest();

    }

    @isTest
    static void testGetPaymentScheme() {
        Company__c company = [SELECT Id FROM Company__c LIMIT 1];
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        Tower__c block = [SELECT Id FROM Tower__c LIMIT 1];

        Test.startTest();
        List<Payment_Scheme__c> paymentSchemes = bulkUpdateDueDateController.getpaymentScheme(company.Id, project.Id, block.Id);
        Test.stopTest();

    }

    @isTest
    static void testSaveTableData() {
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        Payment_Scheme__c paymentScheme = [SELECT Id FROM Payment_Scheme__c LIMIT 1];
        Payment_Schedule__c schedule = [SELECT Id, Name FROM Payment_Schedule__c LIMIT 1];

        // Create payload
        List<bulkUpdateDueDateController.PaymentInstallmentWrapper> wrappers = new List<bulkUpdateDueDateController.PaymentInstallmentWrapper>();
        bulkUpdateDueDateController.PaymentInstallmentWrapper wrapper = new bulkUpdateDueDateController.PaymentInstallmentWrapper();
        wrapper.Name = schedule.Name;
        wrapper.dueDate = Date.today().addDays(20);
        wrapper.payByDate = Date.today().addDays(30);
        wrappers.add(wrapper);

        String payload = JSON.serialize(
            new Map<String, Object>{
                'projectId' => project.Id,
                'paymentSchemeId' => paymentScheme.Id,
                'paymentInstallments' => wrappers
            }
        );

        Test.startTest();
        bulkUpdateDueDateController.saveTableData(payload);
        Test.stopTest();


    }

    @isTest
    static void testNullParameters() {

        try {
            bulkUpdateDueDateController.getProjects(null);
            System.assert(false, 'Expected exception for null Company ID');
        } catch (Exception e) {

        }

        try {
            bulkUpdateDueDateController.getBlocks(null);

        } catch (Exception e) {

        }

        try {
            bulkUpdateDueDateController.saveTableData('');
        } catch (Exception e) {

        }
    }
    
    
     @isTest
    static void testGetCostScheamLinking() {
        
          Company__c company = new Company__c(Name = 'Test Company');
        insert company;

        
        Project__c project = new Project__c(Name = 'Test Project', Company__c = company.Id);
        insert project;

        Payment_Scheme__c paymentScheme = new Payment_Scheme__c(Name = 'Test Payment Scheme');
        insert paymentScheme;

        Cost_Sheet_Template__c costSheetTemplate = new Cost_Sheet_Template__c(Name = 'Test Cost Sheet Template',Company__c =company.Id,Project__c = project.Id );
        insert costSheetTemplate;

        Cost_Scheme_Linking__c costSchemeLinking = new Cost_Scheme_Linking__c(
            Payment_Scheme__c = paymentScheme.Id,
            Cost_Sheet_Template__c = costSheetTemplate.Id
        );
        insert costSchemeLinking;

        Test.startTest();
        List<Cost_Scheme_Linking__c> result = bulkUpdateDueDateController.getCostScheamLinking(paymentScheme.Id);
        Test.stopTest();

    }

    @isTest
    static void testGetPaymentInstallment() {

        Payment_Scheme__c paymentScheme = new Payment_Scheme__c(Name = 'Test Payment Scheme');
        insert paymentScheme;

        Payment_Schedule_Master__c paymentScheduleMaster = new Payment_Schedule_Master__c(Name = 'Test Payment Schedule Master');
        insert paymentScheduleMaster;

        Payment_Scheme_Installment__c paymentInstallment = new Payment_Scheme_Installment__c(
            Payment_Scheme__c = paymentScheme.Id,
            Payment_Schedule_Master__c = paymentScheduleMaster.Id
        );
        insert paymentInstallment;

        Test.startTest();
        List<Payment_Scheme_Installment__c> result = bulkUpdateDueDateController.getPaymentInstallment(paymentScheme.Id);
        Test.stopTest();

    }

    @isTest
    static void testNullInput() {
        
        Test.startTest();
        try {
            bulkUpdateDueDateController.getCostScheamLinking(null);
            System.assert(false, 'Method did not throw an exception for null input.');
        } catch (AuraHandledException e) {

        }

        try {
            bulkUpdateDueDateController.getPaymentInstallment(null);
            System.assert(false, 'Method did not throw an exception for null input.');
        } catch (AuraHandledException e) {
           
        }

        Test.stopTest();
    }
    @isTest
    static void testGetSelectedOppPaymentSchedules(){
        List<Opportunity> oppList = [SELECT Id FROM Opportunity];
        Test.startTest();
        bulkUpdateDueDateController.getSelectedOppPaymentSchedules(oppList[0].Id);
        try{
        bulkUpdateDueDateController.getSelectedOppPaymentSchedules(null);
        }catch(Exception e){
            
        }
        Test.stopTest();
    }
   @isTest
    static void testSaveOppsPaySchedulesSave() {
        
        // Create required test data
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today()
        );
        insert opp;

        Payment_Schedule__c ps = new Payment_Schedule__c(
            Name = 'Test Schedule',
            Opportunity__c = opp.Id,
            Due_Date__c = Date.today().addDays(5),
            Pay_Date__c = Date.today()
        );
        insert ps;
        
        // Build JSON input for the method
        String jsonInput = '[{"Id":"' + ps.Id + '","Due_Date__c":"2025-01-20","Pay_Date__c":"2025-01-10"}]';

        Test.startTest();
        String result = bulkUpdateDueDateController.saveOppsPaySchedulesSave(jsonInput);
        Test.stopTest();
       
    }
}