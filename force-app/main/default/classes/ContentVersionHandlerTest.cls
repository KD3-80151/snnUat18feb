@isTest(seeAllData=true) 
public class ContentVersionHandlerTest {

    private static ContentVersion createTestContentVersion() {
        ContentVersion cv = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'TestFile.pdf',
            VersionData = Blob.valueOf('Test File Content'),
            IsMajorVersion = true
        );
        insert cv; 
        return cv; 
    }

    @isTest
    static void testPublicizeFiles() {

        ContentVersion cv = createTestContentVersion();
        List<ContentVersion> cvList = new List<ContentVersion>{cv};

        Test.startTest();
        new ContentVersionHandler().publicizeFiles(cvList);
        Test.stopTest();

        
    }

   @isTest(seeAllData=true)
static void testCreateConDocLink() {

    ContentVersion cv = new ContentVersion(
        Title = 'Test File',
        PathOnClient = 'TestFile.pdf',
        VersionData = Blob.valueOf('Test Content')
    );
    insert cv;

    List<ContentVersion> cvList = new List<ContentVersion>{cv};

    Test.startTest();
    try {
        new ContentVersionHandler().createConDocLink(cvList);
    } catch (Exception e) {
        
    }
    Test.stopTest();

    
}

}