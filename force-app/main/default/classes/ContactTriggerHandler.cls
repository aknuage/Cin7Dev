public with sharing class ContactTriggerHandler
{
    /**
     * This method is responsible for updating stale accounts
     */
	public static void UpdateStaleAccounts(List<Contact> contactList)
    {
        List<Account> accountsToUpdate = new List<Account>();
        Set<Id> accIdSet = new Set<Id>();

        List<AccountContactRelation> accContactRelationList = [SELECT AccountId FROM AccountContactRelation WHERE ContactId IN :contactList];

        Map<String, Integer> accToNrOfContactsMap = new Map<String, Integer>();

        for(AccountContactRelation accContactRelation : accContactRelationList)
        {
            accIdSet.add(accContactRelation.AccountId);

            if(accToNrOfContactsMap.get(accContactRelation.AccountId) == null)
            {
                accToNrOfContactsMap.put(accContactRelation.AccountId, 1);
            }
            else
            {
                accToNrOfContactsMap.put(accContactRelation.AccountId, accToNrOfContactsMap.get(accContactRelation.AccountId) + 1);
            }
        }

        List<Account> accountList = [SELECT Id, Account_Warmth_Count__c, Stale_Account_Check__c, Last_Stale_On__c, isPartner 
                FROM Account WHERE Id IN :accIdSet];
        
        for(Account account : accountList)
        {
            if(account.Last_Stale_On__c != null && account.isPartner == false)
            {                
                if(account.Account_Warmth_Count__c != null)
                {
                    account.Account_Warmth_Count__c += accToNrOfContactsMap.get(account.Id);
                }
                else
                {
                    account.Account_Warmth_Count__c = accToNrOfContactsMap.get(account.Id);
                }

                account.Stale_Account_Check__c = false;
                accountsToUpdate.add(account);
            }
        }

        if(accountsToUpdate.size() > 0)  
        {
            Update accountsToUpdate;
        }
    }

    /**
     * When a contact is inserted, if its Account qualifies for Northpass subscription, subscribe the contact.
     * When a contat is updated, if its Account lookup changed to a qualifying account, subscribe the contact.
     * 
     * Called by ContactTrigger after insert or update
     * 
     * @param newList - list of Contacts inserted or updated
     * @return void
     * @author nkoonce @ NuAge : CIN7-107 : April 2024
     */ 
    public static void SubscribeToNorthpass(List<Contact> newList, Map<Id,Contact> oldMap)
    {
        system.debug('Is Insert? ' + Trigger.isInsert);
        system.debug('Is Update? ' + Trigger.isUpdate);

        List<API_Error_Log__c> errorLogs = new List<API_Error_Log__c>();

        // Get qualified contacts. If insert, all qualify. If update, those with changing account lookup qualify
        List<Contact> qualifiedContacts = new List<Contact>();
        Set<Id> accountIds = new Set<Id>();
        for (Contact c : newList)
        {
            if (Trigger.isInsert)
            {
                qualifiedContacts.add(c);
                accountIds.add(c.AccountId);
            }
            else if (Trigger.isUpdate)
            {
                if (String.isNotBlank(c.AccountId) && c.AccountId != oldMap.get(c.Id).AccountId) 
                {
                    qualifiedContacts.add(c);
                    accountIds.add(c.AccountId);
                }
            }
        }
        // Query for qualified account records
        Map<Id,Account> accountMap = new Map<Id,Account>([SELECT Id, Dear_Tenant_Id__c, Cin7_Username__c 
                FROM Account WHERE Id IN :accountIds AND Is_Northpass_Qualified__c = true]);

        // Get active ACRs for each contact/qualified account combo
        List<AccountContactRelation> acrs = [SELECT AccountId, Account.Dear_Tenant_Id__c, Account.Cin7_Username__c, ContactId,
                Contact.Firstname, Contact.Lastname, Contact.Email, Contact.Contact_Type__c
            FROM AccountContactRelation WHERE AccountId IN :accountMap.keySet() AND IsActive = true AND ContactId IN :qualifiedContacts];

        // Get map of Northpass group Ids, keyed by their group name
        Map<String,String> northpassGroupIdsByName = NorthpassHelper.GetGroupIdsByName();

        // Build list of subscribers to create
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
                wrap.data.attributes.dear_tenant_Id = acr.Account.Dear_Tenant_Id__c;

                // Determine which group the subscriber belongs to (Omni or Core) and add to the wrapper
                NorthpassHelper.AssignNorthpassGroup(acr, wrap, northpassGroupIdsByName);

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