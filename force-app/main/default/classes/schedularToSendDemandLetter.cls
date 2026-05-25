public without sharing class schedularToSendDemandLetter implements Schedulable{

    public void execute(SchedulableContext sc) {
        BatchToSendReminderOnPaymentDueDate batch = new BatchToSendReminderOnPaymentDueDate();
        Database.executeBatch(batch);
    }
}