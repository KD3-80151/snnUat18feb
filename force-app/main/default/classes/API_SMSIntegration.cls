public class API_SMSIntegration {
    @future (callout=true)
    public static void sendSMS(String leadId, String phone, String triggeringPoint, String otp){
        try {
            System.debug('Lead Id: ' + leadId);
            System.debug('SMS Triggering Point: ' + triggeringPoint);
            if(triggeringPoint == null || triggeringPoint == '' || phone == null || phone == ''){
                System.debug('Error: Triggering Point or Phone no. is Null');
                return;
            }
            OTP_Configuration__mdt otpConfig = [SELECT userName__c, entityId__c, apiKey__c, smsType__c, senderId__c, DeveloperName, EndPoint__c
                                                FROM OTP_Configuration__mdt
                                                WHERE DeveloperName = 'OTP_Config'
                                                LIMIT 1];
            List<Lead> leadList = new List<Lead>();
            String name = '';
            String message = '';
            List<SMS_Template__c> smsTemplateList = new List<SMS_Template__c>();
            if(leadId != null || leadId == ''){
                leadList = [SELECT Id, Salutation, FirstName, MiddleName, LastName, Project__c, Site_Visit_Planned_Date__c 
                            FROM Lead
                            WHERE Id = :leadId];
                smsTemplateList = [SELECT SMS_Content__c, TemplateId__c, Triggering_Point__c 
                                    FROM SMS_Template__c 
                                    WHERE Triggering_Point__c = :triggeringPoint];
                name += leadList[0].Salutation != null ? leadList[0].Salutation : '';
                name += leadList[0].FirstName != null ? ' ' + leadList[0].FirstName : '';
                name += leadList[0].MiddleName != null ? ' ' + leadList[0].MiddleName : '';
                name += leadList[0].LastName != null ? ' ' + leadList[0].LastName : '';
                message = smsTemplateList[0].SMS_Content__c
                                .replace('<Name>', + name != null ? name : '')
                                .replace('<SV_Date>', leadList[0].Site_Visit_Planned_Date__c != null ? leadList[0].Site_Visit_Planned_Date__c.format() : '');
            }
            else {
                smsTemplateList = [SELECT SMS_Content__c, TemplateId__c, Triggering_Point__c 
                                    FROM SMS_Template__c 
                                    WHERE Triggering_Point__c = :triggeringPoint];
                message = otp + ' ' + smsTemplateList[0].SMS_Content__c;
            }
            System.debug('SMS Message: ' + message);
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(otpConfig.EndPoint__c);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            request.setHeader('Cookie', 'AWSALB=ukaHlaSVPqKCDeG8XYuGY6htK2wDnOV0YJcGuPgXGKEm0k0YGUgUlk8mfboDoGZdgHIpg8uW5nqfhGWOb8El/TZL3zf/9vgadPM7We/6gGopcsSqTcKE/UgyHikT; AWSALBCORS=ukaHlaSVPqKCDeG8XYuGY6htK2wDnOV0YJcGuPgXGKEm0k0YGUgUlk8mfboDoGZdgHIpg8uW5nqfhGWOb8El/TZL3zf/9vgadPM7We/6gGopcsSqTcKE/UgyHikT; PHPSESSID=7pbbdar2fbnsdblaf651spfoej; AWSALB=H8dMFzJDmovXK8inw9z9xM1bC0hVN0qax7Yy6CnlFjxbrxMXXrBpQBQTnzz9Bx+JvPcJx1XYDoazdEIOlbSFVn872E2gWx8YBcEsZ4ucadunzo7CrROfaMxXfMGa; AWSALBCORS=H8dMFzJDmovXK8inw9z9xM1bC0hVN0qax7Yy6CnlFjxbrxMXXrBpQBQTnzz9Bx+JvPcJx1XYDoazdEIOlbSFVn872E2gWx8YBcEsZ4ucadunzo7CrROfaMxXfMGa; AWSALB=AO+t+/c3gUpegOcJn+0QjADf3iVIDm+HpwamSJAeYU+5ZCnLoAgeojQiAGGagT81CqpDFq4SlkgBUvybg2VBikRfYWecjwo8iiuCKerS+9XF2L3gR3WpYEPfZele; AWSALBCORS=AO+t+/c3gUpegOcJn+0QjADf3iVIDm+HpwamSJAeYU+5ZCnLoAgeojQiAGGagT81CqpDFq4SlkgBUvybg2VBikRfYWecjwo8iiuCKerS+9XF2L3gR3WpYEPfZele');

            String payload = 
                'userName=' + EncodingUtil.urlEncode(otpConfig.userName__c, 'UTF-8') +
                '&entityId=' + EncodingUtil.urlEncode(otpConfig.entityId__c, 'UTF-8') +
                '&templateId=' + EncodingUtil.urlEncode(smsTemplateList[0].templateId__c, 'UTF-8') +
                '&destinationNumber=' + EncodingUtil.urlEncode(phone, 'UTF-8') +
                '&smsText=' + EncodingUtil.urlEncode(message, 'UTF-8') +
                '&apiKey=' + EncodingUtil.urlEncode(otpConfig.apiKey__c, 'UTF-8') +
                '&smsType=' + EncodingUtil.urlEncode(otpConfig.smsType__c, 'UTF-8') +
                '&senderId=' + EncodingUtil.urlEncode(otpConfig.senderId__c, 'UTF-8');
            System.debug('Encoded Payload: ' + payload);
            request.setBody(payload);
            HttpResponse response = http.send(request);
            System.debug('Response Status: ' + response.getStatus());
            System.debug('Response Body: ' + response.getBody());
        } catch (Exception e) {
            System.debug('Error in line: ' + e.getLineNumber());
            System.debug('Error Message: ' + e.getMessage());
        }
    }
}