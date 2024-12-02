/**
* Makes sure that Onboarding Status field on the Account object has the same value
* as on the Onboarding object
*/
trigger onboardingChanged on Onboarding__c (after insert,after update) {
    System.debug('onboardingChanged trigger');
    for (Onboarding__c obj : Trigger.new){
       Id accId = obj.Account__c; //Account__r.Id;
       System.debug('Account ID: ' + accId);
       List<Account> accountList = [SELECT Id FROM Account WHERE Id = :accId];
       for(Account acc : accountList) {
       System.debug('Updating account status to: ' + obj.Onboarding_Status__c );
        acc.Onboarding_Status__c = obj.Onboarding_Status__c;        
       }
       update accountList;
    }
}