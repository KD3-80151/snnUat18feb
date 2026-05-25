@isTest
private class costSheetTemplateControllerTest {

  
    @TestSetup
    static void setupTestData() {
    Company__c company = new Company__c(Name = 'Test Company');
    insert company;

    Project__c project = new Project__c(Name = 'Test Project', Company__c = company.Id, Active__c = true);
    insert project;

    Tower__c tower = new Tower__c(Name = 'Test Tower', Project__c = project.Id, Tower_Code__c = 'TT1');
    insert tower;

    Floor__c floor = new Floor__c(Blocks__c = tower.Id, Floor_No__c = 1);
    insert floor;

    Unit__c unit = new Unit__c(Floor__c = floor.Id, Unit_Name__c = 'U1', Status__c = 'For Sale');
    insert unit;

    Pricing_Element_Master__c pricingElement = new Pricing_Element_Master__c(
         Name = 'Test Pricing',
        Conversion_Unit__c = 'LS',
        Agreement__c = true
    );
    insert pricingElement;

    Tax_Master__c taxMaster = new Tax_Master__c(
        Name = 'Test Tax',
        Tax__c = 10.0,
        Tax_Type__c = 'SGST',
        Rounding_Method__c = 'No Rounding',
        Short_Name__c = 'test',
        Taxable__c = 2
    );
    insert taxMaster;

    Cost_Sheet_Template__c costSheetTemplate = new Cost_Sheet_Template__c(
        Name = 'Test Template',
        Template_Code__c = 'TEMP001',
        Company__c = company.Id,
        Project__c = project.Id,
        Active__c = true,
        Approval_Status__c = 'Pending'
    );
    insert costSheetTemplate;
        

    Cost_Unit_Linking__c costUnitLink = new Cost_Unit_Linking__c(
        Unit__c = unit.Id,
        Cost_Sheet_Template__c = costSheetTemplate.Id
    );
    insert costUnitLink;

    Cost_Pricing_Association__c costPricing = new Cost_Pricing_Association__c(
        Pricing_Element_Master__c = pricingElement.Id,
        Unit__c = 'LS',
        PE_Type__c = 'Formula',
        Quantity__c = 10,
        Rate__c = 100.0,
        Amount__c = 1000.0,
        Tax_Amount__c = 100.0,
        Cost_Sheet_Template__c = costSheetTemplate.Id
    );
    insert costPricing;

    Cost_Sheet_Tax_Linking__c taxLink = new Cost_Sheet_Tax_Linking__c(
        Tax_Master__c = taxMaster.Id,
        Cost_Pricing_Association__c = costPricing.Id,
        Amount__c = 100.0,
        App__c = 1
    );
    insert taxLink;

    // Call a real controller method (saveAllRecords) to initialize
    Cost_Sheet_Template__c template = [SELECT Id FROM Cost_Sheet_Template__c LIMIT 1];
    Unit__c unit1 = [SELECT Id FROM Unit__c LIMIT 1];
    Pricing_Element_Master__c pricingElement1 = [SELECT Id FROM Pricing_Element_Master__c LIMIT 1];
    Tax_Master__c taxMaster1 = [SELECT Id FROM Tax_Master__c LIMIT 1];

    List<Id> selectedUnitIds = new List<Id>{ unit.Id };

            List<Map<String, Object>> costPricingList = new List<Map<String, Object>>();
        Map<String, Object> pricingMap = new Map<String, Object>{
            'Pricing_Element_Master__c' => pricingElement1.Id,
            'Unit__c' => unit1.Id,
            'PE_Type__c' => 'Type1',
            'Quantity__c' => 10,
            'Rate__c' => 100.0,
            'Amount__c' => 1000.0,
            'Tax_Amount__c' => 100.0,
            'taxList' => new List<Map<String, Object>>{
                new Map<String, Object>{
                    'Id' => taxMaster1.Id,
                    'Amount__c' => 100.0,
                    'App__c' => 1
                }
            }
        };
        costPricingList.add(pricingMap);
        String jsonData = JSON.serialize(costPricingList);
       Boolean isNewCostPricingAsstn = false;
        Test.startTest();
        String result = CostSheetTemplateController.saveAllRecords(template.Id, template, selectedUnitIds, jsonData);
        CostSheetTemplateController.mytest();
        Test.stopTest();
    }


    @isTest
    static void testFetchPricingBasedonSearch() {
        Test.startTest();
        List<Pricing_Element_Master__c> pricingElements = CostSheetTemplateController.fetchPricingBasedonSearch('Test');
        Test.stopTest();
    }
   

    @isTest
    static void testCheckIfTemplateCodeExists() {
        Cost_Sheet_Template__c template = [SELECT Id, Template_Code__c FROM Cost_Sheet_Template__c LIMIT 1];
        Test.startTest();
        Boolean exists = CostSheetTemplateController.checkIfTemplateCodeExists(template.Template_Code__c);
        Test.stopTest();
    }

    @isTest
    static void testFetchExistingData() {
        Cost_Sheet_Template__c template = [SELECT Id FROM Cost_Sheet_Template__c LIMIT 1];
        Map<String, String> objectByField = new Map<String, String>{ 'PE_Type__c' => 'Cost_Pricing_Association__c' };
        Test.startTest();
        CostSheetTemplateController.existingDetailsWrapper result = CostSheetTemplateController.fetchExistingData(template.Id, objectByField);
        Test.stopTest();
    }

    @isTest
    static void testSaveAllRecords() {
       
    }

    @isTest
    static void testGetTowerFloorUnitPricingElementData() {
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        Test.startTest();
        CostSheetTemplateController.unitFloorTowerWrapper result = CostSheetTemplateController.getTowerFloorUnitPricingElementData(project.Id);
        Test.stopTest();
    }

    @isTest
    static void testGetCompanyDetails() {
        Test.startTest();
        List<Company__c> companies = CostSheetTemplateController.getCompanyDetails();
        Test.stopTest();
    }

    @isTest
    static void testFetchProjectAndPicklistDetails() {
        Company__c company = [SELECT Id FROM Company__c LIMIT 1];
        Map<String, String> objectByField = new Map<String, String>{ 'PE_Type__c' => 'Cost_Pricing_Association__c' };
        Test.startTest();
        CostSheetTemplateController.projectPicklistWrapper result = CostSheetTemplateController.fetchProjectAndPicklistDetails(company.Id, objectByField);
        Test.stopTest();
    }

    @isTest
    static void testFetchProjectRecords() {
        Company__c company = [SELECT Id FROM Company__c LIMIT 1];
        Test.startTest();
        List<Project__c> projects = CostSheetTemplateController.fetchProjectRecords(company.Id);
        Test.stopTest();
    }

    @isTest
    static void testGetAllPickListVal() {
        Map<String, String> objectByField = new Map<String, String>{ 'PE_Type__c' => 'Cost_Pricing_Association__c' };
        Test.startTest();
        Map<String, List<String>> result = CostSheetTemplateController.getAllPickListVal(objectByField);
        Test.stopTest();
    }

    @isTest
    static void testGetPicklistValues() {
        Test.startTest();
        List<String> result = CostSheetTemplateController.getPicklistValues('Cost_Pricing_Association__c', 'PE_Type__c');
        Test.stopTest();
    }
        @isTest
    static void testSaveNewTemplate() {
        Cost_Sheet_Template__c template = new Cost_Sheet_Template__c(
            Name = 'New Template',
            Template_Code__c = 'TEMP002',
            Company__c = [SELECT Id FROM Company__c LIMIT 1].Id,
            Project__c = [SELECT Id FROM Project__c LIMIT 1].Id
        );

        List<Id> unitIds = new List<Id>{[SELECT Id FROM Unit__c LIMIT 1].Id};

        List<Map<String, Object>> pricingAssociations = new List<Map<String, Object>>{
            new Map<String, Object>{
                'Pricing_Element_Master__c' => [SELECT Id FROM Pricing_Element_Master__c LIMIT 1].Id,
                'Unit__c' => unitIds[0],
                'Quantity__c' => 10,
                'Rate__c' => 100.00,
                'taxList' => new List<Map<String, Object>>{
                    new Map<String, Object>{
                        'Id' => [SELECT Id FROM Tax_Master__c LIMIT 1].Id,
                        'Amount__c' => 100.00
                    }
                }
            }
        };

        Test.startTest();
        String result = CostSheetTemplateController.saveAllRecords(
            null,
            template,
            unitIds,
            JSON.serialize(pricingAssociations)
        );
        Test.stopTest();
    }

    @isTest
    static void testUpdateExistingTemplate() {
        Cost_Sheet_Template__c template = [SELECT Id FROM Cost_Sheet_Template__c LIMIT 1];
        List<Id> unitIds = new List<Id>{[SELECT Id FROM Unit__c LIMIT 1].Id};

        List<Map<String, Object>> pricingAssociations = new List<Map<String, Object>>{
            new Map<String, Object>{
                'Pricing_Element_Master__c' => [SELECT Id FROM Pricing_Element_Master__c LIMIT 1].Id,
                'Unit__c' => unitIds[0],
                'Quantity__c' => 15,
                'Rate__c' => 150.00,
                'taxList' => new List<Map<String, Object>>{
                    new Map<String, Object>{
                        'Id' => [SELECT Id FROM Tax_Master__c LIMIT 1].Id,
                        'Amount__c' => 150.00
                    }
                }
            }
        };

        Test.startTest();
        String result = CostSheetTemplateController.saveAllRecords(
            template.Id,
            template,
            unitIds,
            JSON.serialize(pricingAssociations)
        );
        Test.stopTest();
    }

    @isTest
    static void testDeleteAssociations() {
        Cost_Sheet_Template__c template = [SELECT Id FROM Cost_Sheet_Template__c LIMIT 1];
        List<Id> unitIds = new List<Id>(); // Empty list to trigger deletions

        Test.startTest();
        String result = CostSheetTemplateController.saveAllRecords(
            template.Id,
            template,
            unitIds,
            JSON.serialize(new List<Map<String, Object>>())
        );
        Test.stopTest();
    }

    @isTest
    static void testExceptionHandling() {
        Test.startTest();
        String result = CostSheetTemplateController.saveAllRecords(
            null,
            new Cost_Sheet_Template__c(),
            new List<Id>(),
            'invalid json'
        );
        Test.stopTest();
    }

}