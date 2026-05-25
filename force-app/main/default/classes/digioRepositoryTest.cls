@isTest
private class digioRepositoryTest {
    
    class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"id": "123456789"}');
            res.setStatusCode(200);
            return res;
        }
    }
    
    @testSetup
    static void setupTestData() {
        
        Account acc = new Account(Name = 'Test Acc', Salutation__c = 'Mr');
        acc.RecordTypeId = Schema.sObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        insert acc;
        
        Contact con = new Contact(AccountId = acc.Id, Salutation = 'Mr.', LastName = 'Test Con', Phone = '9988998899');
        insert con;
        
        Company__c company = new Company__c(Name = 'Test',Registration_Number__c= 'yuthdkjq',Email__c='yghg@hjgh.com', Company_Code__c = 'hghx', Phone__c = '1234567890',GSTIN__c = 'yuthj');
        insert company;
        Project__c project = new Project__c(Name = 'Test',Project_Description__c = 'test',Project_Start_Date__c=system.today(),Project_End_Date__c=system.today(),Project_Address__c='test',Project_Type__c='Commercial',Project_Code__c='test',Project_Status__c='test',Company__c=company.Id,
                                            Zone__c = 'East',City__c='Test',Total_Amount__c=1111,Booking_Amount__c=1111,Unit_Type__c='3 BHK',Area__c='Test',Flat_Type__c='3 BHK');
        insert project;
        Cost_Sheet_Template__c costSheetTemp = new Cost_Sheet_Template__c(Name = 'Test Cost Sheet Template',  Company__c = company.Id, Project__c = project.Id);
        insert costSheetTemp;
        
        
        Tower__c tower = new Tower__c(Tower_Code__c = 'TowerA');
        insert tower;
        
        Floor__c floor = new Floor__c(Floor_No__c = 1, Blocks__c = tower.Id);
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
            Unit__c = unit.Id
            
        );
        insert opp;
        
        opp.Unit__c = unit.Id;
        update opp;
        
        String uniqueSuffix = String.valueOf(DateTime.now().getTime());
        
        User managerUser = new User(
            FirstName = 'Manager',
            LastName = 'User',
            Email = 'manageruser@example.com',
            Username = 'manageruser' + uniqueSuffix + '@example.com.test',
            Alias = 'mgruser',
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
            Alias = 'tuser',
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
        
        
        Applicant__c applicant1 = new Applicant__c(Opportunity__c = opp.Id, Account__c = acc.Id);
        insert applicant1;
        Applicant__c applicant2 = new Applicant__c(Opportunity__c = opp.Id, Account__c = acc.Id);
        insert applicant2;
        Applicant__c applicant3 = new Applicant__c(Opportunity__c = opp.Id, Account__c = acc.Id);
        insert applicant3;
        Applicant__c applicant4 = new Applicant__c(Opportunity__c = opp.Id, Account__c = acc.Id);
        insert applicant4;
        Applicant__c applicant5 = new Applicant__c(Opportunity__c = opp.Id, Account__c = acc.Id);
        insert applicant5;
        // Applicant__c applicant6 = new Applicant__c(Opportunity__c = opp.Id, Account__c = acc.Id);
        // insert applicant6;
        
        Payment_Schedule__c paymentSchedule = new Payment_Schedule__c(
            Opportunity__c = opp.Id,
            Name = 'Booking Amount Installment 1',
            Installment__c = 10,
            Agreement_Value__c = 50000,
            Tax_Amount__c = 500,
            Other_Charges__c = 200,
            Other_Tax_Amount__c = 300,
            Due_Date__c = Date.today().addDays(15)
        );
        insert paymentSchedule;
        
        
        Payment_Schedule__c paymentScheduleAgreement = new Payment_Schedule__c(
            Opportunity__c = opp.Id,
            Name = 'Agreement Installment 1',
            Installment__c = 10,
            Agreement_Value__c = 50000,
            Tax_Amount__c = 500,
            Other_Charges__c = 200,
            Other_Tax_Amount__c = 300
        );
        insert paymentScheduleAgreement;
        
        Payment_Schedule__c paymentScheduleAmenities = new Payment_Schedule__c(
            Opportunity__c = opp.Id,
            Name = 'Amn Installment 1',
            Other_Charges__c = 200,
            Other_Tax_Amount__c = 300
        );
        insert paymentScheduleAmenities;
        
        
        Demand_Letter__c demand = new Demand_Letter__c(Payment_Schedule__c = paymentSchedule.Id);
        insert demand;
        
        Demand_Letter__c demand2 = new Demand_Letter__c(
            Payment_Schedule__c = paymentScheduleAgreement.Id
        );
        insert demand2;
        
        SNN_Bank_Details__c bank = new SNN_Bank_Details__c(
            Name = 'SNN',
            Account_Number__c = '1234567890',
            Bank_Name__c = 'SNN',
            Branch__c = 'xyz',
            IFSC_Code__c = 'abc',
            Type_of_Account__c = 'mnop'
        );
        insert bank;
        
        Document__c demandLetterDocument = new Document__c(
            Name = 'Demand Letters',
            Opportunity__c = opp.Id,
            Document_Id__c = 'DemandLetter'
        );
        insert demandLetterDocument;
        
        Document__c CostSheetDoc = new Document__c(
            Name = 'Cost Sheet',
            Opportunity__c = opp.Id,
            Document_Id__c = 'Cost Sheet'
        );
        insert CostSheetDoc;
        
        Document__c ReceiptsDoc = new Document__c(
            Name = 'Receipts',
            Opportunity__c = opp.Id,
            Document_Id__c = 'Receipts'
        );
        insert ReceiptsDoc;

        Document__c postSalesDoc = new Document__c(
            Name = 'Post Sales',
            Opportunity__c = opp.Id,
            Document_Id__c = 'PostSalesDoc'
        );
        insert postSalesDoc;
        
        Document__c rootFolderDoc = new Document__c(
            Name = 'Root Folder',
            Opportunity__c = opp.Id,
            Document_Id__c = 'RootFolderDoc'
        );
        insert rootFolderDoc;
        
        Document__c salesDoc = new Document__c(
            Name = 'Sales',
            Opportunity__c = opp.Id,
            Document_Id__c = 'SalesDoc'
        );
        insert salesDoc;
        
        Document__c exceDoc = new Document__c(
            Name = 'Exception Process',
            Opportunity__c = opp.Id,
            Document_Id__c = 'ExceptionProcessDoc'
        );
        insert exceDoc;
        
        Document__c AllotmentLetter = new Document__c(
            Name = 'Allotment Letter',
            Opportunity__c = opp.Id,
            Document_Id__c = 'AllotmentLetter'
        );
        insert AllotmentLetter;
        
        Document__c document = new Document__c(
            Name = 'HandOver Checklist',
            Opportunity__c = opp.Id,
            Document_Id__c = '12345'
        );
        insert document;
        Document__c paymentdocument = new Document__c(
            Name = 'Payment Receipts',
            Opportunity__c = opp.Id,
            Document_Id__c = 'PaymentReceipts'
        );
        insert paymentdocument;
        
        Digio_Integration__c digi = new Digio_Integration__c(
            Name = 'Digio',
            Authorization__c = 'Bearer fake_token',
            Endpoint_URL__c = 'https://api.digio.in',
            Allotment_Letter_Template_Key__c = 'Allotment_Letter_Template_Key__c',
            Cost_Sheet_Template_Key__c = 'Cost_Sheet_Template_Key__c',
            Agreement_Copy_Key__c = 'Agreement_Copy_Key__c',
            Data_Sheet_Format_6__c = 'Data_Sheet_Format_6__c',
            Debit_Note_Template_Key__c = 'Debit_Note_Template_Key__c'
        );
        insert digi;
                
        Pricing_Element_Master__c pricingEleMaster = new Pricing_Element_Master__c(Name = 'Test Pricing');
        insert pricingEleMaster;
        
        Payment_Scheme__c paymentScheme = new Payment_Scheme__c(Company__c = company.Id,Block__c =tower.Id,Token_Amount__c = 1111, From_Date__c= system.today(),Name = 'Test',Project__c = project.Id,To_Date__c=system.today());
        insert paymentScheme;
        
        Cost_Scheme_Linking__c costScheme = new Cost_Scheme_Linking__c(Cost_Sheet_Template__c = costSheetTemp.Id,Payment_Scheme__c = paymentScheme.Id);
        insert costScheme;
        
        Cost_Sheet__c costSheet = new Cost_Sheet__c(
            finalize_CostSheet__c = true,
            Opportunity__c = opp.Id,
            Unit__c = unit.Id
        );
        insert costSheet;
        
        Pricing_Element__c pricing = new Pricing_Element__c(
            Amount__c = 1111,
            Cost_Sheet__c = costSheet.Id,
            Pricing_Element_Master__c = pricingEleMaster.Id,
            Rate__c = 1000,
            Discount_Amount__c  = 10, 
            Quantity__c =10,
            parking_Element__c = true
        );
        insert pricing;
        
        Cost_Pricing_Association__c costPricing = new Cost_Pricing_Association__c(Amount__c = 1111, Pricing_Element_Master__c = pricingEleMaster.Id, Cost_Sheet_Template__c = costSheetTemp.Id);
        insert costPricing;
        
        Receipt__c receipt = new Receipt__c(Receipt_Date__c = system.today(), Amount__c = 1111, Transaction_Reference_Number__c = 'gewhcjweh',Paid_Date__c = System.today(), Bank__c = 'SBI', Demand_Letter__c = demand.Id,Opportunity__c =opp.Id,Mode_Of_Payment__c='Cheque',Cheque_Number__c ='hiufgfgf');
        insert receipt;
        
        Receipt__c receipt2 = new Receipt__c(
            Receipt_Date__c = Date.today(),
            Amount__c = 12345,
            Transaction_Reference_Number__c = 'TXN-9876',
            Paid_Date__c = Date.today(),
            Bank__c = 'ICICI',
            Demand_Letter__c = demand2.Id,
            Opportunity__c = opp.Id
        );
        insert receipt2;
        
        Receipt__c receipt3 = new Receipt__c(
        	Debit_Note_Reminder_Sent__c = false,
            Opportunity__c = opp.Id,
            Type__c = 'Debit',
            Description__c = 'Debit',
            Amount__c = 2000
        );
        insert receipt3;
    }
    
    @isTest
    static void testGetCostSheets() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        List<Cost_Sheet__c> costSheets = digioRepository.getCostSheets(testOpp.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, costSheets);
        System.assert(!costSheets.isEmpty(), 'Expected at least one cost sheet record');
    }
    
    @isTest
    static void testcheckAlreadyGenerated() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        digioRepository.checkAlreadyGenerated(testOpp.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testgenerateAgreementCopyDoc() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        digioRepository.generateAgreementCopyDoc(testOpp.Id);
        Test.stopTest();
    }

    @isTest
    static void testgenerateDataSheetFormatDoc() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        digioRepository.docwrpperClass result = digioRepository.generateDataSheetFormatDoc(testOpp.Id);
        Test.stopTest();
    }

    @isTest
    static void testgenerateAllotmentLetter() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        digioRepository.docwrpperClass result = digioRepository.generateAllotmentLetter(testOpp.Id);
        Test.stopTest();
    }

    @isTest
    static void testgenerateWelcomeKit() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        digioRepository.docwrpperClass result = digioRepository.generateWelcomeKit(testOpp.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testgenerateSnnHomeOwner() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        digioRepository.docwrpperClass result = digioRepository.generateSnnHomeOwner(testOpp.Id);
        Test.stopTest();
    }

    @isTest
    static void testsaleAndConstructionAgreement() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        digioRepository.docwrpperClass result = digioRepository.saleAndConstructionAgreement(testOpp.Id);
        Test.stopTest();
    }

    @isTest
    static void testgenerateCostSheet() {
        Cost_Sheet__c cs = [SELECT Id FROM Cost_Sheet__c LIMIT 1];
        Test.startTest();
        digioRepository.docwrpperClass result1 = digioRepository.generateCostSheet(cs.Id);
        digioRepository.docwrpperClass result2 = digioRepository.generateCostSheet('cs.Id');
        Test.stopTest();
    }

    @isTest
    static void testgenerateSerenityReceipt() {
        Receipt__c receipt = [SELECT Id FROM Receipt__c LIMIT 1];
        Test.startTest();
        digioRepository.docwrpperClass result = digioRepository.generateSerenityReceipt(receipt.Id);
        Test.stopTest();
    }

    @isTest
    static void testgenerateDemandLetter() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        digioRepository.docwrpperClass result = digioRepository.generateDemandLetter(testOpp.Id);
        Test.stopTest();
    }

    @isTest
    static void testgenerateDebitNoteWrapper() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        List<Payment_Schedule__c> psList = [
            SELECT Id, Name
            FROM Payment_Schedule__c
            WHERE Opportunity__c = :testOpp.Id
        ];
        List<String> psIds = new List<String>();
        for(Payment_Schedule__c ps : psList) {
            psIds.add(ps.Id);
        }
        Test.startTest();
        digioRepository.generateDebitNoteWrapper(psIds);
        Test.stopTest();
    }

    @isTest
    static void testGenerateStatementOfAccounts() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        List<Payment_Schedule__c> psList = [
            SELECT Id, Name,
            (SELECT Id FROM Demand_Letters__r)
            FROM Payment_Schedule__c
            WHERE Opportunity__c = :testOpp.Id
        ];
        
        System.debug('--- PS List Size: ' + psList.size());
        
        //Receipt__c rec = [SELECT Id FROM Receipt__c WHERE Opportunity__c = :testOpp.Id LIMIT 1];
        Test.startTest();
        digioRepository.docwrpperClass result = digioRepository.generateStatementOfAccounts(testOpp.Id);
        Test.stopTest();
        //System.assert(true, 'No exception should occur');
    }
    
    @isTest
    static void testSendigioDetails() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        Receipt__c rec = [SELECT Id FROM Receipt__c WHERE Opportunity__c = :testOpp.Id LIMIT 1];
        Test.startTest();
        digioRepository.sendigiodetails('dummyDocId', testOpp.Id, 'Test Doc');
        Test.stopTest();
    }
    
    @isTest
    static void testSendigioDetails1() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        Receipt__c rec = [SELECT Id FROM Receipt__c WHERE Opportunity__c = :testOpp.Id LIMIT 1];
        Test.startTest();
        digioRepository.sendigiodetails1('dummyDocId', testOpp.Id, 'Test Doc');
        Test.stopTest();
    }
    
}