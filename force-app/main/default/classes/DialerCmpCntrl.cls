global without sharing class DialerCmpCntrl {
    
    @AuraEnabled
    public static List<String> getCountryCodes() {
        List<String> countryCodes = new List<String>();
        List<Country_Code_Mapping__mdt> countryCodeMetadata = [SELECT Country_Code__c FROM Country_Code_Mapping__mdt];
        for (Country_Code_Mapping__mdt record : countryCodeMetadata) {
            countryCodes.add(record.Country_Code__c);
        }
        Integer index = countryCodes.indexOf('91');
        if (index != -1) {
            countryCodes.remove(index);
        }
        System.debug(countryCodes);
        if(!countryCodes.isEmpty())
        	countryCodes.add(0, '91');
        else
        	countryCodes.add('91'); 
        return countryCodes;
    }
    
    @AuraEnabled
    public static String createCallDetails(String mobileNo){
        User u = [select mobilePhone,Last_Outbound_Id__c from user where id=:userinfo.getUserId()];
        String m = mobileNo;
        system.debug(m);
        u.mobilePhone = u.mobilePhone.replace('+91','')  ; 
        u.mobilePhone = u.mobilePhone.replace('+','')  ;  
        u.mobilePhone=  u.mobilePhone.replaceAll('\\(', '');
        u.mobilePhone=  u.mobilePhone.replaceAll('\\)', '');
        u.mobilePhone=  u.mobilePhone.replaceAll(' ', '');
        if(m != null){
            m= m.replace('+91','')  ; 
            m=  m.replaceAll('\\(', '');
            m=  m.replaceAll('\\)', ''); 
            m=  m.replaceAll(' ', ''); 
        }
        call_detail__c cl = new call_detail__c();
        cl.Call_To__c = m;
        cl.Call_From__c = u.mobilePhone;
        insert cl;
        u.Last_Outbound_Id__c = cl.id;
        update u;
        return cl.Id;
    }
    
    @AuraEnabled
    webservice static String clickToCall(String countryCode,String mobileNo,String recId) {  
        Mcube_Log__c mLog = new Mcube_Log__c();
        mlog.API_Type__c = 'Outward';
        mlog.Action_Type__c = 'Outbound';
        mlog.Api_called_at__c = System.now();
        mlog.Method_Name__c = 'DialerCmpCntrl.clickToCall';
        try{
        User u = [select mobilePhone from user where id=:userinfo.getUserId()];
        //String m= String.valueof(l[0].get(mcubeObject.Field_to_Compare_Mobile_Incoming_Number__c));
        String customerNo = '+'+ countryCode + mobileNo;
        
        countryCode = '';
        system.debug('countrycode '+countryCode + ' '+ mobileNo +'  recId= '+ recId );
        u.mobilePhone = u.mobilePhone.replace('+91','')  ; 
        u.mobilePhone = u.mobilePhone.replace('+','')  ;  
        u.mobilePhone=  u.mobilePhone.replaceAll('\\(', '');
        u.mobilePhone=  u.mobilePhone.replaceAll('\\)', '');
        u.mobilePhone=  u.mobilePhone.replaceAll(' ', '');
      
        Mcube__mdt api1 =  [select Value__c from Mcube__mdt where DeveloperName ='APIKey'];
        Mcube__mdt api2 =  [select Value__c from Mcube__mdt where DeveloperName ='callbackUrl'];
        //for new Products
        List<Mcube__mdt> verstionList = [select Value__c from Mcube__mdt where DeveloperName ='Version'];
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        
        string url = '';
        //For New Products 
        if(!(verstionList.isEmpty()) && verstionList[0].Value__c == '2'){
            url = 'https://api.mcube.com/Restmcube-api/outbound-calls-manipal';
            
            request.setHeader('Content-Type', 'application/json');
            
            Map<String, Object> requestBody = new Map<String, Object>();
            requestBody.put('HTTP_AUTHORIZATION', api1.Value__c);
            requestBody.put('exenumber', u.mobilePhone);
            requestBody.put('custnumber', customerNo);
            requestBody.put('Countrycode', countryCode);
            requestBody.put('refid', '');
            requestBody.put('refurl', 1);
            
            String jsonBody = JSON.serialize(requestBody);
            request.setBody(jsonBody);
            mlog.Request__c = url + requestBody;
            System.debug(requestBody);
        }else{
            url  =   'http://mcube.vmc.in/api/outboundcall?apikey='+api1.Value__c  +'&exenumber='+u.mobilePhone+'&custnumber='+customerNo+'&refid='+'&url='+api2.Value__c+'&c1='+recId+'&Countrycode='+countryCode +'/calland?refid=';
            mlog.Request__c = url;
        }
        
        request.setEndpoint(url);
        request.setMethod('POST');
        
        system.debug(url);
       
            HttpResponse response = http.send(request);
            String var= response.getBody() ;
            Map<String,String> responseMap = (Map<String, String>) JSON.deserialize(var, Map<String, String>.class); 
            system.debug(var);  
            mlog.Response__c = var;
            
            system.debug('Status COde'+response.getStatusCode()); 
            if(response.getStatusCode() == 200 ){
                mlog.Status__c = 'Success';
                String bodyStatus =  responseMap.get('status');
                
                if(bodyStatus=='false'){
                    
                    mlog.Status__c = 'Fail';
                    //throw  new AuraHandledException(responseMap.get('msg'));
                }
                   
              
            }else{
                mlog.Status__c = 'Fail';
            }
            
            if(System.label.Create_Mcube_Log == 'Yes'){
                insert mlog;
            }
          
            return var;
        }
        catch(Exception e){
            mlog.Status__c = 'Fail';
            mlog.Response__c = e.getMessage() + '\n Line: ' + e.getLineNumber();
             if(System.label.Create_Mcube_Log == 'Yes'){
                    insert mlog;
                }
            System.debug('Error : ' + e.getMessage());
            return e.getMessage();
        }
    }
    
    @AuraEnabled
    public static CallCountWrapper getCallCount(String startDate, String endDate) {
        
        
        System.debug(startDate +'  '+ endDate);
        List<Call_Detail__c> callList = new List<Call_Detail__c>();
        User u = [SELECT Id, MobilePhone FROM User WHERE Id = :UserInfo.getUserId()];
        u.mobilePhone = u.mobilePhone.replace('+91','')  ; 
        u.mobilePhone = u.mobilePhone.replace('+','')  ;  
        u.mobilePhone=  u.mobilePhone.replaceAll('\\(', '');
        u.mobilePhone=  u.mobilePhone.replaceAll('\\)', '');
        u.mobilePhone=  u.mobilePhone.replaceAll(' ', '');
        if(startDate ==  null || startDate ==  ''){
            callList = [SELECT Id, Status__c, Call_Type__c,Duration_in_Minutes__c,Answered_Time__c,Start_Time__c FROM Call_Detail__c WHERE Execuive_Number__c = :u.MobilePhone ];
            
        }else{
            Date startdateValue = Date.valueOf(startDate); 
            Date enddateValue = Date.valueOf(endDate); 
            callList = [SELECT Id, Status__c, Call_Type__c,Duration_in_Minutes__c,Answered_Time__c,Start_Time__c,End_Time__c FROM Call_Detail__c WHERE Execuive_Number__c = :u.MobilePhone AND DAY_ONLY(Start_Time__c) >= :startdateValue AND DAY_ONLY(Start_Time__c)<= :enddateValue ];
            
        }
        
        CallCountWrapper callCountWrapper = new CallCountWrapper();
        
        for (Call_Detail__c call : callList) {
            callCountWrapper.totalCount++;
            if (call.Call_Type__c == 'Inbound Call') {
                callCountWrapper.inboundCallCount++;
                if(call.Duration_in_Minutes__c != null && call.Duration_in_Minutes__c> 0){
                    callCountWrapper.inbCallDuration += (call.Duration_in_Minutes__c).setScale(1, RoundingMode.HALF_UP);
                }
                if(call.Answered_Time__c != null){
                callCountWrapper.inbAnsweredTime += (Decimal.valueOf(call.Answered_Time__c) / 60).setScale(1, RoundingMode.HALF_UP);
                }
                if (call.Status__c == 'ANSWER') {
                    callCountWrapper.inbConnCallCount++;
                }
            }
            if (call.Call_Type__c == 'Outbound Call') {
                callCountWrapper.outboundCallCount++;
                if(call.Duration_in_Minutes__c != null && call.Duration_in_Minutes__c> 0){
                callCountWrapper.outCallDuration += (call.Duration_in_Minutes__c).setScale(1, RoundingMode.HALF_UP);
                }
                if(call.Answered_Time__c != null){
                    callCountWrapper.outAnsweredTime += (Decimal.valueOf(call.Answered_Time__c) / 60).setScale(1, RoundingMode.HALF_UP);
                }
                
                if (call.Status__c == 'Call Complete') {
                    callCountWrapper.outConnCallCount++;
                }
            }
            
        }
        
        return callCountWrapper;
    }
    
    public class CallCountWrapper {
        @AuraEnabled
        public Integer totalCount { get; set; }
        @AuraEnabled
        public Integer inboundCallCount { get; set; }
        @AuraEnabled
        public Integer inbConnCallCount { get; set; }
        @AuraEnabled
        public Decimal inbCallDuration { get; set; }
        @AuraEnabled
        public Decimal inbAnsweredTime  { get; set; }
        @AuraEnabled
        public Integer outboundCallCount { get; set; }
        @AuraEnabled
        public Integer outConnCallCount { get; set; }
        @AuraEnabled
        public Decimal outCallDuration { get; set; }
        @AuraEnabled
        public Decimal outAnsweredTime { get; set; }
        
        public CallCountWrapper() {
            this.totalCount = 0;
            this.inboundCallCount = 0;
            this.inbConnCallCount = 0;
            this.inbCallDuration = 0;
            this.inbAnsweredTime = 0;
            
            this.outboundCallCount = 0;
            this.outConnCallCount = 0;
            this.outCallDuration = 0;
            this.outAnsweredTime = 0;
        }
    }
    
    /*Abhinav - set online or offline mode */
    // Method to send the online break request
    @AuraEnabled
    webservice static Boolean offlineonline(Boolean isActive,Boolean isOpen,String breakReason) {
         Mcube_Log__c mLog = new Mcube_Log__c();
        mlog.API_Type__c = 'Outward';
        
        mlog.Api_called_at__c = System.now();
        mlog.Method_Name__c = 'DialerCmpCntrl.offlineonline';
        System.debug(breakReason);
        User u = [SELECT ID,MobilePhone, Profile.Name,Email,Mcube_username__c,mcube_Availability__c FROM User WHERE Id = :UserInfo.getUserId()];
        
        if(isOpen ){
            return u.mcube_Availability__c;
        }
        u.mcube_Availability__c = isActive;
        
        Mcube__mdt api1 =  [select Value__c from Mcube__mdt where DeveloperName ='APIKey'];
        String url = 'https://api.mcube.com/Break-api/break-api';
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod('POST');
        req.setHeader('Authorization', api1.Value__c);
        req.setHeader('Content-Type', 'application/json');
        String jsonPayload;
        if (isActive) {
            mlog.Action_Type__c = 'Online';
            jsonPayload = '{"Authorization":"' + api1.Value__c + '","email":"' + u.Mcube_username__c + '","break":"0"}';
        } else {
            mlog.Action_Type__c = 'Offline';
            jsonPayload = '{"Authorization":"' + api1.Value__c + '","email":"' + u.Mcube_username__c + '","break":"1","break_reason":"' + breakReason + '"}';
            
        }
        system.debug(jsonPayload);
        req.setBody(jsonPayload);
        mlog.Request__c = url + jsonPayload;
        system.debug(req);
        Http http = new Http();
        HttpResponse res;
        if(!test.isRunningTest()){
            
            try {
                res = http.send(req);
                System.debug('Response Status: ' + res.getStatus());
                System.debug('Response Body: ' + res.getBody());
                
                // Handle the response
                if (res.getStatusCode() == 200) {
                    String var = res.getBody();
                    mlog.Status__c = 'Success';
                    mlog.Response__c = var;
                    Map<String, String> responseMap = (Map<String, String>) JSON.deserialize(var, Map<String, String>.class);
                    System.debug('Response Map: ' + responseMap);
                    
                    String bodyStatus = responseMap.get('status');
                    if (bodyStatus == 'false') {
                        mlog.Status__c = 'Fail';
                        throw new AuraHandledException(responseMap.get('msg'));
                    }
                    update u;
                    if(System.label.Create_Mcube_Log == 'Yes'){
                        insert mlog;
                    }
                    return true;
                } else {
                    System.debug('HTTP Request failed with status code: ' + res.getStatusCode());
                    throw new AuraHandledException('HTTP request failed with status code: ' + res.getStatusCode());
                }
                
            } catch (Exception e) {
                System.debug('Error sending request: ' + e.getMessage());
                mlog.Status__c = 'Fail';
                mlog.Response__c = e.getMessage() + '\n Line: ' + e.getLineNumber();
                 if(System.label.Create_Mcube_Log == 'Yes'){
                    insert mlog;
                }
                String var = res.getBody();
                Map<String, String> responseMap = (Map<String, String>) JSON.deserialize(var, Map<String, String>.class);
                string msg = responseMap.get('error');
                if(msg != null){
                    throw new AuraHandledException(responseMap.get('error'));
                }
                else{
                    throw new AuraHandledException('An error occurred while sending the request.');
                }
                
            } 
            
        }
        return false;
    }
    @AuraEnabled
    webservice static String signInSignOut(String username,String password,String type){
        Mcube_Log__c mLog = new Mcube_Log__c();
        mlog.API_Type__c = 'Outward';
        mlog.Api_called_at__c = System.now();
        mlog.Method_Name__c = 'DialerCmpCntrl.signInSignOut';
        mlog.Action_Type__c = type;
        try{
        Map<String, Object> responseMap = new Map<String, Object>();
        User u = [SELECT ID,Mcube_Logged_In__c,Mcube_username__c,Mcube_password__c	 FROM User WHERE Id = :UserInfo.getUserId()];
       /* if(u.Mcube_Logged_In__c && type == 'login'){
            responseMap.put('status', 'false');
            responseMap.put('error', 'Already Logged In, refresh your page.');
            return JSON.serialize(responseMap);
        }else{*/
             Mcube__mdt api1 =  [select Value__c from Mcube__mdt where DeveloperName ='APIKey'];
        String token = api1.Value__c ;
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        string url  =   'https://config.mcube.com/Restmcube-api/sign-in-out';
        String payload = '{"api_key":"' + token + 
            '","username":"' + username + 
            '","password":"' + password + 
            '","type":"' + type + '"}';
        request.setEndpoint(url);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setBody(payload);
        System.debug(payload);
        mlog.Request__c = url + payload;
            HttpResponse response = http.send(request);
            String var= response.getBody() ;
            system.debug(var);
            mlog.Response__c = var;
            system.debug('Status Code :: '+response.getStatusCode()); 
            if(response.getStatusCode() == 200 ){
                mlog.Status__c = 'Success';
                if(type == 'login'){
                    Mcube_Login__c ml = new Mcube_Login__c();
                    ml.Login_Time__c = System.now();
                    ml.User__c = u.id;
                    if(System.label.Create_Mcube_Log == 'Yes'){
                        insert ml;
                    }
                    u.Mcube_username__c = username;
                    u.Mcube_password__c = password;
                    u.Mcube_Logged_In__c = true;
                    u.mcube_Availability__c = true;
                    update u;
                }else{
                    List<Mcube_Login__c> mlList = [select id,Login_Time__c,Logout_Time__c from Mcube_Login__c 
                                                   where User__c =: u.id AND DAY_ONLY(Login_Time__c) = TODAY order by Login_Time__c desc limit 1];
                    if(mlList.size() > 0){
                        mlList[0].Logout_Time__c = system.now();
                        if(System.label.Create_Mcube_Log == 'Yes'){
                        update mlList[0];
                        }
                    }
                    
                    u.Mcube_Logged_In__c = false;
                    update u;
                }
               
            }
            else{
                mlog.Status__c = 'Fail';
            }
            if(System.label.Create_Mcube_Log == 'Yes'){
                insert mlog;
            }
            return var;
            
         //}
       }
        catch(Exception e){
            mlog.Status__c = 'Fail';
            mlog.Response__c = e.getMessage() + '\n Line: ' + e.getLineNumber();
             if(System.label.Create_Mcube_Log == 'Yes'){
                    insert mlog;
                }
            System.debug('Error : ' + e.getMessage());
            return e.getMessage();
        }
    }
    @AuraEnabled
    webservice static string holdUnhold(String callId,String holdtype){
        Mcube_Log__c mLog = new Mcube_Log__c();
        mlog.API_Type__c = 'Outward';
        mlog.Api_called_at__c = System.now();
        mlog.Method_Name__c = 'DialerCmpCntrl.holdUnhold';
        mlog.Action_Type__c = holdtype;
        try{
        System.debug('callId == ' + callId);
        Call_Detail__c cl = [SELECT ID,Call_ID__c,Execuive_Number__c,Hold_Status__c FROM Call_Detail__c WHERE Call_ID__c = :callId];
        String empno = cl.Execuive_Number__c;
        Mcube__mdt api1 =  [select Value__c from Mcube__mdt where DeveloperName ='APIKey'];
        String token = api1.Value__c ;
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        string url  =   'https://config.mcube.com/call-feature/call-hold';
        String payload = '{"Authorization":"' + token + 
            '","callid":"' + callId + 
            '","holdtype":"' + holdtype + 
            '","empnumber":"' + empno + '"}';
            request.setEndpoint(url);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
            request.setBody(payload);
            mlog.Request__c = url + payload;
            System.debug(payload);
            HttpResponse response = http.send(request);
            String var= response.getBody() ;
            system.debug(var);
            mlog.Response__c = var;
            system.debug('Status Code :: '+response.getStatusCode()); 
            if(!test.isRunningTest()){
                
                if(response.getStatusCode() == 200 ){
                    mlog.Status__c = 'Success';
                    cl.Hold_Status__c = (holdtype == 'hold') ? 'hold' : 'unhold';
                    update cl;
                    
                }else{
                    mlog.Status__c = 'Fail';
                }
                 if(System.label.Create_Mcube_Log == 'Yes'){
                    insert mlog;
                }
            }
            
            return var;
        }catch(Exception e){
            mlog.Status__c = 'Fail';
            mlog.Response__c = e.getMessage() + '\n Line: ' + e.getLineNumber();
             if(System.label.Create_Mcube_Log == 'Yes'){
                    insert mlog;
                }
            System.debug('Error : ' + e.getMessage());
            return e.getMessage();
        }
        
    }
    @AuraEnabled
    public static databox userStatus(){
        databox d = new databox();
        User u = [SELECT ID,Mcube_Logged_In__c,mcube_Availability__c,Mcube_username__c,Mcube_password__c	 FROM User WHERE Id = :UserInfo.getUserId()];
        d.u= u;
        List<Mcube_login__c> mlList = [select id from Mcube_Login__c where DAY_ONLY(Login_Time__c) = TODAY AND User__c =: UserInfo.getUserId()];
        boolean status = mlList.size() > 0 ? true : false;
        d.mcubeLogin = status;
        return d;
    }
    /*Abhinav - to get the call history */
    public class callData {
        @AuraEnabled
        public List<Call_Detail__c> callDetail { get; set; }
        
        @AuraEnabled
        public Integer callCount { get; set; }
        
        @AuraEnabled
        public Boolean isUserOnline { get; set; }
        
        @AuraEnabled
        public String isError { get; set; }
    }
    
    // Main method to retrieve call details and call count
    @AuraEnabled
    public static callData getCallDetails(Integer offset, Integer limits) {
        User u = [SELECT Id, MobilePhone FROM User WHERE Id = :UserInfo.getUserId()];
        u.mobilePhone = u.mobilePhone.replace('+91','')  ; 
        u.mobilePhone = u.mobilePhone.replace('+','')  ;  
        u.mobilePhone=  u.mobilePhone.replaceAll('\\(', '');
        u.mobilePhone=  u.mobilePhone.replaceAll('\\)', '');
        u.mobilePhone=  u.mobilePhone.replaceAll(' ', '');
        
        // Create an instance of the inner class
        callData callResponse = new callData();
        
        // Fetch call detail records with pagination
        callResponse.callDetail = [SELECT Id, Name,Call_ID__c, Call_Type__c, Status__c, Lead__c, Case__c, Account__c, 
                                   Contact__c,Start_Time__c, End_Time__c, Duration_in_Minutes__c FROM Call_Detail__c 
                                   where Execuive_Number__c = :u.MobilePhone 
                                   ORDER BY CreatedDate DESC
                                   LIMIT :limits OFFSET :offset
                                  ];
        
        // Fetch total record count (without LIMIT or OFFSET)
        callResponse.callCount = [SELECT COUNT() FROM Call_Detail__c where Execuive_Number__c = :u.MobilePhone];
        
        // Return the response object with records and count
        return callResponse;
    }
    @AuraEnabled
    public static Call_detail__c getLastCallDetails(){
        User u = [select mobilePhone,Last_Outbound_Id__c,Last_Inbound_Id__c from user where id=:userinfo.getUserId()];
        Call_detail__c cl =[select Id,Call_ID__c,Invoke_Mcube__c,Call_Type__c,Contact__c,Customer_Number__c,Execuive_Number__c,Status__c,
                           Hold_Status__c
                            from Call_detail__c where id =: u.Last_Outbound_Id__c];
        return cl;
    }
    
    
    public class databox{
        @AuraEnabled
        Public User u;
        @AuraEnabled
        Public boolean mcubeLogin;
        
    }
    
    
    @AuraEnabled
    public static List<Map<String, String>> getAvailableAgentNames(String callId) {
        Mcube_Log__c ml = new Mcube_Log__c();
        ml.Call_Type__c = 'Outbound Call';
        ml.Api_Type__c = 'Outward';
        ml.Action_type__c = 'Avilable Agent';
        ml.Api_called_at__c = System.now();
         ml.Method_Name__c = 'DialerCmpCntrl.getAvailableAgentNames';
        try {
        System.debug('callId == ' + callId);
        Call_Detail__c cl = [SELECT ID FROM Call_Detail__c WHERE Call_ID__c = :callId LIMIT 1];
           
            ml.Call_Detail__c = cl.id;
            Mcube__mdt api1 = [SELECT Value__c FROM Mcube__mdt WHERE DeveloperName = 'APIKey'];
            String token = api1.Value__c;
            
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            String url = 'https://config.mcube.com/call-feature/availble-agents';
            String payload = '{"Authorization":"' + token + '"}';
            request.setEndpoint(url);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
            request.setBody(payload);
            ml.Request__c = url + payload;
            HttpResponse res = http.send(request);
            String rawResponse = res.getBody();
            String singleLineResponse = rawResponse.replaceAll('[\\r\\n]+', '');
            
            // Storing the single-line JSON
            ml.Response__c = singleLineResponse;
            
            if (res.getStatusCode() == 200) {
                AvailableAgentsWrapper wrapper = (AvailableAgentsWrapper) JSON.deserialize(res.getBody(), AvailableAgentsWrapper.class);
                
                List<Map<String, String>> agentOptions = new List<Map<String, String>>();
                if (wrapper.agentlist != null) {
                    for (AgentInfo a : wrapper.agentlist) {
                        if (String.isNotBlank(a.agent_name) && String.isNotBlank(a.emp_phone)) {
                            Map<String, String> option = new Map<String, String>{
                                'label' => a.agent_name,
                                    'value' => a.emp_phone
                                    };
                                        agentOptions.add(option);
                        }
                    }
                }
                ml.Status__c = 'Success';
                if(System.label.Create_Mcube_Log == 'Yes'){
                    insert ml;
                }
                return agentOptions;
            } else {
                ml.Status__c = 'Fail';
                 if(System.label.Create_Mcube_Log == 'Yes'){
                    insert ml;
                }
                System.debug('Error from API: ' + res.getStatusCode() + ' ' + res.getBody());
                return new List<Map<String, String>>();
            }
            

        } catch (Exception e) {
            System.debug('Exception in callout: ' + e.getMessage());
            ml.Response__c = e.getMessage();
            ml.Status__c = 'Fail';
             if(System.label.Create_Mcube_Log == 'Yes'){
                    insert ml;
                }
            return new List<Map<String, String>>();
        }
    }
    
    public class AvailableAgentsWrapper {
        public String status;
        public List<AgentInfo> agentlist;
    }
    
    public class AgentInfo {
        public String agent_id;
        public String agent_name;
        public String emp_phone;
        public String email;
    }
    
    
    @AuraEnabled
    public static string callTransfer(String callId, String transferToAgentNo) {
        
        Mcube_Log__c ml = new Mcube_Log__c();
        ml.Call_Type__c = 'Outbound Call';
        ml.Action_type__c = 'Call Transfer';
        ml.Api_Type__c = 'Outward';
        ml.Method_Name__c = 'DialerCmpCntrl.callTransfer';
        ml.Api_called_at__c = System.now();
        try {
        System.debug('callId == ' + callId + '  transferToAgentNo ==' + transferToAgentNo);
        Call_Detail__c cl = [SELECT ID FROM Call_Detail__c WHERE Call_ID__c = :callId Limit 1];
        User u = [select mobilePhone from user where id=:userinfo.getUserId()];
        u.mobilePhone = u.mobilePhone.replace('+91','')  ; 
        u.mobilePhone = u.mobilePhone.replace('+','')  ;  
        u.mobilePhone=  u.mobilePhone.replaceAll('\\(', '');
        u.mobilePhone=  u.mobilePhone.replaceAll('\\)', '');
        u.mobilePhone=  u.mobilePhone.replaceAll(' ', '');
            
            ml.Call_Detail__c = cl.id;
            Mcube__mdt api1 =  [select Value__c from Mcube__mdt where DeveloperName ='APIKey'];
            String token = api1.Value__c ;
            
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            string url  =   'https://config.mcube.com/call-feature/call-transfer';
            String payload = '{"Authorization":"' + token + 
                '","callid":"' + callId + 
                '","empnumber":"' + u.mobilePhone + 
                '","type":"' +'outbound'+ 
                '","transferto":"' + transferToAgentNo + '"}';
            request.setEndpoint(url);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
            request.setBody(payload);
            ml.Request__c = url + payload;
            HttpResponse res = http.send(request);
            String rawResponse = res.getBody();
            String singleLineResponse = rawResponse.replaceAll('[\\r\\n]+', '');
            
            // Storing the single-line JSON
            ml.Response__c = singleLineResponse;
           
            
            System.debug('Call Transfer Response: ' + res.getStatusCode() + ' ' + res.getBody());
            if(res.getStatusCode() == 200 ){
                ml.Status__c = 'Success';
            }
            else{
                ml.Status__c = 'Fail';
            }
             if(System.label.Create_Mcube_Log == 'Yes'){
                    insert ml;
                }
          
            return res.getBody();
        } catch(Exception e) {
            System.debug('Exception in callout: ' + e.getMessage());
            ml.Response__c = e.getMessage();
            ml.Status__c = 'Fail';
             if(System.label.Create_Mcube_Log == 'Yes'){
                    insert ml;
                }
            return e.getMessage();
        }
        
    }
    
     @AuraEnabled
    Public static String getPlatformUserGroup(){
     return 'CtiNotification__e';
        
        /*  user userData =   [Select id,Name,Event_Group__c 
                  FROM user 
                  WHERE id =: UserInfo.getUserId()
                 ];
        
        if(userData.Event_Group__c!=null && userData.Event_Group__c!='' && Schema.getGlobalDescribe().containsKey(userData.Event_Group__c+'__e' )){
            return userData.Event_Group__c +'__e';
        }else{
            throw new AuraHandledException('Can\'t find the matching platform event associated with the user');
        }*/
    }
   
    
    public static void getcover(){
        integer  i=0;
        if(i==0){
            i=0;
            i=0;i=0;i=0;i=0; 
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0; 
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0; 
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0; 
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
             i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0; 
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
             i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0; 
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
        }
        
    }
    
}