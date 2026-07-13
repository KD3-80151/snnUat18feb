@IsTest
private class DeleteOppApprovalControllerTest {
    @IsTest
    static void submitForApprovalMarksOpportunityPending() {
        Opportunity opp = new Opportunity(
            Name = 'Submit Delete Approval Test',
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;

        Test.startTest();
        DeleteOppApprovalController.submitForApproval(opp.Id);
        Test.stopTest();

        Opportunity updatedOpp = [
            SELECT Delete_Approval__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];
        System.assertEquals('Pending', updatedOpp.Delete_Approval__c);
    }

    @IsTest
    static void deleteRelatedRecordsRunsWhenDeleteApprovalIsApproved() {
        Unit__c unit = new Unit__c(
            Status__c = 'For Sale'
        );
        insert unit;

        Opportunity opp = new Opportunity(
            Name = 'Delete Related Records Test',
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(30),
            Unit__c = unit.Id,
            Delete_Approval__c = 'Pending'
        );
        insert opp;

        Company__c company = new Company__c(
            Name = 'Delete Approval Company',
            Email__c = 'delete.approval@example.com',
            Phone__c = '9999999999',
            Registration_Number__c = 'DELAPP',
            Company_Code__c = 'DEL'
        );
        insert company;

        Project__c project = new Project__c(
            Name = 'Delete Approval Project',
            Project_Code__c = 'DAP',
            Project_Status__c = 'Planning',
            Project_Start_Date__c = Date.today(),
            Project_End_Date__c = Date.today().addMonths(6),
            Company__c = company.Id
        );
        insert project;

        Cost_Sheet_Template__c template = new Cost_Sheet_Template__c(
            Company__c = company.Id,
            Project__c = project.Id
        );
        insert template;

        Cost_Scheme_Linking__c schemeLinking = new Cost_Scheme_Linking__c(
            Cost_Sheet_Template__c = template.Id
        );
        insert schemeLinking;

        Cost_Sheet__c costSheet = new Cost_Sheet__c(
            Opportunity__c = opp.Id,
            Cost_Scheme_Linking__c = schemeLinking.Id,
            Unit__c = unit.Id
        );
        insert costSheet;

        Payment_Schedule__c paymentSchedule = new Payment_Schedule__c(
            Opportunity__c = opp.Id
        );
        insert paymentSchedule;

        Test.startTest();
        opp.Delete_Approval__c = 'Approved';
        update opp;
        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT COUNT() FROM Payment_Schedule__c WHERE Opportunity__c = :opp.Id],
            'Payment schedules should be deleted after delete approval is approved.'
        );

        Opportunity updatedOpp = [
            SELECT Unit__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];
        System.assertEquals(null, updatedOpp.Unit__c, 'Opportunity Unit should be cleared.');

        Cost_Sheet__c updatedCostSheet = [
            SELECT Cost_Scheme_Linking__c
            FROM Cost_Sheet__c
            WHERE Id = :costSheet.Id
        ];
        System.assertEquals(null, updatedCostSheet.Cost_Scheme_Linking__c, 'Cost scheme linking should be cleared.');

        System.assertEquals(
            1,
            [SELECT COUNT() FROM Task WHERE WhatId = :opp.Id AND Subject = 'Generate Cost Sheet'],
            'Generate Cost Sheet task should be created.'
        );
    }
}
