@isTest
public without Sharing  class costSheetTriggerHandlerTest {
    @isTest
    static void testAfterUpdate() {
        // Create test data for Cost Sheet
        List<Cost_Sheet__c> costSheets = new List<Cost_Sheet__c>{
            new Cost_Sheet__c( Finalize_CostSheet__c = false),
            new Cost_Sheet__c( Finalize_CostSheet__c = false)
        };
        insert costSheets;

        // Create test data for Pricing Element Master
        List<Pricing_Element_Master__c> pricingElementMasters = new List<Pricing_Element_Master__c>{
            new Pricing_Element_Master__c(Name = 'Master 1', Parking_Type__c = '	Dependent'),
            new Pricing_Element_Master__c(Name = 'Master 2', Parking_Type__c = '	Dependent')
        };
        insert pricingElementMasters;

        // Create test data for Pricing Element
        List<Pricing_Element__c> pricingElements = new List<Pricing_Element__c>{
            new Pricing_Element__c(  Cost_Sheet__c = costSheets[0].Id, Pricing_Element_Master__c = pricingElementMasters[0].Id, Quantity__c = 10),
            new Pricing_Element__c(  Cost_Sheet__c = costSheets[1].Id, Pricing_Element_Master__c = pricingElementMasters[1].Id, Quantity__c = 15)
        };
        insert pricingElements;

        // Create test data for Parking Details
              Company__c company = new Company__c(Name = 'TestCompany');
        insert company;
        Project__c project = new Project__c(Name = 'TestProject',Company__c = company.Id );
        insert project;
        
        Tower__c towerRec = new Tower__c();
        towerRec.Project__c = project.id;
        insert towerRec;
        List<Parking_Details__c> parkingDetails = new List<Parking_Details__c>{
            new Parking_Details__c(  Parking_Type__c = 'Dependent', Total_Parking__c = 100, Available_Parking__c = 90,Block__c =towerRec.id ),
            new Parking_Details__c(  Parking_Type__c = 'Independent', Total_Parking__c = 200, Available_Parking__c = 190,Block__c =towerRec.id)
        };
        insert parkingDetails;

        // Update cost sheets to trigger afterUpdate
        for (Cost_Sheet__c costSheet : costSheets) {
            costSheet.Finalize_CostSheet__c = true;
        }

        Test.startTest();
        update costSheets;
        Test.stopTest();
    }
}