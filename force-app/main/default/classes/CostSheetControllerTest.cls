@isTest
public class CostSheetControllerTest {

    // Method to create test data for related objects
    private static void createTestData() {
        Account acc = new Account(Name = 'Test');
		insert acc;
        Opportunity opportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            AccountId = acc.Id 
        );
        insert opportunity;
        
        // Create Unit and related records
        Tower__c tower = new Tower__c(Name = 'Test Tower');
        insert tower;
        
        Floor__c floor = new Floor__c( Blocks__c = tower.Id);
        insert floor;
        
        Unit__c unit = new Unit__c( Floor__c = floor.Id);
        insert unit;

        Parking_Details__c parkingDetail1 = new Parking_Details__c(
            BLock__c = tower.Id, 
            Parking_Type__c = 'Independent', 
            Amount__c = 100
        );
        insert parkingDetail1;
        
        Parking_Details__c parkingDetail2 = new Parking_Details__c(
            BLock__c = tower.Id, 
            Parking_Type__c = 'Open', 
            Amount__c = 150
        );
        insert parkingDetail2;

        // Create Cost Sheet linked to Opportunity and Unit
        Cost_Sheet__c costSheet = new Cost_Sheet__c(
            
            Opportunity__c = opportunity.Id, 
            Unit__c = unit.Id
        );
        insert costSheet;
        
        // Create Pricing Element Master records
        Pricing_Element_Master__c pemIndependent = new Pricing_Element_Master__c(
            Name = 'Car Parking - Independent'
        );
        insert pemIndependent;

        Pricing_Element_Master__c pemOpen = new Pricing_Element_Master__c(
            Name = 'Car Parking - Open'
        );
        insert pemOpen;

        // Create a Pricing Element linked to the Cost Sheet
        Pricing_Element__c pricingElement = new Pricing_Element__c(
            Cost_Sheet__c = costSheet.Id,
            Quantity__c = 2, 
            Rate__c = 100,
            Pricing_Element_Master__c = pemIndependent.Id
        );
        insert pricingElement;
    }
    
    // Test getCostSheets method
    @isTest
    public static void testGetCostSheets() {
        // Create test data
        createTestData();
        
        // Query an Opportunity created in test data
        Opportunity opportunity = [SELECT Id FROM Opportunity LIMIT 1];
        
        // Call the method from the controller
        List<Cost_Sheet__c> costSheets = CostSheetController.getCostSheets(opportunity.Id);
        
        
    }
    
    // Test getParkingDetails method
    @isTest
    public static void testGetParkingDetails() {
        // Create test data
        createTestData();
        
        // Query a Unit created in test data
        Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];
        
        // Call the method from the controller
        CostSheetController.ParkingDetailsWrapper parkingWrapper = CostSheetController.getParkingDetails(unit.Id);
        
       
    }
    
    // Test getParkingTypePicklistValues method
    @isTest
    public static void testGetParkingTypePicklistValues() {
        // Create test data
        createTestData();
        
        // Call the method from the controller
        List<String> parkingTypes = CostSheetController.getParkingTypePicklistValues();
        
        
    }
    
  	 @isTest
    public static void testCreatePricingElement() {
        // Create test data
        createTestData();
        
        // Query a Cost Sheet created in test data
        Id costSheetId = [SELECT Id FROM Cost_Sheet__c LIMIT 1].Id;
        
        // Prepare the JSON data for pricing elements
        List<CostSheetController.PricingElementWrapper> pricingElementData = new List<CostSheetController.PricingElementWrapper>();

        // Correct instantiation of PricingElementWrapper using the constructor
        CostSheetController.PricingElementWrapper wrapper = new CostSheetController.PricingElementWrapper();
        wrapper.amount = 200;
        wrapper.costSheetId = costSheetId;
        wrapper.quantity = 3;
        wrapper.rate = 150;
        wrapper.pricingElementMasterId = 'Car Parking - Independent';
        
        pricingElementData.add(wrapper);
        
        // Serialize the list into JSON string
        String jsondata = JSON.serialize(pricingElementData);
        
        // Call the method from the controller
        String result = CostSheetController.createPricingElement(jsondata);
        
        
    }
    
    // Test checkForRelatedUnit method
    @isTest
    public static void testCheckForRelatedUnit() {
        // Create test data
        createTestData();
        
        // Query a Cost Sheet created in test data
        Cost_Sheet__c costSheet = [SELECT Id FROM Cost_Sheet__c LIMIT 1];
        
        // Call the method from the controller
        Boolean hasRelatedUnit = CostSheetController.checkForRelatedUnit(costSheet.Id);
        
        
    }
	@isTest
    public static void testCreatePricingElement1() {
        // Create test data
        createTestData();
        
        // Query a Cost Sheet created in test data
        Id costSheetId = [SELECT Id FROM Cost_Sheet__c LIMIT 1].Id;
        
        // Prepare the JSON data for pricing elements
        List<CostSheetController.PricingElementWrapper> pricingElementData = new List<CostSheetController.PricingElementWrapper>();

        // Create the PricingElementWrapper using the constructor
        CostSheetController.PricingElementWrapper wrapper = new CostSheetController.PricingElementWrapper(
            200,                     // Amount
            costSheetId,             // Cost Sheet Id
            3,                       // Quantity
            150,                     // Rate
            'Car Parking - Independent'  // Pricing Element Master Id
        );
        
        // Add the wrapper to the list
        pricingElementData.add(wrapper);
        
        // Serialize the list into JSON string
        String jsondata = JSON.serialize(pricingElementData);
        
        // Call the method from the controller
        String result = CostSheetController.createPricingElement(jsondata);
         
        
    }
}