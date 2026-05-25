@isTest
public class ReusableLookupControllerTest {

    @isTest
    static void testFetchRecordsWithParentRecord() {
        Account parentAccount = new Account(Name = 'Parent Account',Document_Id__c = 'test');
        insert parentAccount;

        Contact contact1 = new Contact(FirstName = 'John', LastName = 'Doe', AccountId = parentAccount.Id);
        Contact contact2 = new Contact(FirstName = 'Jane', LastName = 'Smith', AccountId = parentAccount.Id);
        insert new List<Contact>{contact1, contact2};

        ReusableLookupController.SearchWrapper inputWrapper = new ReusableLookupController.SearchWrapper();
        inputWrapper.objectApiName = 'Contact';
        inputWrapper.fieldApiName = 'FirstName';
        inputWrapper.otherFieldApiName = 'LastName';
        inputWrapper.searchString = 'Jo';
        inputWrapper.parentFieldApiName = 'AccountId';
        inputWrapper.parentRecordId = parentAccount.Id;

        Test.startTest();
        List<ReusableLookupController.ResultWrapper> results = ReusableLookupController.fetchRecords(inputWrapper);
        Test.stopTest();
    }

    @isTest
    static void testFetchRecordsWithoutParentRecord() {
        Account account = new Account(Name = 'Test Account',Document_Id__c ='sfdc');
        insert account;

        Contact contact1 = new Contact(FirstName = 'Alice', LastName = 'Brown', AccountId = account.Id);
        Contact contact2 = new Contact(FirstName = 'Bob', LastName = 'Green', AccountId = account.Id);
        insert new List<Contact>{contact1, contact2};

        ReusableLookupController.SearchWrapper inputWrapper = new ReusableLookupController.SearchWrapper();
        inputWrapper.objectApiName = 'Contact';
        inputWrapper.fieldApiName = 'FirstName';
        inputWrapper.otherFieldApiName = 'LastName';
        inputWrapper.searchString = 'Al';

        Test.startTest();
        List<ReusableLookupController.ResultWrapper> results = ReusableLookupController.fetchRecords(inputWrapper);
        Test.stopTest();
    }

    @isTest
    static void testFetchRecordsWithSpecificRecordId() {
        Contact contact = new Contact(FirstName = 'Chris', LastName = 'White');
        insert contact;

        ReusableLookupController.SearchWrapper inputWrapper = new ReusableLookupController.SearchWrapper();
        inputWrapper.objectApiName = 'Contact';
        inputWrapper.fieldApiName = 'FirstName';
        inputWrapper.otherFieldApiName = 'LastName';
        inputWrapper.selectedRecordId = contact.Id;

        Test.startTest();
        List<ReusableLookupController.ResultWrapper> results = ReusableLookupController.fetchRecords(inputWrapper);
        Test.stopTest();
    }

    @isTest
    static void testFetchRecordsWithUnitObject() {
        Unit__c unit1 = new Unit__c(Unit_Name__c = 'UnitA', Status__c = 'For Sale', Business_Type__c = 'Individual', Facing__c = 'North');
        Unit__c unit2 = new Unit__c(Unit_Name__c = 'UnitZ', Status__c = 'Sold', Business_Type__c = 'test', Facing__c = 'East');
        insert new List<Unit__c>{unit1, unit2};

        ReusableLookupController.SearchWrapper inputWrapper = new ReusableLookupController.SearchWrapper();
        inputWrapper.objectApiName = 'Unit__c';
        inputWrapper.fieldApiName = 'Unit_Name__c';
        inputWrapper.searchString = 'Uni';
        inputWrapper.firstFieldFilterApiName = 'Status__c';
		inputWrapper.secondFieldFilterApiName = 'Business_Type__c';
		inputWrapper.thirdFieldFilterApiName = 'Facing__c';
        inputWrapper.firstFieldFilterValue = 'Sold';
		inputWrapper.secondFieldFilterValue = 'test';
		inputWrapper.thirdFieldFilterValue = 'East';

        Test.startTest();
        List<ReusableLookupController.ResultWrapper> results = ReusableLookupController.fetchRecords(inputWrapper);
        Test.stopTest();
    }

    @isTest
    static void testFetchRecordsWithEmptyWrapper() {
        Test.startTest();
        List<ReusableLookupController.ResultWrapper> results = ReusableLookupController.fetchRecords(null);
        Test.stopTest();
    }
}