public without sharing class digioSubRepository {
    
    @AuraEnabled
    public static docwrpperClass generateVehicleParkingDocument(String recordId){
        try{
            if(recordId != null){
                List<Opportunity> oppDetails = [SELECT Id,Name,(SELECT Id,Document_Id__c from Documents__r where Name = 'Post Sales' LIMIT 1) from Opportunity where Id =: recordId LIMIT 1];
                String parentFolderId;
                String docId;
                String subDocUrl = '';
                docwrpperClass wrapperRec = new docwrpperClass();
                System.debug('oppDetails::'+oppDetails);
                if(!oppDetails.isEmpty() && oppDetails[0].Documents__r != null){
                    parentFolderId = oppDetails[0].Documents__r[0].Document_Id__c;
                    docId = oppDetails[0].Documents__r[0].Id;
                }
                
                Digio_Integration__c customData = Digio_Integration__c.getValues('Digio');
                if(customData.Authorization__c != null && customData.Endpoint_URL__c != null && customData.Vehicle_Parking_And_Stickers_Policy__c != null && parentFolderId != null){
                    String endpoint = customData.Endpoint_URL__c + '/v2/client/template/multi_templates/create_sign_request';
                    DigioWrapperClass.generateVehicleParkingWrapper generateDoc = new DigioWrapperClass.generateVehicleParkingWrapper();
                    String fileName = 'Vehicle Parking & Stickers Policy';
                    generateDoc.file_name = fileName;
                    DigioWrapperClass.signersList signer = new DigioWrapperClass.signersList();
                    signer.identifier = 'salesforce@snnestates.com';
                    signer.signer_tag = 'Signer 1';
                    signer.name = 'SNN Estates';
                    signer.sign_type = 'document_review';
                    generateDoc.signers = new List<DigioWrapperClass.signersList>{signer};
                    
                    DigioWrapperClass.vehicleParkingTemplateList tempList = new DigioWrapperClass.vehicleParkingTemplateList();
                    tempList.template_key = customData.Vehicle_Parking_And_Stickers_Policy__c;
                    generateDoc.templates = new List<DigioWrapperClass.vehicleParkingTemplateList>{tempList};
                    String jsonBody = Json.serialize(generateDoc);
                    String digiDocId = digioCalloutUtility.sendHttpRequest('POST', endpoint, customData.Authorization__c, jsonBody);
                    wrapperRec.digiDocId = digiDocId;
                    if(digiDocId != null && fileName != null){
                        subDocUrl = digioCalloutUtility.downloadDocument(digiDocId, fileName, parentFolderId, docId);
                        wrapperRec.subDocUrl = subDocUrl;
                    }
                }
                return wrapperRec;
            }
            return null;
        }catch(Exception e){
            system.debug('Error in generateVettedReceiptDocument===> ' + e.getMessage());
            system.debug('Error line ===> ' + e.getLineNumber());
            return null;
        }
    }
    Public class docwrpperClass{
        @AuraEnabled public String subDocUrl;
        @AuraEnabled public String digiDocId;
    }
    
    @AuraEnabled
    public static docwrpperClass generateServiceProviderContactsListDoc(String recordId){
        try{
            if(recordId != null){
                List<Opportunity> oppDetails = [SELECT Id,Name,(SELECT Id,Document_Id__c from Documents__r where Name = 'Post Sales' LIMIT 1) from Opportunity where Id =: recordId LIMIT 1];
                String parentFolderId;
                String docId;
                String subDocUrl = '';
                docwrpperClass wrapperRec = new docwrpperClass();
                if(!oppDetails.isEmpty() && oppDetails[0].Documents__r != null){
                    parentFolderId = oppDetails[0].Documents__r[0].Document_Id__c;
                    docId = oppDetails[0].Documents__r[0].Id;
                }
                
                Digio_Integration__c customData = Digio_Integration__c.getValues('Digio');
                if(customData.Authorization__c != null && customData.Endpoint_URL__c != null && customData.Contact_Service_List_Template_Key__c != null && parentFolderId != null){
                    String endpoint = customData.Endpoint_URL__c + '/v2/client/template/multi_templates/create_sign_request';
                    DigioWrapperClass.generateContactListWrapper generateDoc = new DigioWrapperClass.generateContactListWrapper();
                    String fileName = 'Contact Details of Service Providers';
                    generateDoc.file_name = fileName;
                    
                    DigioWrapperClass.signersList signer = new DigioWrapperClass.signersList();
                    signer.identifier = 'salesforce@snnestates.com';
                    signer.signer_tag = 'Signer 1';
                    signer.name = 'SNN Estates';
                    signer.sign_type = 'document_review';
                    generateDoc.signers = new List<DigioWrapperClass.signersList>{signer};
                    
                    DigioWrapperClass.serviceContactsTemplateList tempList = new DigioWrapperClass.serviceContactsTemplateList();
                    tempList.template_key = customData.Contact_Service_List_Template_Key__c;
                    generateDoc.templates = new List<DigioWrapperClass.serviceContactsTemplateList>{tempList};
                    String jsonBody = Json.serialize(generateDoc);
                    String digiDocId = digioCalloutUtility.sendHttpRequest('POST', endpoint, customData.Authorization__c, jsonBody);
                    wrapperRec.digiDocId = digiDocId;
                    if(digiDocId != null && fileName != null){
                        subDocUrl = digioCalloutUtility.downloadDocument(digiDocId, fileName, parentFolderId, docId);
                        wrapperRec.subDocUrl = subDocUrl;
                    }
                }
                return wrapperRec;
            }
            return null;
        }catch(Exception e){
            system.debug('Error in generateVettedReceiptDocument===> ' + e.getMessage());
            system.debug('Error line ===> ' + e.getLineNumber());
            return null;
        }
    }
    
    @AuraEnabled
    public static docwrpperClass generateMoveInMoveOutDocument(String recordId){
        try{
            if(recordId != null){
                List<Opportunity> oppDetails = [SELECT Id,Name,AccountId,Unit__r.Name,(SELECT Id,Document_Id__c from Documents__r where Name = 'Post Sales' LIMIT 1) from Opportunity where Id =: recordId LIMIT 1];
                List<Contact> contactList;
                String parentFolderId;
                String docId;
                String subDocUrl = '';
                docwrpperClass wrapperRec = new docwrpperClass();
                if(!oppDetails.isEmpty() && oppDetails[0].AccountId != null){
                    contactList = [SELECT Id,Name,Email,Phone from Contact where AccountId =: oppDetails[0].AccountId order by createdDate Desc Limit 1];
                }
                if(!oppDetails.isEmpty() && oppDetails[0].Documents__r != null){
                    parentFolderId = oppDetails[0].Documents__r[0].Document_Id__c;
                    docId = oppDetails[0].Documents__r[0].Id;
                }
                
                Digio_Integration__c customData = Digio_Integration__c.getValues('Digio');
                if(!oppDetails.isEmpty() && customData.Authorization__c != null && customData.Endpoint_URL__c != null && customData.MoveIn_MoveOut_Template_Key__c != null && !contactList.isEmpty() && parentFolderId != null){
                    String endpoint = customData.Endpoint_URL__c + '/v2/client/template/multi_templates/create_sign_request';
                    DigioWrapperClass.generateMoveInOutWrapper generateDoc = new DigioWrapperClass.generateMoveInOutWrapper();
                    String fileName = 'Move-In & Move-Out Policy';
                    generateDoc.file_name = fileName;
                    
                    DigioWrapperClass.signersList signer = new DigioWrapperClass.signersList();
                    signer.identifier = 'salesforce@snnestates.com';
                    signer.signer_tag = 'Signer 1';
                    signer.name = 'SNN Estates';
                    signer.sign_type = 'document_review';
                    generateDoc.signers = new List<DigioWrapperClass.signersList>{signer};
                    
                    DigioWrapperClass.moveInOutTemplateList tempList = new DigioWrapperClass.moveInOutTemplateList();
                    tempList.template_key = customData.MoveIn_MoveOut_Template_Key__c;
                    DigioWrapperClass.moveInOutTemplateValues templateVariables = new DigioWrapperClass.moveInOutTemplateValues();
                    templateVariables.ApplicationDate   = System.today();
                    templateVariables.ContactMobile     = contactList[0].Phone != null ? contactList[0].Phone : '';
                    templateVariables.ResidentName      = contactList[0].Name != null ? contactList[0].Name : '';
                    templateVariables.UnitNumber        = oppDetails[0].Unit__r.Name != null ? oppDetails[0].Unit__r.Name : '';
                    templateVariables.ContactEmail      = contactList[0].Email != null ? contactList[0].Email : '';
                    
                    tempList.template_values = templateVariables;
                    generateDoc.templates = new List<DigioWrapperClass.moveInOutTemplateList>{tempList};
                    String jsonBody = Json.serialize(generateDoc);
                    String digiDocId = digioCalloutUtility.sendHttpRequest('POST', endpoint, customData.Authorization__c, jsonBody);
                    wrapperRec.digiDocId = digiDocId;
                    if(digiDocId != null && fileName != null){
                        subDocUrl = digioCalloutUtility.downloadDocument(digiDocId, fileName, parentFolderId, docId);
                        wrapperRec.subDocUrl = subDocUrl;
                    }
                }
                return wrapperRec;
            }
            return null;
        }catch(Exception e){
            system.debug('Error in generateVettedReceiptDocument===> ' + e.getMessage());
            system.debug('Error line ===> ' + e.getLineNumber());
            return null;
        }
    }
    
    @AuraEnabled
    public static docwrpperClass generatePartyHallRulesDocument(String recordId){
        try{
            System.debug('recordId ===> ' + recordId);
            if(recordId != null){
                List<Opportunity> oppDetails = [SELECT Id,Name,AccountId,Unit__r.Name,Booking_Date__c,(SELECT Id,Document_Id__c from Documents__r where Name = 'Post Sales' LIMIT 1) from Opportunity where Id =: recordId LIMIT 1];
                List<Contact> contactList;
                String parentFolderId;
                String docId;
                String subDocUrl = '';
                docwrpperClass wrapperRec = new docwrpperClass();
                if(!oppDetails.isEmpty() && oppDetails[0].AccountId != null){
                    contactList = [SELECT Id,Name,Email,Phone,Alternate_Phone__c from Contact where AccountId =: oppDetails[0].AccountId order by createdDate Desc Limit 1];
                }
                if(!oppDetails.isEmpty() && oppDetails[0].Documents__r != null){
                    parentFolderId = oppDetails[0].Documents__r[0].Document_Id__c;
                    docId = oppDetails[0].Documents__r[0].Id;
                }
                
                Digio_Integration__c customData = Digio_Integration__c.getValues('Digio');
                if(!oppDetails.isEmpty() && customData.Authorization__c != null && customData.Endpoint_URL__c != null && customData.Party_Hall_Rules_Temaplate_Key__c != null && !contactList.isEmpty() && parentFolderId != null){
                    String endpoint = customData.Endpoint_URL__c + '/v2/client/template/multi_templates/create_sign_request';
                    DigioWrapperClass.generatePartyHallRulesWrapper generateDoc = new DigioWrapperClass.generatePartyHallRulesWrapper();
                    String fileName = 'Party Hall Rules';
                    generateDoc.file_name = fileName;
                    
                    DigioWrapperClass.signersList signer = new DigioWrapperClass.signersList();
                    signer.identifier = 'salesforce@snnestates.com';
                    signer.signer_tag = 'Signer 1';
                    signer.name = 'SNN Estates';
                    signer.sign_type = 'document_review';
                    generateDoc.signers = new List<DigioWrapperClass.signersList>{signer};
                    
                    DigioWrapperClass.partyHallRulesTemplateList tempList = new DigioWrapperClass.partyHallRulesTemplateList();
                    tempList.template_key = customData.Party_Hall_Rules_Temaplate_Key__c;
                    DigioWrapperClass.partyHallRulesTemplateValues templateVariables = new DigioWrapperClass.partyHallRulesTemplateValues();
                    templateVariables.OppBookingDate    = oppDetails[0].Booking_Date__c != null ? oppDetails[0].Booking_Date__c : null;
                    templateVariables.ResidentPhone     = contactList[0].Phone != null ? contactList[0].Phone : '';
                    templateVariables.ResidentName      = contactList[0].Name != null ? contactList[0].Name : '';
                    templateVariables.UnitNumber        = oppDetails[0].Unit__r.Name != null ? oppDetails[0].Unit__r.Name : '';
                    templateVariables.ResidentAltPhone  = contactList[0].Alternate_Phone__c != null ? contactList[0].Alternate_Phone__c : '';
                    
                    tempList.template_values = templateVariables;
                    generateDoc.templates = new List<DigioWrapperClass.partyHallRulesTemplateList>{tempList};
                    String jsonBody = Json.serialize(generateDoc);
                    String digiDocId = digioCalloutUtility.sendHttpRequest('POST', endpoint, customData.Authorization__c, jsonBody);
                    wrapperRec.digiDocId = digiDocId;
                    
                    if(digiDocId != null && fileName != null){
                        subDocUrl = digioCalloutUtility.downloadDocument(digiDocId, fileName, parentFolderId, docId);
                        wrapperRec.subDocUrl = subDocUrl;
                    }
                }
                return wrapperRec;
            }
            return null;
        }catch(Exception e){
            system.debug('Error in generateVettedReceiptDocument===> ' + e.getMessage());
            system.debug('Error line ===> ' + e.getLineNumber());
            return null;
        }
    }
    
    @AuraEnabled(cacheable=false)
    public static void sendigiodetails(String digiDocId ,string oppId,string docname){
        try{
            if(oppId != null && digiDocId != null && docname != null){
                Opportunity oppRec = [Select Id ,Email__c from Opportunity where Id =: oppId ];
                digioCalloutUtility.downloadDigioDocWithoutGDrive (digiDocId,oppRec.Id,docname);
            }
        }catch(Exception e){
            system.debug('Error ==> ' + e.getMessage());
            system.debug('Error in line ==> ' + e.getLineNumber());
        }
    }
}