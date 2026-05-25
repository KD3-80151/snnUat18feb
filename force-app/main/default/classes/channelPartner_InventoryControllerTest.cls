@isTest
private class channelPartner_InventoryControllerTest {
    
    @testSetup
    static void setupData() {
        Company__c company = new Company__c(Name = 'TestCompany');
        insert company;
        
        Project__c project1 = new Project__c( Name = 'Project A',City__c = 'City A', Zone__c = 'East',  Company__c = company.Id );
        insert project1;
        
        Tower__c tower1 = new Tower__c(Name = 'Tower A', Project__c = project1.Id);
        insert tower1;
        
        Floor__c floor1 = new Floor__c(Blocks__c = tower1.Id, Floor_No__c = 2);
        insert floor1;
        
        Unit__c unit1 = new Unit__c(   Unit_Name__c = 'Unit-101', Status__c = 'For Sale',   Floor__c = floor1.Id,  Unit_Type__c = '2 BHK' );
        insert unit1;
    }

    @isTest
    static void testGetProjectDetails() {
        Test.startTest();
        List<Project__c> result = channelPartner_InventoryController.getProjectDetails();
        Test.stopTest();
        System.assertNotEquals(0, result.size(), 'Should return at least one project');
    }
    
    @isTest
    static void testGetAllPickListVal() {
        Map<String, String> objectByField = new Map<String, String>{
            'City__c' => 'Project__c'
        };
        Test.startTest();
        Map<String, List<String>> picklistResult = channelPartner_InventoryController.getAllPickListVal(objectByField);
        Test.stopTest();
        System.assert(picklistResult.containsKey('City__c'), 'Result must contain City__c picklist values');
    }
    
    @isTest
    static void testGetPicklistValues() {
        Test.startTest();
        List<String> picklistValues = channelPartner_InventoryController.getPicklistValues('Project__c', 'City__c');
        Test.stopTest();
        System.assertNotEquals(null, picklistValues, 'Picklist values should not be null');
    }
    
    @isTest
    static void testGetProjectDetailsBasedonSearch() {
        Project__c project1 = [SELECT Id, Name, City__c, Zone__c FROM Project__c LIMIT 1];
        Tower__c tower1 = [SELECT Name FROM Tower__c WHERE Project__c = :project1.Id LIMIT 1];
        Unit__c unit1 = [SELECT Unit_Type__c FROM Unit__c LIMIT 1];
        
        Test.startTest();
        channelPartner_InventoryController.SelectPropertiesWrappper wrapResult =
            channelPartner_InventoryController.getProjectDetailsBasedonSearch(
                project1.City__c,
                project1.Zone__c,
                project1.Name,
                unit1.Unit_Type__c,
                tower1.Name
            );
        Test.stopTest();
        System.assertNotEquals(null, wrapResult, 'Wrapper result should not be null');
        System.assertEquals(tower1.Name, wrapResult.defaultTowerName, 'Tower name should match');
        System.assertEquals(unit1.Unit_Type__c, wrapResult.defaultFlatType, 'Flat type should match');
    }
    
    @isTest
    static void testGetProjectDetailsBasedonSearch_NoMatch() {
        Test.startTest();
        channelPartner_InventoryController.SelectPropertiesWrappper wrapResult =
            channelPartner_InventoryController.getProjectDetailsBasedonSearch(
                'InvalidCity','InvalidZone','InvalidProject','2 BHK','InvalidTower'
            );
        Test.stopTest();
        System.assertEquals(null, wrapResult, 'Should return null when no project found');
    }

    @isTest
    static void testGetUnitRecord() {
        Unit__c unit1 = [SELECT Id FROM Unit__c LIMIT 1];
        Test.startTest();
        Unit__c result = channelPartner_InventoryController.getUnitRecord(unit1.Id);
        Test.stopTest();
        System.assertEquals(unit1.Id, result.Id, 'Fetched unit should match inserted one');
    }
}