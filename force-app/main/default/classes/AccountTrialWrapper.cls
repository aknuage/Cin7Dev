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
    
    public static AccountTrialWrapper deserializeAccountToWrapper(Account acc, Contact contact) {
        // Initialize a new AccountTrialWrapper
        AccountTrialWrapper wrapper = new AccountTrialWrapper();
        
        // Map fields from Account to AccountTrialWrapper
        wrapper.accountId = acc.Id;
        wrapper.accountName = acc.Name;
        wrapper.billingStreet = acc.BillingStreet;
        wrapper.billingCity = acc.BillingCity;
        wrapper.billingState = acc.BillingState;
        wrapper.billingPostalCode = acc.BillingPostalCode;
        wrapper.billingCountry = acc.BillingCountry;
        wrapper.coreIndustry = acc.Core_Industry__c;
        wrapper.platformAccountStatus = acc.Platform_Account_Status__c;
        wrapper.timeZone = acc.Timezone__c;
        wrapper.websiteURL = acc.Website;
        wrapper.demoData = acc.Free_Trial_Demo_Data__c;
        wrapper.couponReferralCode = acc.Core_Coupon_Referral_Code__c;
        wrapper.partnerAccount = acc.Related_Partner_Account__c == null ? null : acc.Related_Partner_Account__c;
        wrapper.trialDays = acc.Core_Trial_Days__c == null ? null : acc.Core_Trial_Days__c.intValue();
        wrapper.partnerOnboarding = acc.Partner_Onboarding__c;

        // Map contact information if the contact is provided
        if (contact != null) {
            wrapper.contactId = contact.Id;
            wrapper.contactName = contact.FirstName + ' ' + contact.LastName;
            wrapper.contactEmail = contact.Email;
            wrapper.contactPhone = contact.Phone;
        }

        // Return the populated wrapper
        return wrapper;
    }
}