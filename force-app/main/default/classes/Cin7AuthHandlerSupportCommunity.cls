global class Cin7AuthHandlerSupportCommunity implements Auth.RegistrationHandler{
    
    global boolean canCreateUser(Auth.UserData data) {
    
        // some logic to prevent certain users from login in
        //if(data.someField) {
            //return true;
        //}
        return true;
    }

    global User createUser(Id portalId, Auth.UserData data){

        System.debug('====================== data ' + data);
        System.debug('====================== data.username ' + data.username);
    
        if(!canCreateUser(data)) {
            return null;
        }
        
        List<User> userMatch = [SELECT Id FROM User WHERE Username =: data.username LIMIT 1];   
        System.debug('============= userMatch ' + userMatch);
        if (userMatch.size() > 0){
            return userMatch[0];
        }

        String contactId = data.attributeMap.get('salesforce_contact_id');
        String dataemail = data.email;
        if(!String.isBlank(contactId) && !dataemail.contains('@cin7.com') && contactId != '0030I00001SsRtz'){
            List<Contact> contactMatch = [SELECT Id FROM Contact WHERE Id =: data.attributeMap.get('salesforce_contact_id') LIMIT 1];  
            if(contactMatch.size() > 0) {
                return createCommunityUser(contactMatch[0].Id, data);
            }
        }
        
        List<Contact> emailMatch = [SELECT Id FROM Contact WHERE Email =: data.email LIMIT 1];
        if (emailMatch.size() > 0 && !dataemail.contains('@cin7.com')){
            return createCommunityUser(emailMatch[0].Id, data);
        }
        
        String accountId = data.attributeMap.get('salesforce_account_id');
        if(!String.isBlank(accountId)){
            List<Account> accountIdMatch = [SELECT Id FROM Account WHERE Id =: data.attributeMap.get('salesforce_account_id') LIMIT 1];
            if (accountIdMatch.size() > 0 && !dataemail.contains('@cin7.com')){
                Contact newContact = createCommunityContact(accountIdMatch[0].Id, data);
                return createCommunityUser(newContact.Id, data);
            }
        }
        
        return null;   	

    }

    global void updateUser(Id userId, Id portalId, Auth.UserData data){
        // option to update user information

    }
    
    private User createCommunityUser(Id contactId, Auth.UserData data){
        //TODO: Customize the username and profile. Also check that the username doesn't already exist and
        //possibly ensure there are enough org licenses to create a user. Must be 80 characters or less.
        User u = new User();
        if (!Test.isRunningTest()){
            List<Profile> p = [SELECT Id FROM profile WHERE name='Cin7 Customer Portal Login Member' LIMIT 1];
        	u.profileId = p[0].Id;   
        }
        u.username = data.username;
        u.email = data.email;
        if(String.isBlank(data.lastName)){
            u.lastName = 'UNKNOWN';
        }
        else{
            u.lastName = data.lastName;
        }
        u.firstName = data.firstName;
        String alias = data.username;
        //Alias must be 8 characters or less
        if(alias.length() > 8) {
            alias = alias.substring(0, 8);
        }
        u.alias = alias;
        u.languagelocalekey = 'en_US';
        String locale_sid = data.attributeMap.get('locale');
        u.localesidkey = locale_sid.replace('-', '_');
        u.emailEncodingKey = 'UTF-8';
        u.timeZoneSidKey = data.attributeMap.get('zoneinfo');
        u.contactId = contactId;
                        
        return u;    
    }
    
    private Contact createCommunityContact(Id accountId, Auth.UserData data){
        Contact newContact = new Contact();
        newContact.Contact_Type__c = 'Customer';
        newContact.FirstName = data.firstName;
        List<User> sysAdmin = [SELECT Id FROM User WHERE Alias = 'sysadmin'];
        newContact.OwnerId = sysAdmin[0].Id;
        if(String.isBlank(data.lastName)){
            newContact.LastName = 'UNKNOWN';
        }
        else{
            newContact.LastName = data.lastName;
        }
		newContact.Email = data.email;
        newContact.AccountId = accountId;
        
		insert newContact;
                        
        return newContact;    
    }
    
}