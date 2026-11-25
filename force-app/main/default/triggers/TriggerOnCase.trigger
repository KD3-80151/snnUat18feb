trigger TriggerOnCase on Case (before insert, before update) {
    // Unit transfer checks (client, 21 Nov 2026): credit/debit notes must be cancelled first,
    // and the new booking must have its payment schedule generated.
    CaseTriggerHandler.validateUnitTransfer(Trigger.new, Trigger.isUpdate ? Trigger.oldMap : null);
}