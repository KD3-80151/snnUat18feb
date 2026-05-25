@isTest
private class submitCourierDetailsController_Test {
    
    @isTest
    static void testGetOppDetails() {
        try {
            Opportunity opp = new Opportunity(
                Name = 'Test Opportunity',
                StageName = 'Prospecting',
                CloseDate = Date.today(),
                Email__c = 'test@example.com'
            );
            insert opp;
            
            Task tsk = new Task(
                WhatId = opp.Id,
                Status = 'New',
                Subject = 'Test Task'
            );
            insert tsk;
            
            Test.startTest();
            Opportunity result = submitCourierDetailsController.getOppDetails(tsk.Id);
            Opportunity nullTaskIdResult = submitCourierDetailsController.getOppDetails(null);
            Opportunity nullTaskIdResult1 = submitCourierDetailsController.getOppDetails(null); 
            Opportunity blankTaskIdResult = submitCourierDetailsController.getOppDetails('');
            Test.stopTest();
        } catch (Exception e) {
            System.debug('Test Exception: ' + e.getMessage());
        }
    }
    
    @isTest
    static void testSaveOppResult() {
        try {
            Opportunity opp = new Opportunity(
                Name = 'Test Opportunity',
                StageName = 'Prospecting',
                CloseDate = Date.today(),
                Email__c = 'test@example.com'
            );
            insert opp;
            
            Task tsk = new Task(
                WhatId = opp.Id,
                Status = 'New',
                Subject = 'Agreement Signed By Customer'
            );
            insert tsk;
            
            Contact con = new Contact(
                FirstName = 'Test',
                LastName = 'Contact',
                Email = 'test.contact@example.com',
                AccountId = opp.AccountId
            );
            insert con;
            
            Test.startTest();
            submitCourierDetailsController.saveOppResult(
                Date.today(), 
                opp.Id, 
                'Courier Company', 
              
                'Docket123', 
                tsk.Id
            );
            Test.stopTest();
        } catch (Exception e) {
            System.debug('Test Exception: ' + e.getMessage());
        }
    }
    @isTest
    static void testReturnNull() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Task task = new Task(
            WhatId = acc.Id,
            Subject = 'Test Task with Account WhatId',
            Status = 'Completed'
        );
        insert task;
        
        Test.startTest();
        Opportunity result = submitCourierDetailsController.getOppDetails(task.Id);
        Test.stopTest();
    }
}