@isTest
private class CreateCommNotesAndTaskTest {

    @TestSetup
    static void setupData(){
        Company__c company = new Company__c(Name = 'TestCompany');
        insert company;
        Project__c project = new Project__c(Name = 'Project A', Project_Address__c = 'address', City__c = 'City A', Zone__c = 'East', Company__c = company.Id);
        insert project;

        Lead testLead = new Lead(
            FirstName = 'John',
            LastName = 'Doe',
            Salutation = 'Mr.',
            Project__c = project.Id,
            Company = 'TestCompany',
            Phone = '1234567890',
            Status = 'Open'
        );
        insert testLead;
    }

    @isTest
    static void testNoteWithFollowUp(){
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        Datetime followUp = System.now().addDays(2);

        Test.startTest();
        CreateCommNotesAndTask.createCommNotesAndTask(testLead.Id, 'Call', 'Customer asked to call back', followUp);
        Test.stopTest();

        Communication_Notes__c note = [SELECT Title__c, Remarks__c FROM Communication_Notes__c WHERE Lead__c = :testLead.Id];
        System.assertEquals('Call', note.Title__c);
        System.assertEquals('Customer asked to call back', note.Remarks__c);

        Lead updatedLead = [SELECT Next_Follow_Up_Date_Time__c FROM Lead WHERE Id = :testLead.Id];
        System.assertEquals(followUp, updatedLead.Next_Follow_Up_Date_Time__c);

        Date dueDate = followUp.date();
        List<Task> followUpTasks = [SELECT Description, ReminderDateTime FROM Task
                                    WHERE WhoId = :testLead.Id
                                    AND Subject = :CreateCommNotesAndTask.FOLLOW_UP_TASK_SUBJECT
                                    AND ActivityDate = :dueDate];
        System.assertEquals(1, followUpTasks.size(), 'Exactly one follow up task expected for the follow up date');
        System.assertEquals(followUp, followUpTasks[0].ReminderDateTime);
        System.assert(followUpTasks[0].Description.contains('Customer asked to call back'));
    }

    @isTest
    static void testNoteWithoutFollowUp(){
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        Integer tasksBefore = [SELECT COUNT() FROM Task WHERE WhoId = :testLead.Id];

        Test.startTest();
        CreateCommNotesAndTask.createCommNotesAndTask(testLead.Id, 'Email', 'Brochure shared', null);
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM Communication_Notes__c WHERE Lead__c = :testLead.Id]);
        System.assertEquals(tasksBefore, [SELECT COUNT() FROM Task WHERE WhoId = :testLead.Id], 'No task expected without follow up date');
    }

    @isTest
    static void testMissingRequiredFields(){
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        Boolean hasError = false;

        Test.startTest();
        try{
            CreateCommNotesAndTask.createCommNotesAndTask(testLead.Id, '', 'Remarks', null);
        }
        catch(AuraHandledException e){
            hasError = true;
        }
        Test.stopTest();

        System.assert(hasError, 'Expected an error when Title is blank');
        System.assertEquals(0, [SELECT COUNT() FROM Communication_Notes__c WHERE Lead__c = :testLead.Id]);
    }
}
