@IsTest
public class opportunityApprovalProcessTest {

    private static User createTestUser(String aliasValue, Id managerId) {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User u = new User(
            FirstName = 'Test',
            LastName = aliasValue,
            Email = aliasValue + '@test.com',
            Username = aliasValue + String.valueOf(DateTime.now().getTime()) + '@test.com',
            Alias = aliasValue.substring(0, Math.min(aliasValue.length(), 8)),
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id,
            ManagerId = managerId
        );
        insert u;
        return u;
    }

    private static Company__c createCompany() {
        Company__c comp = new Company__c(
            Name = 'Test Company'
        );
        insert comp;
        return comp;
    }

    private static Project__c createProject() {
        Company__c comp = createCompany();

        Project__c proj = new Project__c(
            Name = 'Test Project',
            Company__c = comp.Id
        );
        insert proj;
        return proj;
    }

    private static Opportunity createOpportunity(Id ownerId, Id projectId) {
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            OwnerId = ownerId,
            Project__c = projectId
        );
        insert opp;
        return opp;
    }

    private static Task createTask(Id whatId) {
        Task t = new Task(
            Subject = 'Approval Task',
            WhatId = whatId,
            Status = 'Open'
        );
        insert t;
        return t;
    }

    private static Assignment_Group__c createAssignmentGroup(Id projectId, Decimal lastAllocatedGre, Decimal lastAllocatedRr) {
        Assignment_Group__c ag = new Assignment_Group__c(
            Name = 'CRM Assignment',
            Type__c = 'CRM',
            Project__c = projectId,
            GRE_Last_allocated_Id__c = lastAllocatedGre,
            Last_Allocated_RRid__c = lastAllocatedRr
        );
        insert ag;
        return ag;
    }

    private static Assignment_Group_Member__c createGroupMember(
        Id groupId,
        Id userId,
        Decimal assignmentId,
        Boolean activeFlag,
        Boolean breakTimeFlag,
        Boolean outOfOfficeFlag
    ) {
        Assignment_Group_Member__c agm = new Assignment_Group_Member__c(
            Assignment_Group__c = groupId,
            Group_Member__c = userId,
            Assignment_Id__c = assignmentId,
            Active__c = activeFlag,
            BreakTime_Started__c = breakTimeFlag,
            Out_Of_Office__c = outOfOfficeFlag
        );
        insert agm;
        return agm;
    }

    @IsTest
    static void testGetCRMUsers_FirstMemberWhenLastAllocatedIsNull() {
        User managerUser = createTestUser('mgr001', null);
        User crmUser1 = createTestUser('crm001', managerUser.Id);
        User crmUser2 = createTestUser('crm002', managerUser.Id);

        Project__c proj = createProject();
        Opportunity opp = createOpportunity(crmUser1.Id, proj.Id);
        Task t = createTask(opp.Id);

        Assignment_Group__c ag = createAssignmentGroup(proj.Id, null, 0);
        createGroupMember(ag.Id, crmUser1.Id, 1, true, false, false);
        createGroupMember(ag.Id, crmUser2.Id, 2, true, false, false);

        Test.startTest();
        String assignedUserId = opportunityApprovalProcess.getCRMUsers(t.Id);
        Test.stopTest();

        System.assertEquals(String.valueOf(crmUser1.Id), assignedUserId);

        Assignment_Group__c updatedGroup = [
            SELECT GRE_Last_allocated_Id__c
            FROM Assignment_Group__c
            WHERE Id = :ag.Id
        ];
        System.assertEquals(1, updatedGroup.GRE_Last_allocated_Id__c);
    }

    @IsTest
    static void testGetCRMUsers_NextMemberWhenLastAllocatedExists() {
        User managerUser = createTestUser('mgr002', null);
        User crmUser1 = createTestUser('crm003', managerUser.Id);
        User crmUser2 = createTestUser('crm004', managerUser.Id);

        Project__c proj = createProject();
        Opportunity opp = createOpportunity(crmUser1.Id, proj.Id);
        Task t = createTask(opp.Id);

        Assignment_Group__c ag = createAssignmentGroup(proj.Id, 1, 0);
        createGroupMember(ag.Id, crmUser1.Id, 1, true, false, false);
        createGroupMember(ag.Id, crmUser2.Id, 2, true, false, false);

        Test.startTest();
        String assignedUserId = opportunityApprovalProcess.getCRMUsers(t.Id);
        Test.stopTest();

        System.assertEquals(String.valueOf(crmUser2.Id), assignedUserId);

        Assignment_Group__c updatedGroup = [
            SELECT GRE_Last_allocated_Id__c
            FROM Assignment_Group__c
            WHERE Id = :ag.Id
        ];
        System.assertEquals(2, updatedGroup.GRE_Last_allocated_Id__c);
    }

    @IsTest
    static void testGetCRMUsers_RoundRobinBackToFirst() {
        User managerUser = createTestUser('mgr003', null);
        User crmUser1 = createTestUser('crm005', managerUser.Id);
        User crmUser2 = createTestUser('crm006', managerUser.Id);

        Project__c proj = createProject();
        Opportunity opp = createOpportunity(crmUser1.Id, proj.Id);
        Task t = createTask(opp.Id);

        Assignment_Group__c ag = createAssignmentGroup(proj.Id, 2, 0);
        createGroupMember(ag.Id, crmUser1.Id, 1, true, false, false);
        createGroupMember(ag.Id, crmUser2.Id, 2, true, false, false);

        Test.startTest();
        String assignedUserId = opportunityApprovalProcess.getCRMUsers(t.Id);
        Test.stopTest();

        System.assertEquals(String.valueOf(crmUser1.Id), assignedUserId);

        Assignment_Group__c updatedGroup = [
            SELECT GRE_Last_allocated_Id__c
            FROM Assignment_Group__c
            WHERE Id = :ag.Id
        ];
        System.assertEquals(1, updatedGroup.GRE_Last_allocated_Id__c);
    }

    @IsTest
    static void testGetCRMUsers_NoActiveMembers() {
        User managerUser = createTestUser('mgr004', null);
        User crmUser1 = createTestUser('crm007', managerUser.Id);

        Project__c proj = createProject();
        Opportunity opp = createOpportunity(crmUser1.Id, proj.Id);
        Task t = createTask(opp.Id);

        Assignment_Group__c ag = createAssignmentGroup(proj.Id, null, 0);
        createGroupMember(ag.Id, crmUser1.Id, 1, false, false, false);

        Test.startTest();
        String result = opportunityApprovalProcess.getCRMUsers(t.Id);
        Test.stopTest();

        System.assertEquals('No Active user found in the assignment group', result);
    }

    @IsTest
    static void testGetCRMUsers_NoAssignmentGroupFound() {
        User managerUser = createTestUser('mgr005', null);
        User crmUser1 = createTestUser('crm008', managerUser.Id);

        Project__c proj = createProject();
        Opportunity opp = createOpportunity(crmUser1.Id, proj.Id);
        Task t = createTask(opp.Id);

        Test.startTest();
        String result = opportunityApprovalProcess.getCRMUsers(t.Id);
        Test.stopTest();

        System.assertEquals('No CRM Assignment Group found for the given project', result);
    }

    @IsTest
    static void testUpdateAssignmentGroup() {
        Project__c proj = createProject();
        Assignment_Group__c ag = createAssignmentGroup(proj.Id, null, 0);

        Test.startTest();
        opportunityApprovalProcess.updateAssignmentGroup(ag.Id, 5);
        Test.stopTest();

        Assignment_Group__c updatedGroup = [
            SELECT Last_Allocated_RRid__c
            FROM Assignment_Group__c
            WHERE Id = :ag.Id
        ];
        System.assertEquals(5, updatedGroup.Last_Allocated_RRid__c);
    }

    @IsTest
    static void testSubmitForApproval_Exception_NoManager() {
        User oldOwner = createTestUser('crm009', null);
        User newOwner = createTestUser('crm010', null);

        Project__c proj = createProject();
        Opportunity opp = createOpportunity(oldOwner.Id, proj.Id);
        Task t = createTask(opp.Id);

        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            opportunityApprovalProcess.submitForApproval(t.Id, String.valueOf(newOwner.Id));
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();
    }
}