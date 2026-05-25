@isTest
public class bookingFormControllerTest {
    
    @isTest
    public static void testCreateApplicants() {
        // Setup Test Data
        Account primaryAccount = new Account(Name = 'Primary Account',Last_Name__c = 'Krishna', Email__c = 'primary@example.com', Phone = '1234567890');
        insert primaryAccount;
        
        Account applicant1 = new Account(Name = 'Applicant 1',Last_Name__c = 'Krishna', Email__c = 'applicant1@example.com', Phone = '1234567891');
        Account applicant2 = new Account(Name = 'Applicant 2',Last_Name__c = 'Krishna', Email__c = 'applicant2@example.com', Phone = '1234567892');
        List<Account> applicantList = new List<Account>{applicant1, applicant2};
		
		Contact con = new Contact(LastName = primaryAccount.Name , Email = 'test@gmail.com' ,AccountId = primaryAccount.Id, Phone = '9900990099');
        insert con;
        
		List<Contact> contactList = [Select Id,Name,Email,Phone,AccountId From Contact Where AccountId = :primaryAccount.Id Limit 1];
		System.debug('contactList'+contactList);
		
        
        Opportunity opp = new Opportunity(Name = 'Test Opportunity', StageName = 'Prospecting', CloseDate = System.today(), AccountId = primaryAccount.Id);
        insert opp;
        
        Task ta  = new Task(Subject = 'Fill Applicant Details',WhatId = opp.Id);
        insert ta;

        // Prepare Profile Data List (mock base64 data)
        String profileDataList = '[{"fileName":"file1.png", "base64Data":"dGVzdA==", "Name":"Primary Account"}]';
        
        // Test method
        Test.startTest();
        String result = bookingFormController.createApplicants(applicantList, opp.Id, profileDataList, primaryAccount.Id, primaryAccount);
        Test.stopTest();
    }

    @isTest
    public static void testSaveContentVersion() {
        // Test the saveContentVersion method
        String fileName = 'testfile.png';
        String base64Data = 'dGVzdA==';  // "test" in base64
        Test.startTest();
        Id contentVersionId = bookingFormController.saveContentVersion(fileName, base64Data);
        Test.stopTest();
    }
    
    @isTest
    public static void testGetProjectPicklistDetails() {
        // Test the getProjectPicklistDetails method
        Opportunity opp = new Opportunity(Name = 'Test Opportunity', StageName = 'Prospecting', CloseDate = System.today());
        insert opp;

        Map<String, String> objectByField = new Map<String, String>{'Opportunity' => 'StageName'};
        Map<String, String> objectByFieldAddress = new Map<String, String>{'Account' => 'BillingCountry'};
        
        Test.startTest();
        bookingFormController.projectPicklistWrapper result = bookingFormController.getProjectPicklistDetails(opp.Id, objectByField, objectByFieldAddress);
        Test.stopTest();
    }

    @isTest
    public static void testGetAllPickListVal() {
        // Test the getAllPickListVal method
        Map<String, String> objectByField = new Map<String, String>{'Type' => 'Account'};
        
        Test.startTest();
        Map<String, List<String>> result = bookingFormController.getAllPickListVal(objectByField);
        Test.stopTest();
    }

    @isTest
    public static void testGetPicklistValues() {
        // Test the getPicklistValues method
        String objName = 'Account';
        String fieldName = 'Type';

        Test.startTest();
        List<String> result = bookingFormController.getPicklistValues(objName, fieldName);
        Test.stopTest();
    }

    @isTest
    public static void testGetAllPickListValForAddress() {
        // Test the getAllPickListValForAddress method
        Map<String, String> objectByField = new Map<String, String>{'BillingAddress' => 'Account'};
        
        Test.startTest();
        Map<String, List<Map<String, String>>> result = bookingFormController.getAllPickListValForAddress(objectByField);
        Test.stopTest();
    }

    @isTest
    public static void testGetFieldDependencies() {
        // Test the getFieldDependencies method
        String objectName = 'Account';
        String controllingField = 'Type';
        String dependentField = 'Industry__c';
        
        Test.startTest();
        Map<String, List<String>> result = bookingFormController.getFieldDependencies(objectName, controllingField, dependentField);
        Test.stopTest();
    }


}