@isTest
public class DiscountLineItemTriggerHandlerTest {

    @isTest
    static void testCreateDiscountLineItem() {
        Company__c company = new Company__c(Name = 'Test Company');
        insert company;
        Project__c project = new Project__c(Name = 'Test Project', Company__c = company.Id);
        insert project;

        Project_Roles__c role = new Project_Roles__c(Project__c = project.Id, Role__c = 'MD');
        insert role;

        Discount_Master__c discountMaster = new Discount_Master__c(Project__c = project.Id);
        insert discountMaster;

        Discount_LineItem__c discountLineItem = new Discount_LineItem__c(
            Discount_Master__c = discountMaster.Id,
            Roles__c = 'MD'
        );

        Test.startTest();
        insert discountLineItem;
        Test.stopTest();

        List<Discount_LineItem__c> lineItems = [SELECT Id FROM Discount_LineItem__c WHERE Id = :discountLineItem.Id];

    }

    @isTest
    static void testUpdateDiscountLineItem() {
        Company__c company = new Company__c(Name = 'Test Company');
        insert company;
        Project__c project = new Project__c(Name = 'Test Project', Company__c = company.Id);
        insert project;

        Project_Roles__c role1 = new Project_Roles__c(Project__c = project.Id, Role__c = 'MD');
        insert role1;
        Project_Roles__c role2 = new Project_Roles__c(Project__c = project.Id, Role__c = 'Sales Head');
        insert role2;

        Discount_Master__c discountMaster = new Discount_Master__c(Project__c = project.Id);
        insert discountMaster;
        
		Discount_LineItem__c discountLineItem = new Discount_LineItem__c(
            Discount_Master__c = discountMaster.Id,
            Roles__c = 'MD'
        );
        insert discountLineItem;

		discountLineItem.Roles__c = 'Sales Head';

        Test.startTest();
        update discountLineItem;
        Test.stopTest();
    }
}