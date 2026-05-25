@isTest
public class DummyClassTest {
	@isTest
    static void testCoverage(){
        Test.startTest();
        DummyClass.testCover02();
        DummyClass.testCover03();
        DummyClass.testCover04();
        Test.stopTest();
    }
}