@isTest
public class GenerateSOAforDLTest {
    
    class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            if (req.getMethod() == 'POST') {
                res.setBody('{"id":"123456789"}');
                res.setStatusCode(200);
            } else {
                res.setBody('Dummy File Content');
                res.setStatusCode(200);
            }
            return res;
        }
    }
    
    @testSetup
    static void setupTestData() {
        Account acc = new Account(
            Name = 'Test Acc',
            Salutation__c = 'Mr'
        );
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        insert acc;
        
        Contact con = new Contact(
            AccountId = acc.Id,
            Salutation = 'Mr.',
            LastName = 'Test Con',
            Phone = '9988998899'
        );
        insert con;
        
        Company__c company = new Company__c(
            Name = 'Test',
            Registration_Number__c = 'yuthdkjq',
            Email__c = 'yghg@hjgh.com',
            Company_Code__c = 'hghx',
            Phone__c = '1234567890',
            GSTIN__c = 'yuthj'
        );
        insert company;
        
        Project__c project = new Project__c(
            Name = 'Test Project',
            Project_Description__c = 'test',
            Project_Start_Date__c = System.today(),
            Project_End_Date__c = System.today(),
            Project_Address__c = 'test',
            Project_Type__c = 'Commercial',
            Project_Code__c = 'test',
            Project_Status__c = 'test',
            Company__c = company.Id,
            Zone__c = 'East',
            City__c = 'Test',
            Total_Amount__c = 1111,
            Booking_Amount__c = 1111,
            Unit_Type__c = '3 BHK',
            Area__c = 'Test',
            Flat_Type__c = '3 BHK'
        );
        insert project;
        
        Cost_Sheet_Template__c costSheetTemp = new Cost_Sheet_Template__c(
            Name = 'Test Cost Sheet Template',
            Company__c = company.Id,
            Project__c = project.Id
        );
        insert costSheetTemp;
        
        Tower__c tower = new Tower__c(
            Name = 'Tower A',
            Tower_Code__c = 'TowerA'
        );
        insert tower;
        
        Floor__c floor = new Floor__c(
            Floor_No__c = 1,
            Blocks__c = tower.Id
        );
        insert floor;
        
        Unit__c unit = new Unit__c(
            Unit_Name__c = 'U1',
            Super_Built_Up_Area_sq_ft__c = 1000,
            Base_Price_per_sqft__c = 5000,
            Salable_Area__c = 1200.00,
            Floor__c = floor.Id,
            Carpet_Area__c = 800,
            Unit_Type__c = '3 BHK',
            Facing__c = 'West'
        );
        insert unit;
        
        Opportunity opp = new Opportunity(
            AccountId = acc.Id,
            Phone__c = '1234567890',
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Booking_Date__c = Date.today(),
            Cost_Sheet_Template__c = costSheetTemp.Id,
            Unit__c = unit.Id,
            Project__c = project.Id
        );
        insert opp;
        
        String uniqueSuffix = String.valueOf(DateTime.now().getTime());
        
        User managerUser = new User(
            FirstName = 'Manager',
            LastName = 'User',
            Email = 'manageruser@example.com',
            Username = 'manageruser' + uniqueSuffix + '@example.com.test',
            Alias = 'muser',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert managerUser;
        
        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser' + uniqueSuffix + '@example.com.test',
            Alias = 'tusr',
            ProfileId = managerUser.ProfileId,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ManagerId = managerUser.Id
        );
        insert u;
        
        Case cs = new Case(
            Subject = 'Test Case Subject',
            Status = 'New',
            Origin = 'Web',
            AccountId = acc.Id,
            ContactId = con.Id,
            Opportunity__c = opp.Id,
            OwnerId = u.Id
        );
        insert cs;
        
        insert new List<Applicant__c>{
            new Applicant__c(Opportunity__c = opp.Id, Account__c = acc.Id),
            new Applicant__c(Opportunity__c = opp.Id, Account__c = acc.Id),
            new Applicant__c(Opportunity__c = opp.Id, Account__c = acc.Id)
        };
        
        Payment_Schedule__c paymentSchedule1 = new Payment_Schedule__c(
            Opportunity__c = opp.Id,
            Name = 'Booking Amount Installment 1',
            Installment__c = 10,
            Agreement_Value__c = 50000,
            Tax_Amount__c = 500,
            Other_Charges__c = 200,
            Other_Tax_Amount__c = 300,
            Due_Date__c = Date.today().addDays(15),
            Total_Received_Amount__c = 10000,
            Demand_Letter_Sent__c = true
        );
        insert paymentSchedule1;
        
        Payment_Schedule__c paymentSchedule2 = new Payment_Schedule__c(
            Opportunity__c = opp.Id,
            Name = 'Agreement Installment 1',
            Installment__c = 15,
            Agreement_Value__c = 60000,
            Tax_Amount__c = 600,
            Other_Charges__c = 250,
            Other_Tax_Amount__c = 350,
            Total_Received_Amount__c = 5000,
            Debit_Payment_Schedule__c = true
        );
        insert paymentSchedule2;
        
        Demand_Letter__c demand1 = new Demand_Letter__c(Payment_Schedule__c = paymentSchedule1.Id);
        insert demand1;
        
        Demand_Letter__c demand2 = new Demand_Letter__c(Payment_Schedule__c = paymentSchedule2.Id);
        insert demand2;
        
        insert new SNN_Bank_Details__c(
            Name = 'SNN',
            Account_Number__c = '1234567890',
            Bank_Name__c = 'SNN',
            Branch__c = 'xyz',
            IFSC_Code__c = 'abc',
            Type_of_Account__c = 'mnop'
        );
        
        insert new List<Document__c>{
            new Document__c(Name = 'Demand Letters', Opportunity__c = opp.Id, Document_Id__c = 'DemandLetter'),
            new Document__c(Name = 'Cost Sheet', Opportunity__c = opp.Id, Document_Id__c = 'CostSheet'),
            new Document__c(Name = 'Receipts', Opportunity__c = opp.Id, Document_Id__c = 'Receipts'),
            new Document__c(Name = 'Post Sales', Opportunity__c = opp.Id, Document_Id__c = 'PostSalesDoc'),
            new Document__c(Name = 'Root Folder', Opportunity__c = opp.Id, Document_Id__c = 'RootFolderDoc')
        };
        
        Digio_Integration__c digi = new Digio_Integration__c(
            Name = 'Digio',
            Authorization__c = 'Bearer fake_token',
            Endpoint_URL__c = 'https://api.digio.in',
            Client_ID__c = 'fakeClientId',
            Client_Secret__c = 'fakeClientSecret',
            Statement_of_Accounts_Template_Key__c = 'soa_template_key',
            Statement_of_Account_Debit_Template_Key__c = 'soa_debit_template_key',
            Allotment_Letter_Template_Key__c = 'Allotment_Letter_Template_Key__c',
            Cost_Sheet_Template_Key__c = 'Cost_Sheet_Template_Key__c',
            Agreement_Copy_Key__c = 'Agreement_Copy_Key__c',
            Data_Sheet_Format_6__c = 'Data_Sheet_Format_6__c',
            Debit_Note_Template_Key__c = 'Debit_Note_Template_Key__c',
            Booking_Form_1__c = 'Booking_Form_1__c',
            Booking_Form_2__c = 'Booking_Form_2__c',
            Booking_Form_3__c = 'Booking_Form_3__c',
            Booking_Form_4__c = 'Booking_Form_4__c',
            Booking_Form_5__c = 'Booking_Form_5__c',
            Booking_Form_6__c = 'Booking_Form_6__c'
        );
        insert digi;
        
        Pricing_Element_Master__c pricingEleMaster = new Pricing_Element_Master__c(Name = 'Test Pricing');
        insert pricingEleMaster;
        
        Payment_Scheme__c paymentScheme = new Payment_Scheme__c(
            Company__c = company.Id,
            Block__c = tower.Id,
            Token_Amount__c = 1111,
            From_Date__c = System.today(),
            Name = 'Test',
            Project__c = project.Id,
            To_Date__c = System.today()
        );
        insert paymentScheme;
        
        insert new Cost_Scheme_Linking__c(
            Cost_Sheet_Template__c = costSheetTemp.Id,
            Payment_Scheme__c = paymentScheme.Id
        );
        
        Cost_Sheet__c costSheet = new Cost_Sheet__c(
            finalize_CostSheet__c = true,
            Opportunity__c = opp.Id,
            Unit__c = unit.Id
        );
        insert costSheet;
        
        insert new Pricing_Element__c(
            Amount__c = 1111,
            Cost_Sheet__c = costSheet.Id,
            Pricing_Element_Master__c = pricingEleMaster.Id,
            Rate__c = 1000,
            Discount_Amount__c = 10,
            Quantity__c = 10,
            parking_Element__c = true
        );
        
        insert new Cost_Pricing_Association__c(
            Amount__c = 1111,
            Pricing_Element_Master__c = pricingEleMaster.Id,
            Cost_Sheet_Template__c = costSheetTemp.Id
        );
        
        insert new List<Receipt__c>{
            new Receipt__c(
                Receipt_Date__c = System.today(),
                Amount__c = 1111,
                Transaction_Reference_Number__c = 'TXN001',
                Paid_Date__c = System.today(),
                Bank__c = 'SBI',
                Demand_Letter__c = demand1.Id,
                Opportunity__c = opp.Id,
                Mode_Of_Payment__c = 'Cheque',
                Cheque_Number__c = 'CHQ001',
                Cheque_Date__c = System.today(),
                Type__c = 'Tax Invoice',
                Approval_Status__c = 'Approved',
                Drawn_on_Bank__c = 'SBI'
            ),
            new Receipt__c(
                Receipt_Date__c = System.today(),
                Amount__c = 2000,
                Opportunity__c = opp.Id,
                Type__c = 'Credit',
                Description__c = 'Credit Note',
                Approval_Status__c = 'Approved'
            )
        };
    }
    
    @isTest
    static void testGenerateStatementOfAccounts() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        List<Payment_Schedule__c> psList = [
            SELECT Id
            FROM Payment_Schedule__c
            WHERE Opportunity__c = :testOpp.Id
        ];
        
        List<Id> selectedPaymentScheduleIds = new List<Id>();
        for (Payment_Schedule__c ps : psList) {
            selectedPaymentScheduleIds.add(ps.Id);
        }
        
        Test.startTest();
        GenerateSOAforDL.docwrpperClass result =
            GenerateSOAforDL.generateStatementOfAccounts(testOpp.Id, selectedPaymentScheduleIds);
        Test.stopTest();
        
    }
}