@isTest
public class generateDebitNoteQueueableTest {
	@isTest
    static void testgenerateDebitNoteQueueable() {
        Test.startTest();
        System.enqueueJob(new generateDebitNoteQueueable(new List<Id>{'a0ADy000002ARnAMAW'}));
    }
}