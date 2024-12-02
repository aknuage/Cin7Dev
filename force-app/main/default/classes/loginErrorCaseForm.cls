public with sharing class loginErrorCaseForm {
    private static reCaptcha__c reCaptcha = reCaptcha__c.getOrgDefaults();
    private static String recaptchaSecretKey = reCaptcha.Secret_Key__c;
        
    @AuraEnabled
    public static String verifyCaptchaResponse(String recaptchaResponse){
        //https://developers.google.com/recaptcha/docs/verify
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://www.google.com/recaptcha/api/siteverify');
        request.setMethod('POST');
        request.setBody('secret=' + recaptchaSecretKey + '&response=' + recaptchaResponse);
        HttpResponse response = new HttpResponse();
        try{
            response = http.send(request);
        } catch(Exception errMessage){
            return errMessage.getMessage();
        }

        if (response.getStatusCode() == 200) {
            //System.debug(response.getBody());
            Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

            if (result.containsKey('success') && result.get('success') == true) {
                if (result.containsKey('score')) {
                    //score logic is only needed/returned for v3 (0.0 - 1.0)
                    //https://developers.google.com/recaptcha/docs/v3
                    //TODO: verify action name for the request
                    String action = (String)result.get('action');
                    //TODO: get threshold configuration for each action
                    Decimal threshold = .4;
                    Decimal score = (Decimal)result.get('score');
                    if (score > threshold) {
                        return 'Success - v3';
                    }
                } else {
                    return 'Success - v2';
                }
            } else {
                return 'Invalid Verification';
            }
        }
        return 'Invalid Verification Request';
    }
    
    @AuraEnabled
    public static String insertCase(String recaptchaResponse, String suppliedName, String suppliedCompany, String subject, String description, String suppliedEmail){
        
        String checkCaptcha = verifyCaptchaResponse(recaptchaResponse); 
        if(checkCaptcha.startsWith('Invalid Verification')){
            return checkCaptcha;
        }
        
        if(String.IsBlank(suppliedName) || String.IsBlank(suppliedCompany) //|| String.IsBlank(subject) 
           || String.IsBlank(description) || String.IsBlank(suppliedEmail)){
            return 'Blank Fields';
        }
           
        try{
            Case newCase = new Case();
            newCase.SuppliedEmail = suppliedEmail;
            newCase.SuppliedCompany = suppliedCompany;
            newCase.SuppliedName = suppliedName;
            newCase.Subject = 'Cin7 Connect Login Issue'; //subject;
            newCase.Description = description;
            newCase.Origin = 'Login Error Page';
            newCase.RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Community Support Case'].Id;
            newCase.OwnerId = [SELECT Id FROM Group WHERE Name = 'Regional Skills' LIMIT 1].Id;
            newCase.Queue__c = 'Support';
            insert newCase;
        }
        catch (Exception errMessage){
            return errMessage.getMessage();
        }
        
        return 'Success';
    }
}