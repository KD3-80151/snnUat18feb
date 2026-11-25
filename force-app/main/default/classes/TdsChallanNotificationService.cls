/**
 * Notifies the booking (Opportunity) owner when the customer uploads a TDS Challan from the
 * Customer Portal (client, Nov 2026). Runs from the TDS_Challan_Upload__e subscriber, i.e. as the
 * Automated Process user, because the portal itself runs as the site guest user.
 */
public without sharing class TdsChallanNotificationService {

    public static final String NOTIFICATION_TYPE = 'TDS_Challan_Uploaded';

    /** Number of notifications handed to Salesforce in this transaction (used by tests). */
    @TestVisible
    private static Integer sentCount = 0;

    public static void notifyOwners(List<TDS_Challan_Upload__e> events) {
        if (events == null || events.isEmpty()) {
            return;
        }
        Set<Id> oppIds = new Set<Id>();
        for (TDS_Challan_Upload__e e : events) {
            Id oppId = toId(e.Opportunity_Id__c);
            if (oppId != null) {
                oppIds.add(oppId);
            }
        }
        if (oppIds.isEmpty()) {
            return;
        }

        List<CustomNotificationType> types = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = :NOTIFICATION_TYPE LIMIT 1];
        if (types.isEmpty()) {
            System.debug(LoggingLevel.ERROR, 'Custom notification type ' + NOTIFICATION_TYPE + ' is missing; TDS Challan notification not sent.');
            return;
        }
        Map<Id, Opportunity> opps = new Map<Id, Opportunity>([
            SELECT Id, Name, OwnerId, Owner.IsActive, Account.Name
            FROM Opportunity WHERE Id IN :oppIds
        ]);

        for (TDS_Challan_Upload__e e : events) {
            Opportunity opp = opps.get(toId(e.Opportunity_Id__c));
            if (opp == null || opp.OwnerId == null || opp.Owner.IsActive != true) {
                System.debug(LoggingLevel.WARN, 'TDS Challan notification skipped (no active owner) for ' + e.Opportunity_Id__c);
                continue;
            }
            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setNotificationTypeId(types[0].Id);
            notification.setTargetId(opp.Id);
            notification.setTitle('TDS Challan uploaded by customer');
            notification.setBody(buildBody(opp, e.File_Name__c));
            try {
                notification.send(new Set<String>{ opp.OwnerId });
                sentCount++;
            } catch (Exception ex) {
                System.debug(LoggingLevel.ERROR, 'TDS Challan notification failed for ' + opp.Id + ': ' + ex.getMessage());
            }
        }
    }

    @TestVisible
    private static String buildBody(Opportunity opp, String fileName) {
        String customer = (opp.Account != null && String.isNotBlank(opp.Account.Name)) ? ' ' + opp.Account.Name : '';
        String body = 'TDS Challan has been uploaded by customer' + customer + ' for ' + opp.Name + '.'
            + (String.isNotBlank(fileName) ? ' File: ' + fileName + ' (TDS Uploaded Docs folder).' : '')
            + ' Please verify and create a TDS Receipt.';
        return body.abbreviate(750);
    }

    private static Id toId(String value) {
        if (String.isBlank(value)) {
            return null;
        }
        try {
            return Id.valueOf(value);
        } catch (Exception e) {
            return null;
        }
    }
}