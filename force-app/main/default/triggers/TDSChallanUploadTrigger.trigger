trigger TDSChallanUploadTrigger on TDS_Challan_Upload__e (after insert) {
    // Customer uploaded a TDS Challan from the portal: tell the booking owner (client, Nov 2026).
    TdsChallanNotificationService.notifyOwners(Trigger.new);
}