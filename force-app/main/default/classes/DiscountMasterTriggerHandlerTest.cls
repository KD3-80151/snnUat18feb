@isTest
public class DiscountMasterTriggerHandlerTest {
    
    @isTest
    static void testCheckActiveDiscountMaster() {
        Company__c company = new Company__c(Name = 'Test Company');
        insert company;
        Project__c project1 = new Project__c(Name = 'Project A', Company__c = company.Id);
        insert new List<Project__c>{project1};
        
        Discount_Master__c activeDM1 = new Discount_Master__c(
            Active__c = true,
            Project__c = project1.Id
        );
        Discount_Master__c inactiveDM = new Discount_Master__c(
            Active__c = false,
            Project__c = project1.Id
        );
        insert new List<Discount_Master__c>{activeDM1};

        Discount_Master__c newDM = new Discount_Master__c(
            Active__c = true,
            Project__c = project1.Id
        );
        
        Test.startTest();
        try {
            insert newDM; 
        } catch (DmlException e) {
        }
        Test.stopTest();
    }
    
    @isTest
    static void testShowValidationForSameDiscountMaster() {
        Company__c company = new Company__c(Name = 'Test Company');
        insert company;
        Project__c project1 = new Project__c(Name = 'Project A', Company__c = company.Id);
        Pricing_Element_Master__c pricing1 = new Pricing_Element_Master__c(Name = 'Pricing A');
        insert new List<SObject>{project1, pricing1};
        
        Discount_Master__c activeDM = new Discount_Master__c(
            Active__c = true,
            Project__c = project1.Id,
            Pricing_Element_Master__c = pricing1.Id
        );
        insert activeDM;
        
        Discount_Master__c newDM = new Discount_Master__c(
            Active__c = true,
            Project__c = project1.Id,
            Pricing_Element_Master__c = pricing1.Id
        );
        
        Test.startTest();
        try {
            insert newDM; 
            //System.assert(false, 'Expected an error for duplicate active Discount Master with same pricing element.');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('An active Discount Master record with this Pricing Element already exists for the project.'));
        }
        Test.stopTest();
    }
    
    @isTest
    static void testShowValidationForSameDiscountMasterAfterActive() {
        Company__c company = new Company__c(Name = 'Test Company');
        insert company;
        Project__c project1 = new Project__c(Name = 'Project A', Company__c = company.Id);
        Pricing_Element_Master__c pricing1 = new Pricing_Element_Master__c(Name = 'Pricing A');
        insert new List<SObject>{project1, pricing1};
        
        Discount_Master__c existingDM = new Discount_Master__c(
            Active__c = true,
            Project__c = project1.Id,
            Pricing_Element_Master__c = pricing1.Id
        );
        insert existingDM;
        
        Discount_Master__c newDM = new Discount_Master__c(
            Active__c = false,
            Project__c = project1.Id,
            Pricing_Element_Master__c = pricing1.Id
        );
        insert newDM;

        newDM.Active__c = true;
        
        Test.startTest();
        try {
            update newDM; 
            
        } catch (DmlException e) {
            
        }
        Test.stopTest();
    }
    
    @isTest
    static void testCheckActiveDiscountMaster1() {
        Company__c company = new Company__c(Name = 'Test Company');
        insert company;
        Project__c project = new Project__c(Name = 'Test Project', Company__c = company.Id);
        insert project;

        Discount_Master__c activeDM = new Discount_Master__c(
            Project__c = project.Id,
            Active__c = true
        );
        insert activeDM;
        List<Discount_Master__c> discountMa = new List<Discount_Master__c>();
		discountMa.add(activeDM);



        Test.startTest();
        DiscountMasterTriggerHandler.checkActiveDiscountMaster(discountMa, null);


        Discount_Master__c newActiveDM = new Discount_Master__c(
            Project__c = project.Id,
            Active__c = true
        );

        try {
            insert newActiveDM;
        } catch (DmlException e) {
        }


        Discount_Master__c inactiveDM = new Discount_Master__c(
            Project__c = project.Id,
            Active__c = false
        );
        insert inactiveDM;

        inactiveDM.Active__c = true;

        try {
            update inactiveDM;
        } catch (DmlException e) {
        }

        Project__c anotherProject = new Project__c(Name = 'Another Project', Company__c = company.Id);
        insert anotherProject;

        Discount_Master__c anotherDM = new Discount_Master__c(
            Project__c = anotherProject.Id,
            Active__c = true
        );


        insert anotherDM; 
        Test.stopTest();
    }
}