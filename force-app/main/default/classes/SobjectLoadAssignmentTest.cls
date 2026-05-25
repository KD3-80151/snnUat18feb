@isTest
private class SobjectLoadAssignmentTest {

    private static Map<String, Object> createTestData(){

        User u = new User(
            Username = 'u'+System.currentTimeMillis()+'@test.com',
            Email = 'u@test.com',
            Alias = 'usr',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LastName = 'UserTest',
            IsActive = true
        );
        insert u;

        Group testQueue = new Group(Name='Test Queue', Type='Queue');
        insert testQueue;

        Company__c company = new Company__c(Name='TestCo');
        insert company;

        Project__c proj = new Project__c(Name='TestProject', Company__c=company.Id);
        insert proj;

        Assignment_Group__c ag = new Assignment_Group__c(
            Name='AG-Test',
            isActive__c=true,
            Type__c='Pre Sales',                      
            Supported_Sobject__c='Lead',
            Execution_SOQL__c='SELECT Id, Project__c FROM Lead',
            Round_Robin_Queue_Name__c='Test Queue',
            Max_Sobject_Assignment_Count__c=10,
            Last_Allocated_RRid__c=1
        );
        insert ag;

        Assignment_Group_Member__c agm = new Assignment_Group_Member__c(
            Assignment_Group__c = ag.Id,
            Assignment_Id__c=1,
            Group_Member__c=u.Id,
            Max_Sobject_Assignment_Count__c=5,
            Active__c=true,
            BreakTime_Started__c=false,
            Out_Of_Office__c=false
        );
        insert agm;

        insert new List<Lead>{
            new Lead(LastName='Lead1', Company='ABC', Project__c=proj.Id, Is_User_Assigned__c=false),
            new Lead(LastName='Lead2', Company='XYZ', Project__c=proj.Id, Is_User_Assigned__c=false)
        };

        SobjectLoadAssignmentHelper.rv_MapOfAGIdByAG.put(ag.Id, ag);
        SobjectLoadAssignmentHelper.rv_MapOfAGIDByASMList.put(ag.Id, new List<Assignment_Group_Member__c>{ agm });

        SobjectLoadAssignment.rv_MapOfAGIdByAG.put(ag.Id, ag);
        SobjectLoadAssignment.rv_MapOfAGIDByASMList.put(ag.Id, new List<Assignment_Group_Member__c>{ agm });
        SobjectLoadAssignment.rv_MapOfQueueNameByQueueID.put('Test Queue', testQueue.Id);

        SobjectLoadAssignment.rv_MapofAGIdByAGMRRIDByAGMId.put(
            ag.Id,
            new Map<Integer,Id>{ 1 => agm.Id }
        );

        return new Map<String,Object>{
            'AG' => ag,
            'QUEUE' => testQueue
        };
    }

    @isTest
    static void testExecuteLoadAssignment(){
        createTestData();

        Test.startTest();
        SobjectLoadAssignment.ExecuteLoadAssignment(5);
        Test.stopTest();

        Lead assigned = [SELECT OwnerId FROM Lead LIMIT 1];
    }

    @isTest
    static void testGetAssignMentGroupMemberAndAssignmentGroup(){
        createTestData();

        Test.startTest();
        SobjectLoadAssignment.GetAssignMentGroupMemberAndAssignmentGroup();
        Test.stopTest();

    }

    @isTest
    static void testExecuteSobjectAssignment(){
        Map<String,Object> data = createTestData();
        Assignment_Group__c ag = (Assignment_Group__c)data.get('AG');
        Group q = (Group)data.get('QUEUE');

        Test.startTest();
        SobjectLoadAssignment.ExecuteSobjectAssignment(
            'SELECT Id, Project__c FROM Lead',
            ag.Id,
            q.Id
        );
        Test.stopTest();

        
    }
}