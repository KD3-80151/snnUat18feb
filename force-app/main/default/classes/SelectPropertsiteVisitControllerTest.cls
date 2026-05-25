@IsTest
public class SelectPropertsiteVisitControllerTest {

    @testSetup
    static void setupData() {
        // Company
        Company__c company = new Company__c(Name = 'Test Company');
        insert company;

        // Project
        Project__c project = new Project__c(
            Name       = 'Test Project',
            Company__c = company.Id,
            Active__c  = true,
            City__c    = 'Bangalore',
            Zone__c    = 'East'
        );
        insert project;

        // Tower
        Tower__c tower = new Tower__c(
            Name        = 'Test Tower',
            Tower_Code__c = 'T1',
            Project__c  = project.Id
        );
        insert tower;

        // Floor
        Floor__c floor = new Floor__c(
            Blocks__c             = tower.Id,
            Floor_No__c           = 1,
            Construction_Status__c = 'Completed'
        );
        insert floor;

        // Units – one for each status path in the controller
        List<Unit__c> units = new List<Unit__c>{
            new Unit__c(
                Unit_Name__c = 'Unit 1',
                Status__c    = 'For Sale',
                Floor__c     = floor.Id,
                Unit_Type__c = '3 BHK'
            ),
            new Unit__c(
                Unit_Name__c = 'Unit 2',
                Status__c    = 'Sold',
                Floor__c     = floor.Id,
                Unit_Type__c = '3 BHK'
            ),
            new Unit__c(
                Unit_Name__c = 'Unit 3',
                Status__c    = 'Management Blocked',
                Floor__c     = floor.Id,
                Unit_Type__c = '3 BHK'
            ),
            new Unit__c(
                Unit_Name__c = 'Unit 4',
                Status__c    = 'Booked',
                Floor__c     = floor.Id,
                Unit_Type__c = '3 BHK'
            ),
            new Unit__c(
                Unit_Name__c = 'Unit 5',
                Status__c    = 'Awaiting Payment Confirmation',
                Floor__c     = floor.Id,
                Unit_Type__c = '3 BHK'
            )
        };
        insert units;
    }

    @IsTest
    static void testGetProjectDetails_NotEmpty() {
        Test.startTest();
        List<Project__c> projectList = SelectPropertsiteVisitController.getProjectDetails();
        Test.stopTest();

        System.assertNotEquals(null, projectList, 'Projects list should not be null');
        System.assert(projectList.size() > 0, 'Projects should be returned');
    }

    @IsTest
    static void testGetProjectDetails_EmptyReturnsNull() {
        // Remove all projects for this test context
        delete [SELECT Id FROM Project__c];

        Test.startTest();
        List<Project__c> projectList = SelectPropertsiteVisitController.getProjectDetails();
        Test.stopTest();

        System.assertEquals(null, projectList, 'When no projects, method should return null');
    }

    @IsTest
    static void testGetPicklistValues() {
        Test.startTest();
        List<String> picklistValues =
            SelectPropertsiteVisitController.getPicklistValues('Unit__c', 'Unit_Type__c');
        Test.stopTest();

        System.assert(picklistValues != null && !picklistValues.isEmpty(),
                      'Picklist values should be returned');
    }

    @IsTest
    static void testGetAllPickListVal() {
        Map<String, String> inputMap = new Map<String, String>{
            'Unit_Type__c' => 'Unit__c'
        };

        Test.startTest();
        Map<String, List<String>> result =
            SelectPropertsiteVisitController.getAllPickListVal(inputMap);
        Test.stopTest();

    }

    @IsTest
    static void testGetTowersByProject_BlankName() {
        Test.startTest();
        List<String> towers = SelectPropertsiteVisitController.getTowersByProject('');
        Test.stopTest();

        System.assertNotEquals(null, towers, 'Towers list should not be null');
        System.assertEquals(0, towers.size(),
                            'Blank project name should return empty list');
    }

    @IsTest
    static void testGetTowersByProject_ValidName() {
        Project__c proj = [SELECT Id, Name FROM Project__c LIMIT 1];

        Test.startTest();
        List<String> towers =
            SelectPropertsiteVisitController.getTowersByProject(proj.Name);
        Test.stopTest();

        System.assertNotEquals(null, towers, 'Towers list should not be null');
        System.assertEquals(1, towers.size(), 'There should be one tower for test data');
        System.assertEquals('T1', towers[0], 'Tower code should match test data');
    }

    @IsTest
    static void testGetProjectDetailsBasedonSearch_WithUnitType() {
        Project__c proj = [SELECT Id, Name FROM Project__c LIMIT 1];

        Test.startTest();
        SelectPropertsiteVisitController.SelectPropertiesWrappper wrap =
            SelectPropertsiteVisitController.getProjectDetailsBasedonSearch(
                null,                 // FlatBhkId
                proj.Name,            // projectName
                'T1',                 // towerName
                '3 BHK'               // unitType
            );
        Test.stopTest();

        System.assertNotEquals(null, wrap, 'Wrapper should not be null for valid data');
        System.assertEquals('T1', wrap.defaultTowerName, 'Default tower should be T1');
        System.assertEquals('3 BHK', wrap.defaultFlatType, 'Default flat type should be 3 BHK');
        System.assertEquals(5, wrap.getUnitRecordBasedOnProjectList.size(),
                            'All units of 3 BHK in this tower should be returned');

        System.assertEquals(1, wrap.AvailableforSale, 'For Sale count mismatch');
        System.assertEquals(1, wrap.Sold, 'Sold count mismatch');
        System.assertEquals(1, wrap.ManagementBlocked, 'Management Blocked count mismatch');
        System.assertEquals(1, wrap.Blocked_ForFire_SafetyClearance,
                            'Booked count mismatch');
        System.assertEquals(1, wrap.AwaitingPaymentConfirmation,
                            'Awaiting Payment Confirmation count mismatch');

        System.assert(wrap.FloorwithunitMapDetails != null &&
                      !wrap.FloorwithunitMapDetails.isEmpty(),
                      'Floor-with-unit map should be populated');
    }

    @IsTest
    static void testGetProjectDetailsBasedonSearch_DefaultTower_NoUnitType() {
        Project__c proj = [SELECT Id, Name FROM Project__c LIMIT 1];

        Test.startTest();
        // towerName is blank so method should use first tower from picklist as default
        SelectPropertsiteVisitController.SelectPropertiesWrappper wrap =
            SelectPropertsiteVisitController.getProjectDetailsBasedonSearch(
                null,           // FlatBhkId
                proj.Name,      // projectName
                null,           // towerName (blank -> default)
                null            // unitType
            );
        Test.stopTest();

        System.assertNotEquals(null, wrap, 'Wrapper should not be null');
        System.assertEquals('T1', wrap.defaultTowerName,
                            'Default tower should be picked from towerPicklist');
        System.assertEquals(5, wrap.getUnitRecordBasedOnProjectList.size(),
                            'All units for that tower should be returned when unitType is null');
    }

    @IsTest
    static void testGetProjectDetailsBasedonSearch_BlankProject() {
        Test.startTest();
        SelectPropertsiteVisitController.SelectPropertiesWrappper wrap =
            SelectPropertsiteVisitController.getProjectDetailsBasedonSearch(
                null,   // FlatBhkId
                null,   // projectName
                'T1',   // towerName
                '3 BHK' // unitType
            );
        Test.stopTest();

        System.assertEquals(null, wrap,
                            'Blank project name should return null immediately');
    }

    @IsTest
    static void testGetProjectDetailsBasedonSearch_InvalidProject() {
        Test.startTest();
        SelectPropertsiteVisitController.SelectPropertiesWrappper wrap =
            SelectPropertsiteVisitController.getProjectDetailsBasedonSearch(
                null,           // FlatBhkId
                'InvalidProj',  // projectName
                'T1',           // towerName
                '3 BHK'         // unitType
            );
        Test.stopTest();

        System.assertEquals(null, wrap,
                            'Invalid project name should return null (no project found)');
    }

    @IsTest
    static void testGetProjectDetailsBasedonSearch_ProjectWithNoTower() {
        // Create a project without a tower to hit towers.isEmpty() branch
        Company__c comp = [SELECT Id FROM Company__c LIMIT 1];
        Project__c projNoTower = new Project__c(
            Name       = 'No Tower Project',
            Company__c = comp.Id,
            Active__c  = true,
            City__c    = 'City2',
            Zone__c    = 'West'
        );
        insert projNoTower;

        Test.startTest();
        SelectPropertsiteVisitController.SelectPropertiesWrappper wrap =
            SelectPropertsiteVisitController.getProjectDetailsBasedonSearch(
                null,                 // FlatBhkId
                projNoTower.Name,     // projectName
                null,                 // towerName
                null                  // unitType
            );
        Test.stopTest();

        System.assertEquals(null, wrap,
                            'Project with no towers should return null');
    }

    @IsTest
    static void testGetUnitRecord() {
        Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];

        Test.startTest();
        Unit__c retrievedUnit =
            SelectPropertsiteVisitController.getUnitRecord(unit.Id);
        Test.stopTest();

        System.assertEquals(unit.Id, retrievedUnit.Id,
                            'Unit should be fetched correctly by Id');
    }
}