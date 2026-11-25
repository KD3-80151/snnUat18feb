/**
 * Client (21 Nov): "if we add a 2nd applicant and the form fails, then we correct the data and submit,
 * the corrected applicant becomes the 3rd co-applicant and the failed one stays as the 2nd".
 * A failed submission must save nothing, so the corrected resubmission gives exactly the applicants entered.
 */
@isTest
private class BookingFormRollbackTest {

    private static Opportunity setupBooking() {
        Account primary = new Account(Name = 'Primary Buyer', First_Name__c = 'Primary', Last_Name__c = 'Buyer', Email__c = 'primary.buyer@example.com', Phone = '9000000001');
        insert primary;
        insert new Contact(LastName = 'Buyer', FirstName = 'Primary', Email = 'primary.buyer@example.com', AccountId = primary.Id, Phone = '9000000001');
        Opportunity opp = new Opportunity(Name = 'Booking Rollback Opp', StageName = 'Prospecting', CloseDate = System.today().addDays(10), AccountId = primary.Id);
        insert opp;
        return opp;
    }

    private static List<Account> coApplicants(String secondEmail) {
        return new List<Account>{
            new Account(Name = 'Second Applicant', First_Name__c = 'Second', Last_Name__c = 'Applicant', Email__c = secondEmail, Phone = '9000000002')
        };
    }

    private static Account primaryOf(Opportunity opp) {
        Account a = [SELECT Id, Name, First_Name__c, Last_Name__c, Email__c, Phone FROM Account WHERE Id = :opp.AccountId];
        return new Account(Id = a.Id, Name = a.Name, First_Name__c = a.First_Name__c, Last_Name__c = a.Last_Name__c, Email__c = a.Email__c, Phone = a.Phone);
    }

    @isTest
    static void bookingFormSavesNothingOnErrorAndRetryGivesOneCoApplicant() {
        Opportunity opp = setupBooking();
        Test.startTest();
        String failed = bookingFormController.createApplicants(coApplicants('not-an-email'), opp.Id, '[]', opp.AccountId, primaryOf(opp));
        System.assert(!failed.startsWith('Success'), failed);
        System.assertEquals(0, [SELECT COUNT() FROM Applicant__c WHERE Opportunity__c = :opp.Id], 'nothing saved on error');
        System.assertEquals(0, [SELECT COUNT() FROM Account WHERE Name = 'Second Applicant']);

        String ok = bookingFormController.createApplicants(coApplicants('second.applicant@example.com'), opp.Id, '[]', opp.AccountId, primaryOf(opp));
        Test.stopTest();
        System.assert(ok.startsWith('Success'), ok);
        List<Applicant__c> apps = [SELECT Account__r.Email__c FROM Applicant__c WHERE Opportunity__c = :opp.Id];
        System.assertEquals(1, apps.size(), 'exactly the corrected 2nd applicant');
        System.assertEquals('second.applicant@example.com', apps[0].Account__r.Email__c);
    }

    @isTest
    static void editApplicantDetailsSavesNothingOnErrorAndRetryGivesOneCoApplicant() {
        Opportunity opp = setupBooking();
        Test.startTest();
        try {
            bookingFormButtonController.createApplicants(coApplicants('not-an-email'), opp.Id, '[]', opp.AccountId, primaryOf(opp), null, null);
            System.assert(false, 'expected an error');
        } catch (AuraHandledException e) {
            System.assert(String.isNotBlank(e.getMessage()));
        }
        System.assertEquals(0, [SELECT COUNT() FROM Applicant__c WHERE Opportunity__c = :opp.Id], 'nothing saved on error');
        System.assertEquals(0, [SELECT COUNT() FROM Account WHERE Name = 'Second Applicant']);

        bookingFormButtonController.createApplicantsWrapper ok = bookingFormButtonController.createApplicants(coApplicants('second.applicant@example.com'), opp.Id, '[]', opp.AccountId, primaryOf(opp), null, null);
        Test.stopTest();
        System.assertNotEquals(null, ok.accNumberByIdMap);
        System.assertEquals(1, [SELECT COUNT() FROM Applicant__c WHERE Opportunity__c = :opp.Id], 'exactly the corrected 2nd applicant');
    }
}