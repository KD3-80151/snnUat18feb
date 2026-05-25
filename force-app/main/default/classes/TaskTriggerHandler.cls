public with sharing class TaskTriggerHandler {
    public static void handleActivitiesBeforeAnyUpdate(List<task> newRecords, Map<Id,Task> oldMap){
        for (Task newTask : newRecords) {
            Task oldTask = oldMap.get(newTask.Id);

            if (oldTask.Status == 'Completed' && hasFieldChanged(newTask, oldTask)) {
                system.debug('newTask ==> ' + newTask);
                system.debug('oldTask ==> ' + oldTask);
                system.debug('hasFieldChanged(newTask, oldTask) ===> '+hasFieldChanged(newTask, oldTask));
                newTask.addError('You cannot update a Task that is completed.');
            }
        }
    }

    private static Boolean hasFieldChanged(Task newTask, Task oldTask) {
        Map<String, Schema.SObjectField> taskFields = Schema.SObjectType.Task.fields.getMap();
        for (String fieldName : taskFields.keySet()) {
            system.debug('fieldName ====> '+fieldName);
            // Skip the WhatId field for this check
            if (fieldName == 'WhoId' || fieldName == 'WhatId') {
                continue;
            }
            
            Object newValue = newTask.get(fieldName);
            Object oldValue = oldTask.get(fieldName);
            system.debug('newValue ====> ' + newValue);
            system.debug('oldValue ====> ' + oldValue);

            // If newValue is null and oldValue is not null, or vice versa
            if ((newValue == null && oldValue != null) || (newValue != null && oldValue == null)) {
                return true;
            }

            // If both are not null and they are not equal
            if (newValue != null && !newValue.equals(oldValue)) {
                return true;
            }
        }

        // Check if WhatId field specifically has changed
        if (newTask.WhoId != oldTask.WhoId || newTask.WhatId != oldTask.WhatId) {
            system.debug('WhatId has changed');
            return false; // Indicate that the validation should be bypassed
        }

        return false;
    }

    //platform events trigger
    public static void processTaskEvents(List<Task> newTasks, List<Task> oldTasks, Boolean isInsert, Boolean isUpdate, Boolean isDelete) {
        List<TaskChangeEvent__e> events = new List<TaskChangeEvent__e>();

        if (isInsert || isUpdate) {
            for (Task task : newTasks) {
                if (task.WhoId != null && task.WhoId.getSObjectType() == Lead.SObjectType) {
                    TaskChangeEvent__e event = new TaskChangeEvent__e(
                        TaskId__c = task.Id, 
                        Operation__c = isInsert ? 'Create' : 'Update'
                    );
                    events.add(event);
                }
            }
        }

        if (isDelete) {
            for (Task task : oldTasks) {
                if (task.WhoId != null && task.WhoId.getSObjectType() == Lead.SObjectType) {
                    TaskChangeEvent__e event = new TaskChangeEvent__e(
                        TaskId__c = task.Id, 
                        Operation__c = 'Delete' 
                    );
                    events.add(event);
                }
            }
        }
        //publish
        if (!events.isEmpty()) {
            EventBus.publish(events);
        }
    }

    // public static void createUnitTransferNotes(List<Task> newList, Map<Id, Task> oldMap) {
    //     Set<Id> caseIds = new Set<Id>();

    //     if(newList == null || newList.isEmpty() || oldMap == null) {
    //         return; // No tasks to process
    //     }
    //     for (Task t : newList) {
    //         Task oldT = oldMap.get(t.Id);

    //         if (
    //             t.Status == 'Completed' && oldT.Status != 'Completed' && t.Subject == 'Receipt Transfer is successful please verify' && t.WhatId != null && String.valueOf(t.WhatId).startsWith('500')) {
    //             caseIds.add(t.WhatId);
    //         }
    //     }

    //     if (caseIds.isEmpty()) return;
        
    //     Map<Id, Case> caseMap = new Map<Id, Case>();
    //     List<Case> unitTransferCases = new List<Case>();
        
    //     String unitTransferRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Unit Transfer').getRecordTypeId();
        
    //     unitTransferCases= [ SELECT Id, RecordTypeId, Opportunity__c, From_Unit__c, To_Unit__c FROM Case WHERE Id IN :caseIds AND RecordTypeId = :unitTransferRTId Limit 1];
    //     String fromUnit = unitTransferCases[0].From_Unit__c;
    //     String toUnit = unitTransferCases[0].To_Unit__c;
    //     Id oppId = unitTransferCases[0].Opportunity__c;


    //     List<ContentNote> notesToInsert = new List<ContentNote>();

    //     for (Case c : unitTransferCases) {
    //         ContentNote note = new ContentNote();
    //         note.Title = 'Unit Transfer Successful from ' + fromUnit + ' to ' + toUnit;
    //         note.Content = Blob.valueOf('The unit transfer for this case has been successfully completed.');
    //         note.OwnerId = UserInfo.getUserId();
    //         caseMap.put(c.Id, c);
    //     }
    //     if (caseMap.isEmpty()) return;

    //     if (notesToInsert.isEmpty()) return;

    //     insert notesToInsert;
    //     Set<Id> noteVersionIds = new Set<Id>();
    //     for (ContentNote cn : notesToInsert) {
    //         noteVersionIds.add(cn.Id); 
    //     }

    //     Map<Id, Id> noteIdToDocId = new Map<Id, Id>();
    //     list<ContentDocument> contentDocs = [
    //         SELECT Id, LatestPublishedVersionId FROM ContentDocument WHERE LatestPublishedVersionId IN :noteVersionIds
    //     ];
    //     for (ContentDocument doc : contentDocs) {
    //         noteIdToDocId.put(doc.LatestPublishedVersionId, doc.Id);
    //     }

    //     List<ContentDocumentLink> links = new List<ContentDocumentLink>();
    //     Integer idx = 0;
    //     for (Case c : caseMap.values()) {
    //         Id noteId = notesToInsert[idx].Id;
    //         Id docId = noteIdToDocId.get(noteId);
    //         if (docId != null) {
    //             ContentDocumentLink link = new ContentDocumentLink();
    //             link.ContentDocumentId = docId;
    //             link.LinkedEntityId = oppId;//c.Id; // link to Case
    //             link.ShareType = 'V';
    //             link.Visibility = 'AllUsers';
    //             links.add(link);
    //         }
    //         idx++;
    //     }

    //     if (!links.isEmpty()) {
    //         insert links;
    //     }
    // }

    public static void createUnitTransferNotes(List<Task> newList, Map<Id, Task> oldMap) {
        try{
        Set<Id> caseIds = new Set<Id>();
        for (Task t : newList) {
            Task oldT = (oldMap == null) ? null : oldMap.get(t.Id);
            Boolean movedToCompleted = t.Status == 'Completed' && (oldT == null || oldT.Status != 'Completed');

            if (movedToCompleted
                && t.Subject == 'Receipt Transfer is successful please verify'
                && t.WhatId != null
                && String.valueOf(t.WhatId).startsWith('500')) {
                caseIds.add(t.WhatId);
            }
        }
        System.debug('caseIds collected: ' + caseIds);
        if (caseIds.isEmpty()) return;

        Id unitTransferRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Unit Transfer').getRecordTypeId();

        System.debug('unitTransferRTId: ' + unitTransferRTId);
        List<Case> unitTransferCases = [
            SELECT Id, CaseNumber, From_Unit__c, To_Unit__c, From_Unit__r.Name, To_Unit__r.Name, Opportunity__c FROM Case WHERE Id IN :caseIds AND RecordTypeId = :unitTransferRTId AND Opportunity__c != null limit 1
        ];
        if (unitTransferCases.isEmpty()) return;
        System.debug('unitTransferCases found: ' + unitTransferCases.size());

        List<ContentNote> notes = new List<ContentNote>();
        for (Case c : unitTransferCases) {
            String title = 'Unit Transfer Successful: ' + (c.From_Unit__r.Name == null ? '' : c.From_Unit__r.Name)
                         + ' to ' + (c.To_Unit__r.Name == null ? '' : c.To_Unit__r.Name);
            String body  = 'Case ' + c.CaseNumber + ': The unit transfer has been successfully completed.';

            notes.add(new ContentNote(
                Title   = title,
                Content = Blob.valueOf(body),
                OwnerId = UserInfo.getUserId()
            ));
        }
        insert notes;
        System.debug('ContentNotes created: ' + notes.size());

        ContentDocumentLink links = new ContentDocumentLink();
        links.ContentDocumentId = notes[0].Id;
        links.linkedEntityId = unitTransferCases[0].Opportunity__c; // Link to Opportunity
        links.ShareType = 'V'; // Viewer
        links.Visibility = 'AllUsers';
        insert links;
        System.debug('link====>'+links);
    }
        catch(Exception e) {
        System.debug('Error in createUnitTransferNotes: ' + e.getMessage() + ' at line ' + e.getLineNumber());
    }   
        
    }
}