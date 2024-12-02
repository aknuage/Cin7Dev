public class PreChatValuesController {
    
    @AuraEnabled
    public static user fetchUserDetails() {      

       User u = [ SELECT Id, FirstName, LastName, Email, Phone, Account.Name
                 FROM User
                 WHERE Id =: userInfo.getUserId() ];

       return u;
        
    }

}