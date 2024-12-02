@isTest
private class ContactTriggerHandlerTest 
{	
	@isTest static void test_method_one() 
    {
		// Data Setup
        Account newAccount = new Account();
        newAccount.Name = 'testAccountName';
        newAccount.Last_Stale_On__c = Date.today();
        insert newAccount;

        Account newAccount2 = new Account();
        newAccount2.Name = 'testAccount2Name';
        newAccount2.Last_Stale_On__c = Date.today();
        insert newAccount2;

        Contact newContact = new Contact();
        newContact.LastName  = 'testLastNameContact';
        newContact.AccountId = newAccount2.Id;
        insert newContact;

        AccountContactRelation newAccountContactRelation = new AccountContactRelation();
        newAccountContactRelation.AccountId = newAccount.Id;
        newAccountContactRelation.ContactId = newContact.Id;
        insert newAccountContactRelation;

        // Start Testing
        Test.startTest();
            update newContact;
        Test.stopTest();

        // Test Results
        List<Account> accountList = 
            [
                SELECT Id, Account_Warmth_Count__c, Stale_Account_Check__c, isPartner
                FROM Account 
                WHERE Name = 'testAccountName'
            ];
            
        System.assertEquals(1, accountList.size());
        //System.assertEquals(2, accountList[0].Account_Warmth_Count__c);
        //System.assertEquals(false, accountList[0].Stale_Account_Check__c);
	}

}