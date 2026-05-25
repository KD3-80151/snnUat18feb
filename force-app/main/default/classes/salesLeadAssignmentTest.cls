@isTest
private class salesLeadAssignmentTest {
    
    @isTest
    static void testExecuteLoadAssignment() {
        
         User testUser = new User(
            Username = 'testuser' + System.currentTimeMillis() + '@example.com',
            Email = 'testuser@example.com',
            Alias = 'tu',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
             TimeZoneSidKey = 'America/Los_Angeles',
             LocaleSidKey = 'en_US',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LastName = 'testuser',
            IsActive = true
        );
        insert testUser;
        
         Group testQueue = new Group(
            Name = 'Test Queue', 
            Type = 'Queue'
        );
        insert testQueue;

        Assignment_Group__c agRecord = new Assignment_Group__c(
            Name = 'Test Assignment Group',
            isActive__c = true,
            Execution_SOQL__c = 'select id,Project__c,Project__r.Name,Is_User_Assigned__c from lead', 
            Round_Robin_Queue_Name__c = testQueue.Name,
            Supported_Sobject__c = 'Lead',
            Max_Sobject_Assignment_Count__c = 200,
              Last_Allocated_RRID__c = 2,
            Type__c = 'Sales'
            
        );
        insert agRecord;

        Assignment_Group_Member__c agmRecord = new Assignment_Group_Member__c(
            Assignment_Group__c = agRecord.Id,
            Assignment_Id__c = 1,
            Group_Member__c = testUser.Id,
            Out_Of_Office__c = false,
            BreakTime_Started__c = false,
            Max_Sobject_Assignment_Count__c = 100,
            Active__c = true
        );
        insert agmRecord;
        Company__c company = new Company__c(Name = 'TestCompany');
        insert company;
        Project__c proj = new Project__c(name ='Tridasa First Project', Company__c = company.Id);
        insert proj;
        
        Lead li = new Lead(
            LastName = 'Vamsi',
            AGM_Related_to__c = agmRecord.Id,
            Project__c = proj.Id,
            Company = 'util',
            Is_User_Assigned__c = false,
            Sales_Person_on_Queue__c = false
            
        );
        insert li;
        
        Lead li2 = new Lead(
            LastName = 'Vamsi1',
            Project__c = proj.Id,
            Company = 'util',
            Is_User_Assigned__c = false,
            Sales_Person_on_Queue__c = true
        );
        insert li2;
        
        Test.startTest();
        salesLeadAssignment.ExecuteLoadAssignment1(10, 'Sales');
        Test.stopTest();
    }

    @isTest
    static void testGetAssignMentGroupMemberAndAssignmentGroup() {
        
        User testUser = new User(
            Username = 'testuser2' + System.currentTimeMillis() + '@example.com',
            Email = 'testuser2@example.com',
            Alias = 'tu2',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
             TimeZoneSidKey = 'America/Los_Angeles',
             LocaleSidKey = 'en_US',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LastName = 'testuser2',
            IsActive = true
        );
        insert testUser;
        
         Group testQueue = new Group(
            Name = 'Test Queue', 
            Type = 'Queue'
        );
        insert testQueue;

        Assignment_Group__c agRecord = new Assignment_Group__c(
            Name = 'Test Assignment Group 2',
            isActive__c = true,
            Execution_SOQL__c = 'select id,Project__c,Project__r.Name,Is_User_Assigned__c from lead',
            Round_Robin_Queue_Name__c = 'Test Queue 2',
            Supported_Sobject__c = 'Lead',
            Max_Sobject_Assignment_Count__c = 200,
            Last_Allocated_RRID__c = null,
            Type__c = 'Sales'
            
        );
        insert agRecord;

        Assignment_Group_Member__c agmRecord = new Assignment_Group_Member__c(
            Assignment_Group__c = agRecord.Id,
            Assignment_Id__c = 2,
            Group_Member__c = testUser.Id,
            Out_Of_Office__c = false,
            BreakTime_Started__c = false,
            Max_Sobject_Assignment_Count__c = 100,
            Active__c = true
            
            
        );
        insert agmRecord;
        Company__c company = new Company__c(Name = 'TestCompany');
        insert company;
        Project__c proj = new Project__c(name ='Tridasa First Project', Company__c = company.Id);
        insert proj;
        
        Lead li = new Lead(
            LastName = 'krishna',
            AGM_Related_to__c = agmRecord.Id,
            Project__c = proj.Id,
            Company = 'util',
            Is_User_Assigned__c = true,
            Sales_Person_on_Queue__c = false
        );
        insert li;
        
        Lead li2 = new Lead(
            LastName = 'kumri',
            Project__c = proj.Id,
            Company = 'util',
            Is_User_Assigned__c = false,
            Sales_Person_on_Queue__c = true
        );
        insert li2;

        Test.startTest();
        salesLeadAssignment.GetAssignMentGroupMemberAndAssignmentGroup('Sales');
        Test.stopTest();
    }

    @isTest
    static void testExecuteSobjectAssignment() {
        
         User testUser = new User(
            Username = 'testuser3' + System.currentTimeMillis() + '@example.com',
            Email = 'testuser2@example.com',
            Alias = 'tu2',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
             TimeZoneSidKey = 'America/Los_Angeles',
             LocaleSidKey = 'en_US',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LastName = 'testuser2',
            IsActive = true
        );
        insert testUser;

        Assignment_Group__c agRecord = new Assignment_Group__c(
            Name = 'Test Assignment Group 3',
            isActive__c = true,
            Execution_SOQL__c = 'select id,Project__c,Project__r.Name,Is_User_Assigned__c from lead',
            Round_Robin_Queue_Name__c = 'Test Queue 3',
            Supported_Sobject__c = 'Lead',
            Max_Sobject_Assignment_Count__c = 200,
            Last_Allocated_RRID__c = null,
            Type__c = 'Sales'
        );
        insert agRecord;
        
         Assignment_Group_Member__c agmRecord = new Assignment_Group_Member__c(
            Assignment_Group__c = agRecord.Id,
            Assignment_Id__c = 2,
            Group_Member__c = testUser.Id,
            Out_Of_Office__c = false,
            BreakTime_Started__c = false,
            Max_Sobject_Assignment_Count__c = 100,
             Active__c = true
             
            
        );
        insert agmRecord;
        
         Group testQueue = new Group(
            Name = 'Test Queue', 
            Type = 'Queue'
        );
        insert testQueue;
        Company__c company = new Company__c(Name = 'TestCompany');
        insert company;
        Project__c proj = new Project__c(name ='Tridasa First Project', Company__c = company.Id);
        insert proj;
        
        Lead li = new Lead(
            LastName = 'krishna',
            AGM_Related_to__c = agmRecord.Id,
            Project__c = proj.Id,
            Company = 'util',
            Is_User_Assigned__c = true,
            Sales_Person_on_Queue__c = True
        );
        insert li;

        Test.startTest();
        salesLeadAssignment.ExecuteSobjectAssignment('select id,Project__c,Project__r.Name,Is_User_Assigned__c from lead', agRecord.Id, testQueue.Id, 'Sales');
        Test.stopTest();

    }

    @isTest
    static void testFutureMethod() {
        
         User testUser = new User(
            Username = 'testuser4' + System.currentTimeMillis() + '@example.com',
            Email = 'testuser2@example.com',
            Alias = 'tu2',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
             TimeZoneSidKey = 'America/Los_Angeles',
             LocaleSidKey = 'en_US',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LastName = 'testuser2',
            IsActive = true
        );
        insert testUser;

        Assignment_Group__c agRecord = new Assignment_Group__c(
            Name = 'Test Future Method Group',
            isActive__c = true,
            Execution_SOQL__c = 'select id,Project__c,Project__r.Name,Is_User_Assigned__c from lead',
            Round_Robin_Queue_Name__c = 'Test Queue for Future',
            Supported_Sobject__c = 'Lead',
            Max_Sobject_Assignment_Count__c = 200,
            Type__c = 'Sales'
        );
        insert agRecord;
        
         Assignment_Group_Member__c agmRecord = new Assignment_Group_Member__c(
            Assignment_Group__c = agRecord.Id,
            Assignment_Id__c = 2,
            Group_Member__c = testUser.Id,
            Out_Of_Office__c = false,
            BreakTime_Started__c = false,
            Max_Sobject_Assignment_Count__c = 100,
             Active__c = true
            
        );
        insert agmRecord;
        
         Group testQueue = new Group(
            Name = 'Test Queue', 
            Type = 'Queue'
        );
        insert testQueue;
        Company__c company = new Company__c(Name = 'TestCompany');
        insert company;
        Project__c proj = new Project__c(name ='Tridasa First Project', Company__c = company.Id);
        insert proj;
        
        Lead li = new Lead(
            LastName = 'krishna',
            AGM_Related_to__c = agmRecord.Id,
            Project__c = proj.Id,
            Company = 'util',
            Is_User_Assigned__c = true,
            Sales_Person_on_Queue__c = false
        );
        insert li;
        
        Test.startTest();
        salesLeadAssignment.ExecuteSobjectAssignment('select id,Project__c,Project__r.Name,Is_User_Assigned__c from lead', agRecord.Id, testQueue.Id, 'Sales');
        Test.stopTest();

    }

   
}