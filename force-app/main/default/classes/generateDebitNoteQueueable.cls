public without sharing class generateDebitNoteQueueable implements Queueable, Database.allowsCallouts{
    public List<String> paymentSchId;

    public generateDebitNoteQueueable(List<String> paymentSchId) {
        this.paymentSchId = paymentSchId;
    }

    public void execute(QueueableContext context) {
        digioRepository.generateDebitNoteWrapper(paymentSchId);
    }
}