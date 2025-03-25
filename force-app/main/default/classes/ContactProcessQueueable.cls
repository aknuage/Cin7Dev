/**
 * @description       : 
 * @author            : AS | NuAge Experts
 * @group             : 
 * @last modified on  : 03-26-2024
 * @last modified by  : AS | NuAge Experts
**/
//KNOWN ERROR - Private Contacts = When a Contact exists in Salesforce but the Contact is not related to any Account. Discovered during Apex Unit tests 
public with sharing class ContactProcessQueueable implements Queueable
{ 
    List<IncomingRequestJSONParse.Users> cin7Users = new List<IncomingRequestJSONParse.Users>();
    String tenantId;
    Id sfAccountId;
    public static Integer executionCount = 0;

    // Constructor
    public ContactProcessQueueable(List<IncomingRequestJSONParse.Users> cin7_users, String tenant_id) 
    {
        cin7Users = cin7_users;
        tenantId = tenant_id;
        system.debug(tenantId);
        sfAccountId = [SELECT Id FROM Account WHERE DEAR_Tenant_ID__c = :tenantId].Id;
    }

    public ContactProcessQueueable(IncomingRequestHelper.ContactJobInputWrapper wrapper) 
    {
        cin7Users = wrapper.users;
        tenantId = wrapper.tenantId;
        system.debug(tenantId);
        sfAccountId = [SELECT Id FROM Account WHERE DEAR_Tenant_ID__c = :tenantId].Id;
    }

    public void execute(QueueableContext context)
    {
        executionCount++;
        // Collect core user ids and core email addresses
        Set<String> cin7UserIds = new Set<String>();
        Set<String> cin7UserEmails = new Set<String>();
        for (IncomingRequestJSONParse.Users u : cin7Users)
        {
            cin7UserIds.add(u.UserId);
            cin7UserEmails.add(u.Email);
        }

        // Query for matching contacts
        List<Contact> matchingContacts =[SELECT Id, Name, FirstName, LastName, Phone, Email,DEAR_Tenant_ID__c, 
                    AccountId, Account.DEAR_Tenant_ID__c, Cin7_CORE_User_ID__c 
                FROM Contact WHERE Cin7_Core_User_Id__c IN :cin7UserIds OR (Cin7_Core_User_Id__c = null AND Email IN :cin7UserEmails)];  
        
        // Iterate core users and choose one of 3 paths:
        //  - Contact match is found by user id (if tenant Id matches, update update remaining fields)
        //  - Contact match is found by Email (if tenant Id matches, update user Id and remaining fields)
        //      - If contact match found and tenant Id does not match, create an Account Contact Relationship and update the contact fields to match incoming data
        //  - Contact match is not found (create a new contact - ACR will be auto-created in this case)
        List<Contact> contactsToInsert = new List<Contact>();
        Map<Id,Contact> contactsToUpdate = new Map<Id,Contact>();
        Map<Id,String> matchedContactIdToRole = new Map<Id,String>();  // Used in the creation of new ACRs for matched contacts that aren't already associated with the sfAccount
        for (IncomingRequestJSONParse.Users u : cin7Users)
        {
            // Look for contact match
            Contact matchingContact;
            for (Contact c : matchingContacts)
            {
                System.debug('matching contact? : ' + c.Name);
                // Did we match on Email only? If so, update the Cin7 Core User Id
                if (String.isBlank(c.Cin7_Core_User_Id__c) && c.Email == u.Email)
                {
                    // Load matching contact and update the core user id
                    matchingContact = c;
                    matchingContact.Cin7_Core_User_Id__c = u.UserId;
                }
                // Did we match on user id?
                else if (c.Cin7_Core_User_Id__c == u.UserId)
                {
                    matchingContact = c;
                }

                // If we found a match, update remaining fields
                if (matchingContact != null)
                {
                    // Matching contact found, update contact fields to match
                    // If incoming first/last populated but different than existing first/last, update existing.
                    String newFirstName = defaultFirstNameIfBlank(u);
                    String newLastName = u.DisplayName.substringAfter(' ');
                    if (String.isNotBlank(newFirstName) && newFirstName.trim() != matchingContact.FirstName?.trim()) matchingContact.FirstName = newFirstName;
                    if (String.isNotBlank(newLastName) && newLastName.trim() != matchingContact.LastName?.trim()) matchingContact.LastName = newLastName;
                    // If existing last name is blank and incoming DisplayName is blank, give the contact the default last name
                    if (String.isBlank(matchingContact.FirstName) && String.isBlank(matchingContact.LastName) && String.isBlank(u.DisplayName)) matchingContact.LastName = setDefaultNameIfBlank('');

                    matchingcontact.Email = u.Email;    
                    contactsToUpdate.put(matchingContact.Id, matchingContact);

                    // Map the matched ContactId to the sfAccountId we're processing. Used to determine if new ACRs need to be created
                    matchedContactIdToRole.put(matchingContact.Id, u.UserType);
                    
                    break;  // We found a matching contact, so break out of the contact matching loop
                }
            }

            // If we didn't find a matching Contact create a new contact and associate it to this Account (which will auto-create an Account Contact Relationship)
            if (matchingContact == null)
            {
                System.debug('non matching contact: ' + u.DisplayName);
                String firstName = defaultFirstNameIfBlank(u);
                String lastName = String.isNotBlank(u.DisplayName) ? u.DisplayName.substringAfter(' ') : 'Cin7 Core User';
                
                // Ensure last name is properly assigned
                if (String.isBlank(lastName)) {
                    lastName = setDefaultNameIfBlank('');
                }
                
                Contact newContact = new Contact(
                    FirstName = firstName,
                    LastName = lastName,
                    AccountId = sfAccountId,
                    Email = u.Email,
                    Cin7_Core_User_Id__c = u.UserId
                );
                contactsToInsert.add(newContact);
            }
        }
        
        // Query for ACRs already associated with our sfAccount
        List<AccountContactRelation> existingAcrs = [SELECT ContactId, IsActive, IsDirect, EndDate FROM AccountContactRelation WHERE AccountId =: sfAccountId];
        
        // Are there new ACRs to add?
        List<AccountContactRelation> acrsToInsert = new List<AccountContactRelation>();
        for (Id matchedContactId : matchedContactIdToRole.keySet())
        {
            Boolean matchFound = false;
            for (AccountContactRelation acr : existingAcrs)
            {
                if (acr.ContactId == matchedContactId)
                {
                    matchFound = true;
                    break;
                }
            }

            // If we didn't find a match then we need a new ACR
            if (matchFound == false)
            {
                acrsToInsert.add(new AccountContactRelation(
                    ContactId = matchedContactId,
                    AccountId = sfAccountId,
                    IsActive = true,
                    Roles = matchedContactIdToRole.get(matchedContactId),
                    StartDate = Date.today()
                ));
            }
        }

        // Iterate over the Account Contact Relationships for this Account. Delete ACRs associated to Contacts not represented
        //  in this Core User upload. If a matched ACR is inactive, activate it.
        List<AccountContactRelation> acrsToUpdate = new List<AccountContactRelation>();
        List<AccountContactRelation> acrsToDelete = new List<AccountContactRelation>();
        for(AccountContactRelation acr : existingAcrs)
        {
            // If the ACR doesn't match any of the contacts we matched to incoming users, delete the ACR
            if(!contactsToUpdate.keySet().contains(acr.ContactId)) 
            {
                system.debug(acr.IsDirect);
                // If the ACR "isDirect" (meaning the Account is the Contact's primary account) then we can't delete, we have to deactivate
                if (acr.IsDirect)
                {
                    acr.isActive = false;
                    acr.EndDate = Date.today();
                    acrsToUpdate.add(acr);
                }
                // If the ACR is not direct, we can delete it
                else
                {
                    acrsToDelete.add(acr);
                }
            }
            // If ACR matches a contact that we've matched to incoming user, make sure the ACR's "isActive" flag is checked
            else if (acr.isActive == false)
            {
                acr.isActive = true;
                acrsToUpdate.add(acr);
            }
        }        

        // DML
        List<API_Error_Log__c> errLog = new List<API_Error_Log__c>();
        
        if (contactsToInsert.size() > 0) Database.insert(contactsToInsert, false);
        if (contactsToUpdate.size() > 0) Database.update(contactsToUpdate.values(), false);
        if (acrsToDelete.size() > 0) Database.delete(acrsToDelete, false);
        if (acrsToUpdate.size() > 0) Database.update(acrsToUpdate, false);
        if (acrsToInsert.size() > 0) 
        {
            List<Database.saveResult> insertResults = Database.insert(acrsToInsert, false);

            for (Database.saveResult res : insertResults)
            {
                if (!res.isSuccess())
                {
                    API_Error_Log__c el = new API_Error_Log__c();
    
                    String msg = 'ACR insert error: ';
    
                    for (Database.Error err : res.getErrors())
                    {
                        msg += err.getStatusCode() + ', ' + err.getMessage();
    
                        if (err.getFields().size() > 0) 
                        {
                            msg += ', Fields: ';
    
                            for (String fld : err.getFields())
                            {
                                msg += fld + ', ';
                            }
                            msg = msg.removeEnd(', ');
                        }
                        el.Error_Message__c = msg;
                    }
                    errLog.add(el);
                    System.debug('Error in Contact Process Queueable: ' + JSON.serializePretty(el));
                }
            }

            // Insert error log
            if (errLog.size() > 0) insert errLog;
        }
    }

    /**
     * If User's first name needs to be updated, set it to the string before their Display Name.
     * If that is blank, set it to the string before the @domain.com portion of their email address.
     * Else return empty string;
     * 
     * @param IncomingRequestJSONParse.Users user 
     * @return string
     * @author Akelly @ NuAge : CIN7-132 : March 2025
     */
    private String defaultFirstNameIfBlank(IncomingRequestJSONParse.Users user) 
    {
        System.debug('entering default first name: ' + user.DisplayName);
    
        if (String.isNotBlank(user.DisplayName)) {
            if (user.DisplayName.contains(' ') && !String.isBlank(user.DisplayName.subStringBefore(' '))) {
                return user.DisplayName.substringBefore(' ');
            }
        }
        
        if (String.isNotBlank(user.Email) && user.Email.contains('@')) {
            return user.Email.substringBefore('@').capitalize();
        }
    
        return ''; // Fall back on blank string
    }
    
    
    
    /**
     * If string passed-in is blank, set to 'Cin7 Core User' and return the result.
     * 
     * @param lastName 
     * @return string set to 'Cin7 Core User' if lastName is blank, otherwise return lastName
     * @author nkoonce @ NuAge : CIN7-80 : May 2024, CIN7-113 : Change "Default Name" assignment to "Cin7 Core User"
     */
    private String setDefaultNameIfBlank(String lastName)
    {
        String returnValue = 'Cin7 Core User';

        if (String.isNotBlank(lastName)) returnValue = lastName;
        
        return returnValue;
    } 
}