@isTest
public class SobjectLoadAssignmentUtilityTest {

    @isTest
  public  static void setupTestData() {
        // Create some Assignment Groups
        List<Assignment_Group__c> assignmentGroups = new List<Assignment_Group__c>();
        for (Integer i = 0; i < 3; i++) {
            assignmentGroups.add(new Assignment_Group__c(
                Name = 'Group' + i,
                Round_Robin_Queue_Name__c = 'Queue' + i,
                isActive__c = true,
                Supported_Sobject__c ='Lead'
            ));
        }
        insert assignmentGroups;
        
        // Create some Assignment Group Members
        List<Assignment_Group_Member__c> groupMembers = new List<Assignment_Group_Member__c>();
        for (Assignment_Group__c group1 : assignmentGroups) {
            groupMembers.add(new Assignment_Group_Member__c(
                Assignment_Group__c = group1.Id,
                Active__c = true
            ));
        }
        insert groupMembers;
        
        // Create Queue Groups
        List<Group> queueGroups = new List<Group>();
        for (Integer i = 0; i < 3; i++) {
            queueGroups.add(new Group(
                Name = 'Queue' + i,
                Type = 'Queue'
            ));
        }
        insert queueGroups;
        
        
        Test.startTest();
        SobjectLoadAssignmentUtility.GetQueuesNameAndId();
        SobjectLoadAssignmentUtility.GetassigmentGroup();
       SobjectLoadAssignmentUtility.assignmentGroupMembers();
      SobjectLoadAssignmentUtility.getCaseCount(queueGroups[0].id);
         Test.stopTest();  
    }

   /* @isTest
    static void testGetQueuesNameAndId() {
        Map<String, Id> queueMap = SobjectLoadAssignmentUtility.GetQueuesNameAndId();
        
        System.assertNotEquals(null, queueMap, 'Queue map should not be null');
        System.assertEquals(3, queueMap.size(), 'Queue map should have 3 entries');
        for (Integer i = 0; i < 3; i++) {
            System.assert(queueMap.containsKey('Queue' + i), 'Queue map should contain Queue' + i);
        }
    }

    @isTest
    static void testGetAssignmentGroup() {
        Map<Id, Assignment_Group__c> assignmentGroupMap = SobjectLoadAssignmentUtility.GetassigmentGroup();
        
        System.assertNotEquals(null, assignmentGroupMap, 'Assignment group map should not be null');
        System.assertEquals(3, assignmentGroupMap.size(), 'Assignment group map should have 3 entries');
    }

    @isTest
    static void testGetCaseCount() {
        Assignment_Group__c assignmentGroup = [SELECT Id FROM Assignment_Group__c LIMIT 1];
        Assignment_Group_Member__c groupMember = [SELECT Id FROM Assignment_Group_Member__c WHERE Assignment_Group__c = :assignmentGroup.Id LIMIT 1];
        
        // Insert test cases for today
        for (Integer i = 0; i < 2; i++) {
            Case testCase = new Case(
                AGM_Related_to__c = groupMember.Id
            );
            insert testCase;
        }
        
        Map<Id, Integer> caseCountMap = SobjectLoadAssignmentUtility.getCaseCount(assignmentGroup.Id);
        
        System.assertNotEquals(null, caseCountMap, 'Case count map should not be null');
        System.assertEquals(1, caseCountMap.size(), 'Case count map should have 1 entry');
        System.assertEquals(2, caseCountMap.get(groupMember.Id), 'Case count for group member should be 2');
    }

    @isTest
    static void testAssignmentGroupMembers() {
        Map<Id, List<Assignment_Group_Member__c>> assignmentGroupMembersMap = SobjectLoadAssignmentUtility.assignmentGroupMembers();
        
        System.assertNotEquals(null, assignmentGroupMembersMap, 'Assignment group members map should not be null');
        System.assertEquals(3, assignmentGroupMembersMap.size(), 'Assignment group members map should have 3 entries');
        for (Id groupId : assignmentGroupMembersMap.keySet()) {
            System.assertEquals(1, assignmentGroupMembersMap.get(groupId).size(), 'Each assignment group should have 1 member');
        }
    }*/
}