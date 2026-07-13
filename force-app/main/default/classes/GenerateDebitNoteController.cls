public without sharing class GenerateDebitNoteController {

    public class docwrpperClass {
        @AuraEnabled public String digiDocId;
        @AuraEnabled public String subDocUrl;
    }

    @AuraEnabled
    public static docwrpperClass generateDebitNote(String recorId) {
        try {
            System.debug('recorId=>' + recorId);

            if (String.isBlank(recorId)) {
                return null;
            }

            String parentFolderId;
            String docId;
            String subDocUrl = '';
            docwrpperClass wrapperRec = new docwrpperClass();

            List<Receipt__c> receiptRecord = [
                SELECT Id,
                       Name,
                       Receipt_Date__c, Total_Credit_Debit_Gst__c,
                       Amount__c,
                       Payment_Schedule__c,
                       Payment_Schedule__r.Name,
                       Description__c,
                       CreatedBy.Name,
                       Opportunity__c,
                       Opportunity__r.Account.Salutation__c,
                       Opportunity__r.Account.Name,
                       Opportunity__r.Account.Permanent_Address__PostalCode__s,
                       Opportunity__r.Project__r.Name,
                       Opportunity__r.Unit__r.Unit_Name__c,
                       Opportunity__r.Unit__r.Floor__r.Blocks__r.Name
                FROM Receipt__c
                WHERE Id = :recorId
                LIMIT 1
            ];

            if (receiptRecord.isEmpty() || receiptRecord[0].Opportunity__c == null) {
                return null;
            }

            List<Opportunity> oppDetails = [
                SELECT Id,
                       Name,
                       AccountId,
                       (SELECT Id, Document_Id__c
                        FROM Documents__r
                        WHERE Name = 'Receipts'
                        LIMIT 1)
                FROM Opportunity
                WHERE Id = :receiptRecord[0].Opportunity__c
                LIMIT 1
            ];

            if (!oppDetails.isEmpty() && oppDetails[0].Documents__r != null && !oppDetails[0].Documents__r.isEmpty()) {
                parentFolderId = oppDetails[0].Documents__r[0].Document_Id__c;
                docId = oppDetails[0].Documents__r[0].Id;
            }

            Digio_Integration__c customData = Digio_Integration__c.getValues('Digio');

            if (customData == null ||
                String.isBlank(customData.Authorization__c) ||
                String.isBlank(customData.Endpoint_URL__c) ||
                String.isBlank(customData.Debit_Note__c)) {
                return null;
            }

            String endpoint = customData.Endpoint_URL__c + '/v2/client/template/multi_templates/create_sign_request';

            Map<String, Object> generateDoc = new Map<String, Object>();
            Datetime now = System.now();
            String formattedTimestamp = now.format('yyyy-MM-dd HH:mm:ss');
            String fileName = 'Debit Note - ' + formattedTimestamp;
            generateDoc.put('file_name', fileName);

            Map<String, Object> signer = new Map<String, Object>();
            signer.put('identifier', 'projects@snnestates.com');
            signer.put('signer_tag', 'Signer 1');
            signer.put('name', 'Snn');
            signer.put('sign_type', 'document_review');
            generateDoc.put('signers', new List<Object>{ signer });

            Map<String, Object> templateWrapper = new Map<String, Object>();
            templateWrapper.put('template_key', customData.Debit_Note__c);

            Map<String, Object> templateVariables = new Map<String, Object>();
            templateVariables.put(
                'receiptDate',
                receiptRecord[0].Receipt_Date__c != null
                    ? DateTime.newInstance(receiptRecord[0].Receipt_Date__c, Time.newInstance(0, 0, 0, 0)).format('dd MMM yyyy')
                    : ''
            );
            templateVariables.put(
                'salutation',
                receiptRecord[0].Opportunity__r != null &&
                receiptRecord[0].Opportunity__r.Account != null &&
                receiptRecord[0].Opportunity__r.Account.Salutation__c != null
                    ? receiptRecord[0].Opportunity__r.Account.Salutation__c
                    : ''
            );
            templateVariables.put(
                'accountName',
                receiptRecord[0].Opportunity__r != null && receiptRecord[0].Opportunity__r.Account != null
                    ? receiptRecord[0].Opportunity__r.Account.Name
                    : ''
            );
            templateVariables.put(
                'pincode',
                receiptRecord[0].Opportunity__r != null && receiptRecord[0].Opportunity__r.Account != null
                    ? receiptRecord[0].Opportunity__r.Account.Permanent_Address__PostalCode__s
                    : ''
            );
            templateVariables.put(
                'unitName',
                receiptRecord[0].Opportunity__r != null && receiptRecord[0].Opportunity__r.Unit__r != null
                    ? receiptRecord[0].Opportunity__r.Unit__r.Unit_Name__c
                    : ''
            );
            templateVariables.put(
                'project',
                receiptRecord[0].Opportunity__r != null && receiptRecord[0].Opportunity__r.Project__r != null
                    ? receiptRecord[0].Opportunity__r.Project__r.Name
                    : ''
            );
            templateVariables.put(
                'block',
                receiptRecord[0].Opportunity__r != null &&
                receiptRecord[0].Opportunity__r.Unit__r != null &&
                receiptRecord[0].Opportunity__r.Unit__r.Floor__r != null &&
                receiptRecord[0].Opportunity__r.Unit__r.Floor__r.Blocks__r != null
                    ? receiptRecord[0].Opportunity__r.Unit__r.Floor__r.Blocks__r.Name
                    : ''
            );
            templateVariables.put('amount', (receiptRecord[0].Amount__c != null && receiptRecord[0].Total_Credit_Debit_Gst__c != null) ? (receiptRecord[0].Amount__c + receiptRecord[0].Total_Credit_Debit_Gst__c) : 0);
            templateVariables.put(
                'paymentSchedule',
                receiptRecord[0].Payment_Schedule__r != null
                    ? receiptRecord[0].Payment_Schedule__r.Name
                    : ''
            );
            templateVariables.put(
                'createdBy',
                receiptRecord[0].CreatedBy != null ? receiptRecord[0].CreatedBy.Name : ''
            );
            templateVariables.put(
                'decription',
                receiptRecord[0].Description__c != null ? receiptRecord[0].Description__c : ''
            );

            templateWrapper.put('template_values', templateVariables);
            generateDoc.put('templates', new List<Object>{ templateWrapper });

            String jsonBody = JSON.serialize(generateDoc);

            String authorizationValue = 'Basic ' +
                EncodingUtil.base64Encode(
                    Blob.valueOf(customData.Client_ID__c + ':' + customData.Client_Secret__c)
                );

            String digiDocId = digioCalloutUtility.sendHttpRequest('POST', endpoint, authorizationValue, jsonBody);
            wrapperRec.digiDocId = digiDocId;

            if (digiDocId != null && fileName != null && parentFolderId != null && docId != null) {
                subDocUrl = digioCalloutUtility.downloadDocument(digiDocId, fileName, parentFolderId, docId);
                wrapperRec.subDocUrl = subDocUrl;
            }

            return wrapperRec;
        } catch (Exception e) {
            System.debug('Error in generateDebitNote => ' + e.getMessage());
            System.debug('Error line => ' + e.getLineNumber());
            return null;
        }
    }
}