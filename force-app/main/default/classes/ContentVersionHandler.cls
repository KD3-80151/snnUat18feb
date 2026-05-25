public without Sharing  class ContentVersionHandler {
    public void publicizeFiles(List<ContentVersion> newRecords) {
        if(!newRecords.isEmpty()){
            for(ContentVersion conVer : newRecords){
                conVer.SharingPrivacy = 'P';//Public
            }
        }
    }

    public void createConDocLink(List<ContentVersion> newRecords){
        if(!newRecords.isEmpty()){
            List<ContentDistribution> cDisToInsert = new List<ContentDistribution>();
            List<ContentDocumentLink> cdlToInsert = new List<ContentDocumentLink>();
            for(ContentVersion conVer : newRecords){
                ContentDistribution cdl = new ContentDistribution();
                cdl.ContentVersionId = conVer.Id;
                cdl.Name = 'PublicShare';
                cdl.PreferencesAllowViewInBrowser = true;
                cdl.PreferencesLinkLatestVersion = true;
                cdl.PreferencesAllowOriginalDownload = true;
                cDisToInsert.add(cdl);
                ContentDocumentLink conDocLink = New ContentDocumentLink();
                conDocLink.LinkedEntityId =System.label.Channel_Partner_User_Id;
                conDocLink.ContentDocumentId = conVer.ContentDocumentId;  //ContentDocumentId Id from ContentVersion
                conDocLink.shareType = 'V';
                cdlToInsert.add(conDocLink);
            }
            if(!cdlToInsert.isEmpty()){
                insert cdlToInsert;
            }
            if(!cDisToInsert.isEmpty()){
                insert cDisToInsert;
            }
        }
    }
}