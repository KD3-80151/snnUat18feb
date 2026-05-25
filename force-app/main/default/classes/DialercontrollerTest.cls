@isTest
public class DialercontrollerTest {

    @isTest
    static void testDialerController() {
		 Company__c company = new Company__c(Name='TestCo');
        insert company;

        Project__c proj = new Project__c(Name='TestProject', Company__c=company.Id);
        insert proj;
        /** 🔹 Test Data: Create Sample Leads */
        List<Lead> leads = new List<Lead>();
        for(Integer i=1; i<=3; i++){
            leads.add(new Lead(
                LastName = 'Test ' + i,
                Company = 'Test Company',
                Project__c = proj.Id
            ));
        }
        insert leads;

        /** 🔹 StandardSetController with selected records */
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(leads);

        /** 🔹 Create Controller Instance */
        Test.startTest();
        Dialercontroller dc = new Dialercontroller(ssc);
        PageReference resultPage = dc.direct();
        Test.stopTest();

    }
}