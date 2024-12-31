/**
 * @description       : 
 * @author            : AS | NuAge Experts
 * @group             : 
 * @last modified on  : 2023-05-11
 * @last modified by  : NuAge
**/
public with sharing class AccountTriggerHandler 
{
    public static void checkAccountPartnerStatus(Map<Id,Account> newAccounts, Map<Id,Account> oldAccounts) {
        if(NuAge_UtilityClass.CheckAutomationToRun('Account_checkAccountPartnerStatus')){
            for(Id newAcc : oldAccounts.keySet()){
                if(newAccounts.get(newAcc).Partner_Status__c != oldAccounts.get(newAcc).Partner_Status__c){
                    System.enqueueJob(new PartnerActivationQueueable(newAccounts.get(newAcc)));
                }
            }
        } 
    }

    /**
     * If an Account becomes a paid customer (their Platform Account Status = Onboarding, Live or Client), and they have a Dear Tenant Id
     * or a Cin7 User Name, the active contacts are subscribed to the Northpass LMS
     * 
     * Called by AccountTrigger after update      
     *    
     * @param newMap - map of accounts being updated
     * @param oldMap - newMap its prior form
     * @author nkoonce @ NuAge : CIN7-107 : May 2024
     */ 
    public static void ProcessAccountForNorthpass(Map<Id,Account> newMap, Map<Id,Account> oldMap)
    {
        List<API_Error_Log__c> errorLogs = new List<API_Error_Log__c>();

        // Get accounts that are newly qualified for Northpass
        Set<Id> accountIds = new Set<Id>();
        for (Account a : newMap.values())
        {
            if (a.Is_Northpass_Qualified__c && (a.Is_Northpass_Qualified__c != oldMap.get(a.Id).Is_Northpass_Qualified__c))
            {
                System.debug('account tenant id: ' + a.DEAR_Tenant_Id__c);
                System.debug('is account Northpass qualified: ' + a.Is_Northpass_Qualified__c + '. was account not qualified before? :' + oldMap.get(a.Id).Is_Northpass_Qualified__c);
                accountIds.add(a.Id);
            }
        }

        // Query for related active Contacts
        List<AccountContactRelation> acrs = [SELECT AccountId, Account.Dear_Tenant_Id__c, Account.Cin7_Username__c, ContactId,
                Contact.Firstname, Contact.Lastname, Contact.Email, Contact.Contact_Type__c
            FROM AccountContactRelation WHERE AccountId IN :accountIds and IsActive = true];

        if (acrs.size() == 0) return;

        // Map NP group Ids by name
        Map<String,String> northpassGroupIdsByName = NorthpassHelper.GetGroupIdsByName();

        // Iterate and build list of Contacts to send to Northpass
        List<NorthpassSubscriptionWrapper> subscriptionsToCreate = new List<NorthpassSubscriptionWrapper>();
        for (AccountContactRelation acr : acrs)
        {
            // Validate contacts for subscription (accounts have already been validated by virtue of the Is Northpass Qualified flag)
            if (String.isNotBlank(acr.Contact.FirstName) && String.isNotBlank(acr.Contact.LastName) && String.isNotBlank(acr.Contact.Email))
            {
                // Build the subscription wrapper
                NorthpassSubscriptionWrapper wrap = new NorthpassSubscriptionWrapper();

                wrap.data.attributes.type = 'people';
                wrap.data.attributes.first_name = acr.Contact.FirstName;
                wrap.data.attributes.last_name = acr.Contact.LastName;
                wrap.data.attributes.email = acr.Contact.Email;
                wrap.data.attributes.dear_tenant_id = acr.Account.Dear_Tenant_Id__c;

                // Determine which group the subscriber belongs to (Omni or Core) and add to the wrapper
                NorthpassHelper.AssignNorthpassGroup(acr, wrap, northpassGroupIdsByName);

                // If we found a valid group Id, create the user and assign them to the group
                if (wrap.data.attributes.northpass_group_id != null)
                {
                    subscriptionsToCreate.add(wrap);
                }
                else
                {
                    system.debug('Northpass Group Id not found');
                    API_Error_Log__c err = new API_Error_Log__c(
                        Error_Message__c = 'Northpass Group Id (Core/Omni) not found in this Salesforce environment'
                    );
                    errorLogs.add(err);
                }
            }
            else
            {
                system.debug('Contact doesn\'t qualify for Northpass subscription. Missing first name, last name, or email');
                API_Error_Log__c err = new API_Error_Log__c(
                    Error_Message__c = 'Contact (' + acr.Contact.Id + ') doesn\'t qualify for Northpass subscription. Missing first name, last name, or email'
                );
                errorLogs.add(err);
            }
        }

        // Subscribe contacts to Northpass
        if (subscriptionsToCreate.size() > 0) NorthpassHelper.CreateNorthpassSubscriptions(subscriptionsToCreate);

        // Insert error logs
        if (errorLogs.size() > 0) insert errorLogs;        
    }


    
}