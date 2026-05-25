@isTest
public class SobjectLoadAssignmentHelperTest {

    @testSetup
    static void setup() {

      	Company__c comp = new Company__c(Name = 'Test Company', Email__c = 'test@test.com');
        insert comp;

        Project__c proj = new Project__c(Name = 'Test Project', Company__c = comp.Id);
        insert proj;

        Assignment_Group__c ag = new Assignment_Group__c(
            Name = 'Test Group',
            Max_Sobject_Assignment_Count__c = 10,
            Last_Allocated_RRid__c = 0,
            isActive__c = true,
            Type__c = 'Pre Sales',
            Supported_Sobject__c = 'Lead'   
        );
        insert ag;

        List<Assignment_Group_Member__c> members = new List<Assignment_Group_Member__c>{
            new Assignment_Group_Member__c(
                Assignment_Group__c = ag.Id,
                Assignment_Id__c = 2,
                Group_Member__c = UserInfo.getUserId(),
                Max_Sobject_Assignment_Count__c = 5,
                BreakTime_Started__c = false,
                Active__c = true
            ),
            new Assignment_Group_Member__c(
                Assignment_Group__c = ag.Id,
                Assignment_Id__c = 4,
                Group_Member__c = UserInfo.getUserId(),
                Max_Sobject_Assignment_Count__c = 5,
                BreakTime_Started__c = false,
                Active__c = true
            ),
            new Assignment_Group_Member__c(
                Assignment_Group__c = ag.Id,
                Assignment_Id__c = 6,
                Group_Member__c = UserInfo.getUserId(),
                Max_Sobject_Assignment_Count__c = 5,
                BreakTime_Started__c = false,
                Active__c = true
            )
        };
        insert members;

        List<Lead> leads = new List<Lead>();
        for(Integer i = 1; i <= 5; i++){
            leads.add(new Lead(
                LastName = 'Lead ' + i,
                Company = 'Test Company ' + i,
                Project__c = proj.Id   
            ));
        }
        insert leads;

        SobjectLoadAssignmentHelper.rv_MapOfAGIdByAG.put(ag.Id, ag);
        SobjectLoadAssignmentHelper.rv_MapOfAGIDByASMList.put(ag.Id, members);

        SobjectLoadAssignment.rv_MapOfAGIDByASMList = new Map<Id, List<Assignment_Group_Member__c>>();
        SobjectLoadAssignment.rv_MapOfAGIDByASMList.put(ag.Id, members);
    }


    @isTest
    static void testExecuteSobjectOwnerAssignment_LeadFlow() {

        Assignment_Group__c groupRec = [SELECT Id FROM Assignment_Group__c LIMIT 1];
        List<Lead> leads = [SELECT Id FROM Lead];

        Test.startTest();
        SobjectLoadAssignmentHelper.ExecuteSobjectOwnerAssignment(leads, groupRec.Id, null);
        Test.stopTest();

        Lead anyLead = [
            SELECT OwnerId, Status 
            FROM Lead LIMIT 1
        ];

      
    }
}