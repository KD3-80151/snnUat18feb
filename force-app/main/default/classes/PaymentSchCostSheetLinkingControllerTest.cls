@isTest
public class PaymentSchCostSheetLinkingControllerTest {
		
    @isTest
    public static void testGetCostSheetData() {
        Company__c company1 = new Company__c(Name = 'Company 1', Email__c = 'company1@example.com');
        Company__c company2 = new Company__c(Name = 'Company 2', Email__c = 'company2@example.com');
        insert new List<Company__c>{company1, company2};
        
        Project__c project1 = new Project__c(Name = 'Project 1', Company__c = company1.Id);
        Project__c project2 = new Project__c(Name = 'Project 2', Company__c = company2.Id);
        insert new List<Project__c>{project1, project2};
        
        Tower__c tower1 = new Tower__c(Name = 'Tower 1', Project__c = project1.Id, Tower_Code__c = 'T1', Parking_Availability__c = true);
        Tower__c tower2 = new Tower__c(Name = 'Tower 2', Project__c = project2.Id, Tower_Code__c = 'T2', Parking_Availability__c = false);
        insert new List<Tower__c>{tower1, tower2};
        
        Payment_Scheme__c paymentScheme1 = new Payment_Scheme__c(
            Name = 'Payment Scheme 1', 
            Block__c = tower1.id, 
            Company__c = company1.Id, 
            Project__c = project1.Id, 
            From_Date__c = Date.today(), 
            To_Date__c = Date.today().addDays(30),
            Token_Amount__c = 1000, 
            Installment_start_date_diff_in_days__c = 7, 
            Approval_Status__c = 'Approved'
        );
        Payment_Scheme__c paymentScheme2 = new Payment_Scheme__c(
            Name = 'Payment Scheme 2', 
            Block__c = tower2.id, 
            Company__c = company2.Id, 
            Project__c = project2.Id, 
            From_Date__c = Date.today(), 
            To_Date__c = Date.today().addDays(60),
            Token_Amount__c = 1500, 
            Installment_start_date_diff_in_days__c = 10, 
            Approval_Status__c = 'Approved'
        );
        insert new List<Payment_Scheme__c>{paymentScheme1, paymentScheme2};
        
        Cost_Sheet_Template__c costSheetTemplate1 = new Cost_Sheet_Template__c(
            Name = 'Cost Sheet Template 1', 
            Company__c = company1.Id, 
            Project__c = project1.Id, 
            Template_Code__c = 'TEMPLATE1', 
            Approval_Status__c = 'Approved'
        );
        Cost_Sheet_Template__c costSheetTemplate2 = new Cost_Sheet_Template__c(
            Name = 'Cost Sheet Template 2', 
            Company__c = company2.Id, 
            Project__c = project2.Id, 
            Template_Code__c = 'TEMPLATE2', 
            Approval_Status__c = 'Approved'
        );
        insert new List<Cost_Sheet_Template__c>{costSheetTemplate1, costSheetTemplate2};
        
        Test.startTest();
        
        PaymentSchemeCostSheetLinkingController.WrapperList wrapperList = PaymentSchemeCostSheetLinkingController.getCostSheetData();
        
        Test.stopTest();
    }
    
     @isTest
    public static void testSubmitData() {
        Company__c company = new Company__c(Name = 'Test Company');
        insert company;

        Project__c project = new Project__c(Name = 'Test Project', Company__c = company.Id);
        insert project;

        Payment_Scheme__c paymentScheme = new Payment_Scheme__c(
            Name = 'Test Payment Scheme', 
            Company__c = company.Id, 
            Project__c = project.Id,
            Approval_Status__c = 'Approved'
        );
        insert paymentScheme;

        Cost_Sheet_Template__c costSheetTemplate = new Cost_Sheet_Template__c(
            Name = 'Test Cost Sheet', 
            Company__c = company.Id, 
            Project__c = project.Id, 
            Template_Code__c = 'TEMPLATE1', 
            Approval_Status__c = 'Approved'
        );
        insert costSheetTemplate;

        Payment_Scheme_Installment__c paymentSchemeInstallment = new Payment_Scheme_Installment__c( 
            Payment_Scheme__c = paymentScheme.Id, 
            Installment__c = 25,
            Display_Order__c = 1
        );
        insert paymentSchemeInstallment;

        Test.startTest();

        List<Scheme_Installment__c> schemeInstallments = PaymentSchemeCostSheetLinkingController.submitData(paymentScheme.Id, costSheetTemplate.Id);

        Test.stopTest();
    }

    @isTest
    public static void testSubmitDataWithExistingLink() {
        Company__c company = new Company__c(Name = 'Test Company');
        insert company;

        Project__c project = new Project__c(Name = 'Test Project', Company__c = company.Id);
        insert project;

        Payment_Scheme__c paymentScheme = new Payment_Scheme__c(
            Name = 'Test Payment Scheme', 
            Company__c = company.Id, 
            Project__c = project.Id,
            Approval_Status__c = 'Approved'
        );
        insert paymentScheme;

        Cost_Sheet_Template__c costSheetTemplate = new Cost_Sheet_Template__c(
            Name = 'Test Cost Sheet', 
            Company__c = company.Id, 
            Project__c = project.Id, 
            Template_Code__c = 'TEMPLATE1', 
            Approval_Status__c = 'Approved'
        );
        insert costSheetTemplate;

        Cost_Scheme_Linking__c existingLink = new Cost_Scheme_Linking__c(
            Payment_Scheme__c = paymentScheme.Id,
            Cost_Sheet_Template__c = costSheetTemplate.Id
        );
        insert existingLink;

        Test.startTest();

        try {
            List<Scheme_Installment__c> schemeInstallments = PaymentSchemeCostSheetLinkingController.submitData(paymentScheme.Id, costSheetTemplate.Id);
        } catch (AuraHandledException e) {
        }

        Test.stopTest();
    }
    
    @isTest
    public static void testGetCostSheetExisData() {
        Company__c company = new Company__c(Name = 'Test Company');
        insert company;

        Project__c project = new Project__c(Name = 'Test Project', Company__c = company.Id);
        insert project;
		
        Tower__c tower1 = new Tower__c(Name = 'Tower 1', Project__c = project.Id, Tower_Code__c = 'T1', Parking_Availability__c = true);
        
        Payment_Scheme__c paymentScheme = new Payment_Scheme__c(
            Name = 'Test Payment Scheme', 
            Company__c = company.Id, 
            Project__c = project.Id,
            Approval_Status__c = 'Approved',
            Block__c = tower1.Id
        );
        insert paymentScheme;

        Cost_Sheet_Template__c costSheetTemplate = new Cost_Sheet_Template__c(
            Name = 'Test Cost Sheet', 
            Company__c = company.Id, 
            Project__c = project.Id, 
            Template_Code__c = 'TEMPLATE1', 
            Approval_Status__c = 'Approved'
        );
        insert costSheetTemplate;

        Cost_Scheme_Linking__c costSchemeLinking = new Cost_Scheme_Linking__c(
            Payment_Scheme__c = paymentScheme.Id,
            Cost_Sheet_Template__c = costSheetTemplate.Id,
            Approval_Status__c = 'Approved'
        );
        insert costSchemeLinking;
        
        Payment_Schedule_Master__c psm = new Payment_Schedule_Master__c();
        psm.Name = 'tets';
        insert psm;

        Scheme_Installment__c schemeInstallment = new Scheme_Installment__c(
            Cost_Scheme_Linking__c = costSchemeLinking.Id,
            Payment_Schedule_Master__c = psm.Id,
            Agreement_Value__c = 1000,
            Agreement_Tax__c = 100,
            Installment__c = 500
        );
        insert schemeInstallment;

        Test.startTest();

       PaymentSchemeCostSheetLinkingController.CostSheetDataWrapper result = PaymentSchemeCostSheetLinkingController.getCostSheetExisData(costSchemeLinking.Id);

        Test.stopTest();
    }
    
    @isTest
    public static void testUpdateData() {
        Company__c company = new Company__c(Name = 'Test Company');
        insert company;

        Project__c project = new Project__c(Name = 'Test Project', Company__c = company.Id);
        insert project;
		
        Tower__c tower1 = new Tower__c(Name = 'Tower 1', Project__c = project.Id, Tower_Code__c = 'T1', Parking_Availability__c = true);
        
        Payment_Scheme__c paymentScheme = new Payment_Scheme__c(
            Name = 'Test Payment Scheme', 
            Company__c = company.Id, 
            Project__c = project.Id,
            Approval_Status__c = 'Approved',
            Block__c = tower1.Id
        );
        insert paymentScheme;
        

        Cost_Sheet_Template__c costSheetTemplate = new Cost_Sheet_Template__c(
            Name = 'Test Cost Sheet', 
            Company__c = company.Id, 
            Project__c = project.Id, 
            Template_Code__c = 'TEMPLATE1', 
            Approval_Status__c = 'Approved'
        );
        insert costSheetTemplate;
       
        Cost_Scheme_Linking__c costSchemeLinking = new Cost_Scheme_Linking__c(
            Payment_Scheme__c = paymentScheme.Id,
            Cost_Sheet_Template__c = costSheetTemplate.Id
        );
        insert costSchemeLinking;
        
        Payment_Schedule_Master__c psm = new Payment_Schedule_Master__c();
        psm.Name = 'test';
        insert psm;

        Scheme_Installment__c schemeInstallment = new Scheme_Installment__c(
            Cost_Scheme_Linking__c = costSchemeLinking.Id,
            Payment_Schedule_Master__c = psm.Id,
            Agreement_Value__c = 1000,
            Agreement_Tax__c = 100,
            Installment__c = 500
        );
        insert schemeInstallment;

        String costSheetIdNew = costSchemeLinking.Id;
        String paymentSchemeId = paymentScheme.Id;
        String costSheetId = costSheetTemplate.Id;
        String schemeId = costSchemeLinking.Id;
        
        Test.startTest();
        
        List<Scheme_Installment__c> result = PaymentSchemeCostSheetLinkingController.updateData(paymentSchemeId, costSheetId, schemeId, costSheetIdNew);
         List<Scheme_Installment__c> resultt = PaymentSchemeCostSheetLinkingController.updateData(paymentSchemeId, costSheetId, schemeId, null);
        Test.stopTest();
    }
}