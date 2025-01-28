/*
**************************************************************************
Created Date       : Jan 2025
@description       : Account + Contact wrapper class utilizing invocable
variables to pass parameters queueable Trial Account callout class. 
@author            : Anthony Kelly
Modification Log:
Ver   Date         Author                    Modification
1.0   01-09-2025   Anthony Kelly             Initial Version
***************************************************************************
*/
global with sharing class AccountTrialWrapper {

    // Invocable variables for Flow to use
    @InvocableVariable(required=true)
    global ID accountId;
    
    @InvocableVariable(required=true)
    global ID contactId;
    
    @InvocableVariable
    global String tenantId;

    @InvocableVariable
    global String accountName;
    
    @InvocableVariable
    global String contactEmail;
    
    @InvocableVariable
    global String contactName;
    
    @InvocableVariable
    global String billingEmail;
    
    @InvocableVariable
    global String platformAccountStatus;

    @InvocableVariable
    global String contactPhone;

    @InvocableVariable
    global String billingStreet;

    @InvocableVariable
    global String addressLineOne;

    @InvocableVariable
    global String addressLineTwo;

    @InvocableVariable
    global String billingCity;

    @InvocableVariable
    global String timeZone;

    @InvocableVariable
    global String billingState;

    @InvocableVariable
    global String billingPostalCode;

    @InvocableVariable
    global String billingCountry;

    @InvocableVariable
    global String coreIndustry;
    
    @InvocableVariable
    global Boolean demoData;

    @InvocableVariable
    global String websiteURL;

    @InvocableVariable
    global String couponReferralCode;

    @InvocableVariable
    global Boolean partnerOnboarding;

    @InvocableVariable
    global Integer trialDays;

    @InvocableVariable
    global String partnerAccount;

    // Invocable Method to be called from Screen Flow
    @InvocableMethod(label='Create Account Trial from Flow' description='Creates an account trial and processes Northpass subscription')
    global static void createTrialAccount(List<AccountTrialWrapper> accountContacts) {
        for (AccountTrialWrapper atw : accountContacts) {
            // Process each AccountTrialWrapper
            System.enqueueJob(new AccountTrialCreationQueueable(atw));
        }
    }
}
