@isTest
private class LeadTriggerHandlerTest {

    @testSetup
    static void setupTestData() {
        Company__c company = new Company__c(Name = 'Test Company');
        insert company;

        Project__c project = new Project__c(Name = 'Test Project', Company__c = company.Id);
        insert project;

        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Co',
            Phone = '1234567890',
            Project__c = project.Id
        );
        insert testLead;
    }

    // IsConverted/ConvertedOpportunityId are system-managed and can only be
    // populated by a real lead conversion; this performs one and returns the
    // post-conversion Lead (with those fields now populated by Salesforce).
    private static Lead convertLead(Id leadId) {
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(leadId);
        lc.setConvertedStatus('Converted');
        lc.setDoNotCreateOpportunity(false);
        Database.convertLead(lc);
        return [SELECT Id, IsConverted, ConvertedOpportunityId FROM Lead WHERE Id = :leadId];
    }

    @isTest
    static void testHandleLeadConversionUpdatesExistingNotes() {
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];

        Communication_Notes__c note1 = new Communication_Notes__c(Lead__c = testLead.Id);
        Communication_Notes__c note2 = new Communication_Notes__c(Lead__c = testLead.Id);
        insert new List<Communication_Notes__c>{ note1, note2 };

        Lead oldLead = new Lead(Id = testLead.Id, IsConverted = false);
        Lead newLead = convertLead(testLead.Id);

        Test.startTest();
        LeadTriggerHandler.handleLeadConversion(
            new List<Lead>{ newLead },
            new Map<Id, Lead>{ testLead.Id => oldLead }
        );
        Test.stopTest();

        List<Communication_Notes__c> updatedNotes = [SELECT Id, Opportunity__c FROM Communication_Notes__c WHERE Lead__c = :testLead.Id];
        System.assertEquals(2, updatedNotes.size());
        for (Communication_Notes__c n : updatedNotes) {
            System.assertEquals(newLead.ConvertedOpportunityId, n.Opportunity__c);
        }
    }

    @isTest
    static void testHandleLeadConversionSkipsWhenNotNewlyConverted() {
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];

        Communication_Notes__c note = new Communication_Notes__c(Lead__c = testLead.Id);
        insert note;

        Lead oldLead = new Lead(Id = testLead.Id, IsConverted = false);
        Lead newLead = new Lead(Id = testLead.Id, IsConverted = false);

        Test.startTest();
        LeadTriggerHandler.handleLeadConversion(
            new List<Lead>{ newLead },
            new Map<Id, Lead>{ testLead.Id => oldLead }
        );
        Test.stopTest();

        Communication_Notes__c unchangedNote = [SELECT Opportunity__c FROM Communication_Notes__c WHERE Id = :note.Id];
        System.assertEquals(null, unchangedNote.Opportunity__c, 'Note should not change when lead is not converted.');
    }

    @isTest
    static void testHandleLeadConversionSkipsWhenAlreadyConverted() {
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];

        Communication_Notes__c note = new Communication_Notes__c(Lead__c = testLead.Id);
        insert note;

        Lead oldLead = new Lead(Id = testLead.Id, IsConverted = true);
        Lead newLead = new Lead(Id = testLead.Id, IsConverted = true);

        Test.startTest();
        LeadTriggerHandler.handleLeadConversion(
            new List<Lead>{ newLead },
            new Map<Id, Lead>{ testLead.Id => oldLead }
        );
        Test.stopTest();

        Communication_Notes__c unchangedNote = [SELECT Opportunity__c FROM Communication_Notes__c WHERE Id = :note.Id];
        System.assertEquals(null, unchangedNote.Opportunity__c, 'Note should not change when lead was already converted.');
    }

    @isTest
    static void testHandleLeadConversionSkipsWhenNoConvertedOpportunityId() {
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];

        Communication_Notes__c note = new Communication_Notes__c(Lead__c = testLead.Id);
        insert note;

        Lead oldLead = new Lead(Id = testLead.Id, IsConverted = false);
        Lead newLead = new Lead(Id = testLead.Id, IsConverted = true);

        Test.startTest();
        LeadTriggerHandler.handleLeadConversion(
            new List<Lead>{ newLead },
            new Map<Id, Lead>{ testLead.Id => oldLead }
        );
        Test.stopTest();

        Communication_Notes__c unchangedNote = [SELECT Opportunity__c FROM Communication_Notes__c WHERE Id = :note.Id];
        System.assertEquals(null, unchangedNote.Opportunity__c);
    }

    @isTest
    static void testHandleLeadConversionWithNoExistingNotes() {
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];

        Lead oldLead = new Lead(Id = testLead.Id, IsConverted = false);
        Lead newLead = convertLead(testLead.Id);

        Test.startTest();
        LeadTriggerHandler.handleLeadConversion(
            new List<Lead>{ newLead },
            new Map<Id, Lead>{ testLead.Id => oldLead }
        );
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Communication_Notes__c WHERE Lead__c = :testLead.Id]);
    }

    @isTest
    static void testHandleLeadConversionSwallowsExceptionWhenOldLeadMissing() {
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        Lead newLead = new Lead(Id = testLead.Id, IsConverted = true);

        Test.startTest();
        // oldLeadMap intentionally has no entry for this lead, forcing a null
        // pointer on oldLead.IsConverted that the method must swallow.
        LeadTriggerHandler.handleLeadConversion(
            new List<Lead>{ newLead },
            new Map<Id, Lead>()
        );
        Test.stopTest();
    }

    @isTest
    static void testHandleLeadConversionWithMultipleConvertedLeads() {
        Company__c company = new Company__c(Name = 'Second Company');
        insert company;
        Project__c project = new Project__c(Name = 'Second Project', Company__c = company.Id);
        insert project;

        Lead secondLead = new Lead(
            FirstName = 'Second',
            LastName = 'Lead',
            Company = 'Second Co',
            Phone = '9999999999',
            Project__c = project.Id
        );
        insert secondLead;

        Lead firstLead = [SELECT Id FROM Lead WHERE Id != :secondLead.Id LIMIT 1];

        Communication_Notes__c note1 = new Communication_Notes__c(Lead__c = firstLead.Id);
        Communication_Notes__c note2 = new Communication_Notes__c(Lead__c = secondLead.Id);
        insert new List<Communication_Notes__c>{ note1, note2 };

        Lead oldLead1 = new Lead(Id = firstLead.Id, IsConverted = false);
        Lead newLead1 = convertLead(firstLead.Id);
        Lead oldLead2 = new Lead(Id = secondLead.Id, IsConverted = false);
        Lead newLead2 = convertLead(secondLead.Id);

        Test.startTest();
        LeadTriggerHandler.handleLeadConversion(
            new List<Lead>{ newLead1, newLead2 },
            new Map<Id, Lead>{ firstLead.Id => oldLead1, secondLead.Id => oldLead2 }
        );
        Test.stopTest();

        Map<Id, Communication_Notes__c> notesByLead = new Map<Id, Communication_Notes__c>();
        for (Communication_Notes__c n : [SELECT Id, Lead__c, Opportunity__c FROM Communication_Notes__c
                                          WHERE Lead__c IN :new List<Id>{ firstLead.Id, secondLead.Id }]) {
            notesByLead.put(n.Lead__c, n);
        }
        System.assertEquals(newLead1.ConvertedOpportunityId, notesByLead.get(firstLead.Id).Opportunity__c);
        System.assertEquals(newLead2.ConvertedOpportunityId, notesByLead.get(secondLead.Id).Opportunity__c);
    }
}
