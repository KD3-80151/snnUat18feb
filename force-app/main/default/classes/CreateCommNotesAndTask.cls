public with sharing class CreateCommNotesAndTask {

    public static final String FOLLOW_UP_TASK_SUBJECT = 'Take Follow Up with Customer';

    @AuraEnabled
    public static void createCommNotesAndTask(String recordId, String title, String remarks, Datetime nextFollowUpDateTime){
        if(String.isBlank(recordId)){
            throw new AuraHandledException('Lead Id is missing.');
        }
        if(String.isBlank(title) || String.isBlank(remarks)){
            throw new AuraHandledException('Title and Remarks are required.');
        }

        Savepoint sp = Database.setSavepoint();
        try{
            Communication_Notes__c commNote = new Communication_Notes__c(
                Lead__c = recordId,
                Title__c = title.trim(),
                Remarks__c = remarks.trim()
            );
            insert commNote;

            if(nextFollowUpDateTime != null){
                update new Lead(Id = recordId, Next_Follow_Up_Date_Time__c = nextFollowUpDateTime);

                Date dueDate = nextFollowUpDateTime.date();
                List<Task> existingTasks = [SELECT Id FROM Task WHERE WhoId = :recordId AND Subject = :FOLLOW_UP_TASK_SUBJECT AND ActivityDate = :dueDate
                                            AND IsClosed = false ORDER BY CreatedDate DESC LIMIT 1];

                Task followUpTask = existingTasks.isEmpty() ? new Task(WhoId = recordId, Subject = FOLLOW_UP_TASK_SUBJECT, Status = 'Not Started', Priority = 'Normal', OwnerId = recordId)
                    : existingTasks[0];
                followUpTask.ActivityDate = dueDate;
                followUpTask.IsReminderSet = true;
                followUpTask.ReminderDateTime = nextFollowUpDateTime;
                followUpTask.Description = title.trim() + '\n' + remarks.trim();
                upsert followUpTask;
            }
        }
        catch(Exception e){
            Database.rollback(sp);
            throw new AuraHandledException(e.getMessage());
        }
    }
}
