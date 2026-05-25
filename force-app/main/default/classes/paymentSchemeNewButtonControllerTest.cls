@isTest
public class paymentSchemeNewButtonControllerTest {

    @TestSetup
    static void setupTestData() {
        Company__c company = new Company__c(Name = 'Test Company');
        insert company;

        Project__c project = new Project__c(Name = 'Test Project', Company__c = company.Id);
        insert project;

        Tower__c tower = new Tower__c(Name = 'Test Tower', Project__c = project.Id);
        insert tower;

        Payment_Schedule_Master__c paymentScheduleMaster = new Payment_Schedule_Master__c(
            Name = 'Test Payment Schedule',
            Installment_Code__c = 'TEST001',
            Installment_Sequence__c = 1
        );
        insert paymentScheduleMaster;

        Payment_Scheme__c paymentScheme = new Payment_Scheme__c(
            Name = 'Test Payment Scheme',
            Company__c = company.Id,
            Project__c = project.Id,
            Block__c = tower.Id,
            Token_Amount__c = 5000,
            From_Date__c = Date.today(),
            To_Date__c = Date.today().addDays(30)
        );
        insert paymentScheme;

        Payment_Scheme_Installment__c paymentInstallment = new Payment_Scheme_Installment__c(
            Payment_Scheme__c = paymentScheme.Id,
            Payment_Schedule_Master__c = paymentScheduleMaster.Id,
            Display_Order__c = 1
        );
        insert paymentInstallment;
    }

    @isTest
    static void testSaveInstallmentData() {
        Test.startTest();
        Map<String, Object> data = new Map<String, Object>{
            'name' => 'Test Installment',
            'installmentCode' => 'TEST002',
            'installmentSequence' => '2'
        };
        paymentSchemeNewButtonController.saveInstallmentData(data);
        Test.stopTest();
    }

    @isTest
    static void testGetAllCompanies() {
        Test.startTest();
        List<Company__c> companies = paymentSchemeNewButtonController.getAllCompanies();
        System.assert(!companies.isEmpty());
        Test.stopTest();
    }

    @isTest
    static void testGetProjects() {
        Company__c company = [SELECT Id FROM Company__c LIMIT 1];
        Test.startTest();
        List<Project__c> projects = paymentSchemeNewButtonController.getProjects(company.Id);
        System.assert(!projects.isEmpty());
        Test.stopTest();
    }

    @isTest
    static void testGetBlocks() {
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        Test.startTest();
        List<Tower__c> blocks = paymentSchemeNewButtonController.getBlocks(project.Id);
        System.assert(!blocks.isEmpty());
        Test.stopTest();
    }

    @isTest
    static void testGetPaymentScheduleOptions() {
        Test.startTest();
        List<Payment_Schedule_Master__c> paymentSchedules = paymentSchemeNewButtonController.getPaymentScheduleOptions();
        System.assert(!paymentSchedules.isEmpty());
        Test.stopTest();
    }

    @isTest
    static void testInsertPaymentScheme() {
        Payment_Scheme__c paymentScheme = [SELECT Id, Company__c, Project__c, Block__c, Token_Amount__c, Name, From_Date__c, To_Date__c FROM Payment_Scheme__c LIMIT 1];
        List<Payment_Scheme_Installment__c> installments = [SELECT Id, Payment_Scheme__c, Payment_Schedule_Master__c, Display_Order__c FROM Payment_Scheme_Installment__c LIMIT 1];
        List<String> blockIds = new List<String>{paymentScheme.Block__c};

        Test.startTest();
        List<String> insertedPaymentSchemeIds = paymentSchemeNewButtonController.insertPaymentScheme(paymentScheme, installments, false, blockIds);
        System.assert(!insertedPaymentSchemeIds.isEmpty());
        Test.stopTest();
    }

    @isTest
    static void testGetPaymentScheme() {
        Payment_Scheme__c paymentScheme = [SELECT Id FROM Payment_Scheme__c LIMIT 1];
        Test.startTest();
        paymentSchemeNewButtonController.PaymentSchemeWrapper wrapper = paymentSchemeNewButtonController.getPaymentScheme(paymentScheme.Id);
        System.assert(!wrapper.paymentSchemes.isEmpty());
        Test.stopTest();
    }

    @isTest
    static void testInsertPaymentSchemeUpdate() {
        Payment_Scheme__c paymentScheme = [SELECT Id, Company__c, Project__c, Block__c, Token_Amount__c, Name, From_Date__c, To_Date__c FROM Payment_Scheme__c LIMIT 1];
        List<Payment_Scheme_Installment__c> installments = [SELECT Id, Payment_Scheme__c, Payment_Schedule_Master__c, Display_Order__c FROM Payment_Scheme_Installment__c LIMIT 1];
        List<String> blockIds = new List<String>{paymentScheme.Block__c};

        Test.startTest();
        // First Insert
        List<String> insertedPaymentSchemeIds = paymentSchemeNewButtonController.insertPaymentScheme(paymentScheme, installments, false, blockIds);
        
        // Update
        paymentScheme.Name = 'Updated Payment Scheme';
        List<String> updatedPaymentSchemeIds = paymentSchemeNewButtonController.insertPaymentScheme(paymentScheme, installments, true, blockIds);
        Test.stopTest();

        System.assert(!insertedPaymentSchemeIds.isEmpty());
    }
}