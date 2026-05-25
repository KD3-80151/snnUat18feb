@isTest
public class CostSheetGenerationControllerTest {
    private static User createTestUser() {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser' + DateTime.now().getTime() + '@example.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = profile.Id
        );
        insert testUser;
        return testUser;
    }
    
    private static Opportunity createTestOpportunity() {
        
        User owner = createTestUser();
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Qualification',
            CloseDate = Date.today().addMonths(1),
            OwnerId = owner.Id
        );
        insert opp;
        return opp;
    }
    
    private static Unit__c createTestUnit() {
        Unit__c unit = new Unit__c(
            
            Status__c = 'For Sale'
        );
        insert unit;
        return unit;
    }
    
    private static Cost_Sheet_Template__c createTestCostSheetTemplate() {
        Company__c compRec = new Company__c(
            Name = 'TestComp',
            Email__c = 'test@gmail.com',
            Registration_Number__c = 'anbxbn1232',
            Company_Code__c = 'XYZ',
            Phone__c = '8989786756'
        );
        insert compRec;
        
        Project__c proRec = new Project__c(
            Name = 'Test',
            Project_Start_Date__c = Date.today(),
            Project_End_Date__c = Date.today(),
            Project_Description__c = 'sfdfd',
            Project_Address__c = 'dfsdf',
            Booking_Amount__c = 1000,
            Project_Status__c = 'Planning',
            Project_Type__c = 'Residential',
            Project_Code__c = 'sfsd',
            Zone__c = 'East',
            City__c = 'Bhopal',
            Unit_Type__c = '3 BHK',
            Total_Amount__c = 199000,
            Company__c = compRec.Id
        );
        insert proRec;
        
        Cost_Sheet_Template__c costSheetTemplate = new Cost_Sheet_Template__c(
            Company__c = compRec.Id,
            Project__c = proRec.Id
        );
        insert costSheetTemplate;
        return costSheetTemplate;
    }
    
    @isTest
    static void testGetOnLoadDataWithTaskRecordId() {
    // Create required data
    Opportunity testOpportunity = createTestOpportunity();
    Unit__c testUnit = createTestUnit();
    Cost_Sheet_Template__c testTemplate = createTestCostSheetTemplate();

    Tax_Details__c testData = new Tax_Details__c(
        Name = 'Tax Details',
        CGST__c = 2.50,
        SGST__c = 2.50
    );
    insert testData;

    // Create a Task associated with the Opportunity
    Task testTask = new Task(
        Subject = 'Finalise Cost Sheet & Generate Payment Schedule',
        WhatId = testOpportunity.Id,
        Status = 'Open',
        ActivityDate = Date.today().addDays(2)
    );
    insert testTask;

    Test.startTest();
    // Pass Task Id to hit the `if(recordId.startsWith('00T'))` block
    CostSheetGenerationController.fetchDataWrapper result = 
        CostSheetGenerationController.getOnLoadData(testTask.Id);
    Test.stopTest();

    }
    
    @isTest
static void testCreateCostSheet_FullCoverage() {
    // Setup user, opportunity, and unit with necessary fields
    Opportunity testOpportunity = createTestOpportunity();

    Unit__c testUnit = new Unit__c(
        
        Super_Built_Up_Area_sq_ft__c = 1000,
        Floor_Rise__c = 40,
        Base_Price_per_sqft__c = 2000
    );
    insert testUnit;

    // Create supporting company and project
    Company__c comp = new Company__c(
        Name = 'Test Company',
        Email__c = 'email@test.com',
        Phone__c = '1234567890',
        Registration_Number__c = 'REG123',
        Company_Code__c = 'TCODE'
    );
    insert comp;

    Project__c proj = new Project__c(
        Name = 'Test Project',
        Project_Code__c = 'PCODE',
        Project_Status__c = 'Planning',
        Project_Start_Date__c = Date.today(),
        Project_End_Date__c = Date.today().addMonths(6),
        Company__c = comp.Id
    );
    insert proj;

    // Link opportunity to project
    testOpportunity.Project__c = proj.Id;
    update testOpportunity;

    Cost_Sheet_Template__c template = new Cost_Sheet_Template__c(
        Name = 'Template 1',
        Company__c = comp.Id,
        Project__c = proj.Id
    );
    insert template;

    Cost_Scheme_Linking__c schemeLinking = new Cost_Scheme_Linking__c(
        Cost_Sheet_Template__c = template.Id
    );
    insert schemeLinking;

    // Insert PEMs for all condition types
    List<Pricing_Element_Master__c> pems = new List<Pricing_Element_Master__c>{
        new Pricing_Element_Master__c(Name = 'Corner Charges'),
        new Pricing_Element_Master__c(Name = 'Floor Rise'),
        new Pricing_Element_Master__c(Name = 'Facing Charges'),
        new Pricing_Element_Master__c(Name = 'Basic Price')
    };
    insert pems;

    // Insert CPAs for all PEMs
    List<Cost_Pricing_Association__c> cpas = new List<Cost_Pricing_Association__c>();
    for (Pricing_Element_Master__c pem : pems) {
        cpas.add(new Cost_Pricing_Association__c(
            Cost_Sheet_Template__c = template.Id,
            Pricing_Element_Master__c = pem.Id,
            Unit__c = 'sqft',
            Rate__c = 10
        ));
    }
    insert cpas;

    // Insert Tax Masters
    List<Tax_Master__c> taxes = new List<Tax_Master__c>{
        new Tax_Master__c(Name = 'SGST', Tax_Type__c = 'SGST', Tax__c = 9, Short_Name__c = 'asda',Taxable__c = 2),
        new Tax_Master__c(Name = 'CGST', Tax_Type__c = 'CGST', Tax__c = 9, Short_Name__c = 'hgf',Taxable__c = 3),
        new Tax_Master__c(Name = 'IGST', Tax_Type__c = 'IGST', Tax__c = 18, Short_Name__c = 'gfdc',Taxable__c = 2)
    };
    insert taxes;

    // Link taxes to CPA
    List<Cost_Sheet_Tax_Linking__c> taxLinks = new List<Cost_Sheet_Tax_Linking__c>();
    for (Integer i = 0; i < 3; i++) {
        taxLinks.add(new Cost_Sheet_Tax_Linking__c(
            Cost_Pricing_Association__c = cpas[0].Id, // attach to at least one CPA
            Tax_Master__c = taxes[i].Id
        ));
    }
    insert taxLinks;

    // Create a dummy task that gets completed
    Task t = new Task(
        Subject = 'Generate Cost Sheet',
        WhatId = testOpportunity.Id,
        Status = 'Not Started'
    );
    insert t;

    List<Task> tasks = new List<Task>{ t };

    Test.startTest();
    String result = CostSheetGenerationController.createCostSheet(
        testOpportunity,
        tasks,
        testUnit.Id,
        schemeLinking.Id
    );
    Test.stopTest();

    System.assertNotEquals(null, result);
}

    
    @isTest
    static void testCheckAccess() {
        Opportunity testOpportunity = createTestOpportunity();
          Company__c company = new Company__c(Name = 'Test Company');
         insert company;

        Project__c project = new Project__c(
            Name = 'Test Project',
            Company__c = company.Id, Active__c = true,
            Role__c = 'Sales Executive'
        );
        insert project;
        
        Project_Roles__c projectRole = new Project_Roles__c(
            
            Role__c = 'Sales Executive',
            Project__c = project.id
            
        );
        insert projectRole;
        
        testOpportunity.Project__c = project.Id;
        testOpportunity.StageName =  'Cost Sheet Generated';
        update testOpportunity;
        
        Discount_Master__c discountMaster = new Discount_Master__c(
            Project__c = project.Id,
            Active__c = true
        );
        insert discountMaster;
        
        Discount_LineItem__c discountLineItem = new Discount_LineItem__c(
            Discount_Master__c = discountMaster.Id,
            Minimum__c = 10,
            Maximum__c = 50,
            Roles__c = 'Sales Executive'
        );
        insert discountLineItem;
        
        Test.startTest();
        List<Discount_LineItem__c> result = CostSheetGenerationController.checkAccess(testOpportunity.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testGetPricingElements() {
        
        Opportunity testOpportunity = createTestOpportunity();
        Unit__c testUnit = createTestUnit();
        Cost_Sheet_Template__c testTemplate = createTestCostSheetTemplate();
        
        Cost_Sheet__c costSheet = new Cost_Sheet__c(
            Opportunity__c = testOpportunity.Id,
            Cost_Scheme_Linking__c = null,
            Unit__c = testUnit.Id
        );
        insert costSheet;
        List<Pricing_Element__c> lisrPricin = new  List<Pricing_Element__c> ();
        Pricing_Element__c pricingElement = new Pricing_Element__c(
            Cost_Sheet__c = costSheet.Id,
            Amount__c = 100
        );
        insert pricingElement;
        lisrPricin.add(pricingElement);
        
        Test.startTest();
        List<Pricing_Element__c> result = CostSheetGenerationController.getPricingElements(costSheet.Id);
        CostSheetGenerationController.updatePricingElements(lisrPricin);
        
        Test.stopTest();
        
    }
    
      @isTest
    static void testGetDecimalValue() {
        Decimal result1 = CostSheetGenerationController.getDecimalValue(null);       

        Decimal expectedDecimal = 100.25;
        Decimal result2 = CostSheetGenerationController.getDecimalValue(expectedDecimal);


        Decimal result3 = CostSheetGenerationController.getDecimalValue('250.75');

        Decimal result4 = CostSheetGenerationController.getDecimalValue('invalidNumber');

        Decimal result5 = CostSheetGenerationController.getDecimalValue('500');

    }
    
      @isTest
    static void testGetIntegerValue() {
        Integer result1 = CostSheetGenerationController.getIntegerValue(null);

        Decimal expectedDecimal = 100.25;
        Integer result2 = CostSheetGenerationController.getIntegerValue(expectedDecimal);
        Integer result3 = CostSheetGenerationController.getIntegerValue('250');
        Integer result4 = CostSheetGenerationController.getIntegerValue('invalidNumber');
        Integer result5 = CostSheetGenerationController.getIntegerValue('500');
    }
    
    @isTest
    static void testCreateParkingElements() {
        
        Opportunity testOpportunity = createTestOpportunity();
        Unit__c testUnit = createTestUnit();
        Cost_Sheet_Template__c testTemplate = createTestCostSheetTemplate();
        
        Cost_Sheet__c costSheet = new Cost_Sheet__c(
            Opportunity__c = testOpportunity.Id,
            Unit__c = testUnit.Id
        );
        insert costSheet;
        Pricing_Element_Master__c test1 = new Pricing_Element_Master__c(
            Name = 'Some',
            Parking_Type__c = 'Dependent'
        );
        insert test1;
        Map<String, Object> parkingElement = new Map<String, Object>();
        parkingElement.put('type', 'Dependent');
        parkingElement.put('amount', 200);
        parkingElement.put('Parking_Numbers__c', 20);
        
        
        List<Map<String, Object>> parkingElements = new List<Map<String, Object>>();
        parkingElements.add(parkingElement);
        
        Test.startTest();
        List<Pricing_Element__c> result = CostSheetGenerationController.createparkingElements(parkingElements, costSheet.Id);
        Test.stopTest();
    }
   @isTest
static void testGetDecimalValueInvalid() {
    Test.startTest();
    Decimal d = CostSheetGenerationController.getDecimalValue('NotANumber');
    Test.stopTest();
}
    @isTest
    static void testSubmitCostSheetForApprovalMethod() {
         Company__c company = new Company__c(Name = 'Test Company');
         insert company;

         Project__c testProject = new Project__c(Name = 'Test', Company__c = company.Id, Active__c = true);
         insert testProject;
        
        Project_Roles__c projectRole = new Project_Roles__c(
            
            Role__c = 'Sales Executive',
            Project__c = testProject.id
            
        );
        insert projectRole;
        
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = System.today().addDays(30),
            Project__c = testProject.Id
        );
        insert testOpportunity;
        
        Cost_Sheet__c testCostSheet = new Cost_Sheet__c(
            Opportunity__c = testOpportunity.Id,
            finalize_CostSheet__c = false
        );
        insert testCostSheet;
        
        Pricing_Element_Master__c pricingElement1 = new Pricing_Element_Master__c(Name = 'Pricing Element 1');
        Pricing_Element_Master__c pricingElement2 = new Pricing_Element_Master__c(Name = 'Pricing Element 2');
        insert new List<Pricing_Element_Master__c>{pricingElement1, pricingElement2};
            
            Discount_Master__c discountMaster = new Discount_Master__c(
                Project__c = testProject.Id,
                Active__c = true,
                Pricing_Element_Master__c = pricingElement1.Id
            );
        insert discountMaster;
        
        Discount_LineItem__c discountLine1 = new Discount_LineItem__c(
            Discount_Master__c = discountMaster.Id,
            Minimum__c = 100,
            Maximum__c = 500,
            Roles__c = 'Sales Executive'
        );
        Discount_LineItem__c discountLine2 = new Discount_LineItem__c(
            Discount_Master__c = discountMaster.Id,
            Minimum__c = 501,
            Maximum__c = 1000,
            Roles__c = 'Sales Executive'
        );
        insert new List<Discount_LineItem__c>{discountLine1, discountLine2};
            
            String discountData = '[{"discountAmount":"200","id":"' + pricingElement1.Id + '"},{"discountAmount":"800","id":"' + pricingElement2.Id + '"}]';
        String costSheetId = testCostSheet.Id;
        
        Unit__c unit = new Unit__c(
            
            Status__c = 'Booked'
        );
        insert unit;       
        
        Test.startTest();
        CostSheetGenerationController.submitCostSheetForApproval(discountData, costSheetId);
        CostSheetGenerationController.getParkingRecords( unit.Id);
        CostSheetGenerationController.getUnitRecord( unit.Id);
         //  CostSheetGenerationController.testData();
        Test.stopTest();
        
        Cost_Sheet__c updatedCostSheet = [
            SELECT Id, Highest_Approver__c FROM Cost_Sheet__c WHERE Id = :costSheetId
        ];
        
    }
}