/*
*****************************************************************************
Created Date       : Feb 2025
@description       : Tests AccountTrialCreationQueueable, AccountTrialWrapper,
                    AccountPartnerClientQueueable, AccountTrigger afterUpdate
@author            : AKelly @ Nuage - Cin7-120
Modification Log:
Ver   Date         Author                    Modification
1.0   01-01-2025   Anthony Kelly          Initial Version
******************************************************************************
*/
@isTest
public class AccountTrialCreationQueueableTest {
    
    static final string CONTACT_REC_TYPE = [SELECT Id FROM RecordType WHERE Name = 'New Contact'].Id;
    static final Id CUSTOMER_ACC_TYPE = [SELECT Id FROM RecordType WHERE Name = 'Customer Account'].Id;        
    
    static void createAcctAndCon(Boolean createPartner) {
        // 1. Insert the Account record with unique name    
        // Randomized values for the Account fields
        String randomStreet = 'Street ' + String.valueOf(Crypto.getRandomInteger()) + ' ' + String.valueOf(System.currentTimeMillis());
        String randomCity = 'City ' + String.valueOf(Crypto.getRandomInteger());
        String randomState = 'California';
        String randomPostalCode = String.valueOf(Crypto.getRandomInteger()).substring(0, 5); // Simulate postal code
        String randomPhone = '555-' + String.valueOf(Crypto.getRandomInteger()).substring(0, 3) + '-' + String.valueOf(Crypto.getRandomInteger()).substring(0, 4); // Random phone number
    
        Account partnerAcct = new Account(
            Name = 'Partner Account',
            BillingStreet = '123 Any Street',
            BillingCity = 'Denver',
            BillingState = 'Colorado',
            BillingPostalCode = '55555',
            BillingCountry = 'United States',
            Core_Industry__c = 'BWS',
            Core_Plan_Type__c = 'Referral',
            DEAR_Tenant_Id__c = '1234567-8900203-454556',
            Core_Trial_Days__c = 60,
            Free_Trial_Demo_Data__c = true,
            Timezone__c = 'Pacific Standard Time (GMT-08:00)'
        );

        if (createPartner) {
            insert partnerAcct;
        }

        // Create a unique Account name by appending the current timestamp and a random integer
        Account account = new Account(
            Name = 'Test Client Account',
            BillingStreet = randomStreet,
            BillingCity = randomCity,
            BillingState = randomState,
            BillingPostalCode = randomPostalCode,
            BillingCountry = 'United States',
            Core_Industry__c = 'BWS',
            DEAR_Tenant_Id__c = null,
            Partner_Onboarding__c = createPartner ? true : false,
            Related_Partner_Account__c = createPartner ? partnerAcct.Id : '',
            Core_Trial_Days__c = 60,
            Free_Trial_Demo_Data__c = true,

            Timezone__c = 'Pacific Standard Time (GMT-08:00)',
            RecordTypeId = CUSTOMER_ACC_TYPE
        );
        insert account;
    
        // 2. Insert the Contact record with a unique name and email
        // Create a unique email by appending a random string
        String randomFirstName = 'Topher_' + String.valueOf(Crypto.getRandomInteger()); // Unique First Name
        String randomLastName = 'Doe_' + String.valueOf(System.currentTimeMillis()); // Unique Last Name
        String randomEmail = 'topher.doe_' + String.valueOf(Crypto.getRandomInteger()) + '@example.com'; // Unique Email
    
        Contact contact = new Contact(
            FirstName = randomFirstName,
            LastName = randomLastName,
            Email = randomEmail,
            Phone = randomPhone,
            AccountId = account.Id,
            RecordTypeId = CONTACT_REC_TYPE            
        );
        insert contact;
    }
    
    
    /**
     * Test the execution of the AccountTrialCreationQueueable with mock data.
     * This test verifies the functionality of the queueable job that handles trial account creation.
     */
    @isTest
    public static void testExecuteQueueableJob() {
        // 1. Setup: Create mock data for Account and Contact
        Account account = new Account(
            Name = 'New AK Test Account',
            BillingStreet = '123 Main St',
            BillingCity = 'Test City',
            BillingState = 'California',
            BillingPostalCode = '12345',
            BillingCountry = 'United States',
            Core_Industry__c = 'BWS',
            DEAR_Tenant_Id__c = null,
            Core_Trial_Days__c = 60,
            Free_Trial_Demo_Data__c = true,
            RecordTypeId = CUSTOMER_ACC_TYPE,
            Timezone__c = 'Pacific Standard Time (GMT-08:00)'
        );
        insert account;

        Contact contact = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'john.doe@example.com',
            Phone = '123-456-7890',
            AccountId = account.Id,
            RecordTypeId = CONTACT_REC_TYPE
        );
        insert contact;

        // 2. Create an instance of AccountTrialWrapper with test data
        AccountTrialWrapper wrapper = new AccountTrialWrapper();
        wrapper.accountId = account.Id;
        wrapper.contactId = contact.Id;
        wrapper.accountName = account.Name;
        wrapper.contactEmail = contact.Email;
        wrapper.contactName = contact.FirstName + ' ' + contact.LastName;
        wrapper.contactPhone = contact.Phone;
        wrapper.billingStreet = account.BillingStreet;
        wrapper.billingCity = account.BillingCity;
        wrapper.billingState = account.BillingState;
        wrapper.billingPostalCode = account.BillingPostalCode;
        wrapper.billingCountry = account.BillingCountry;
        wrapper.coreIndustry = account.Core_Industry__c;
        wrapper.trialDays = 30;
        wrapper.partnerOnboarding = false;
        wrapper.demoData = true;
        wrapper.timeZone = 'Pacific Standard Time (GMT-08:00)';
        
        List<AccountTrialWrapper> wrappers = new List<AccountTrialWrapper>{ wrapper };

        // 3. Set up the mock callout response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorCoreTrial());
        
        // 4. Run the Queueable job
        Test.startTest();
        AccountTrialWrapper.createTrialAccount(wrappers);
        Test.stopTest();

        // 5. Verify: Check if the DEAR_Tenant_Id__c was updated on the Account record
        Account updatedAccount = [SELECT DEAR_Tenant_Id__c, Core_Last_Updated_Date__c FROM Account WHERE Id = :account.Id];

        System.assertNotEquals(null, updatedAccount.DEAR_Tenant_Id__c, 'Tenant ID should be updated');
        System.assertEquals('newTenant123', updatedAccount.DEAR_Tenant_Id__c);
        System.assertNotEquals(null, updatedAccount.Core_Last_Updated_Date__c);

    }

    /**
     * Test the execution of the POST request for Partner-Client relationship.
     * This test ensures the POST request correctly handles the partner account data.
     */
    @isTest
    public static void testAccountTrialCreationWithPartnerAcct() {
        
        // Setup mock account and partner account data
        createAcctAndCon(true);
        Account clientAccount = [SELECT Id, BillingStreet, Name, BillingCity, Core_Industry__c, BillingState, BillingPostalCode, BillingCountry, DEAR_Tenant_ID__c FROM Account WHERE Name = 'Test Client Account' LIMIT 1];
        Account partnerAccount = [SELECT Id, Core_Plan_Type__c, DEAR_Tenant_ID__c FROM Account WHERE Name = 'Partner Account' LIMIT 1];
        Contact clientContact = [SELECT Id, FirstName, LastName, Email, Phone FROM Contact WHERE FirstName LIKE '%Topher%' LIMIT 1];

        // Create AccountTrialWrapper for the partner-client relationship
        AccountTrialWrapper wrapper = new AccountTrialWrapper();
        wrapper.accountId = clientAccount.Id;
        wrapper.contactId = clientContact.Id;
        wrapper.accountName = clientAccount.Name;
        wrapper.contactEmail = clientContact.Email;
        wrapper.contactName = clientContact.FirstName + ' ' + contact.LastName;
        wrapper.contactPhone = clientContact.Phone;
        wrapper.billingStreet = clientAccount.BillingStreet;
        wrapper.billingCity = clientAccount.BillingCity;
        wrapper.billingState = clientAccount.BillingState;
        wrapper.billingPostalCode = clientAccount.BillingPostalCode;
        wrapper.billingCountry = clientAccount.BillingCountry;
        wrapper.coreIndustry = clientAccount.Core_Industry__c;
        wrapper.trialDays = 60;
        wrapper.partnerOnboarding = true;
        wrapper.demoData = true;
        wrapper.partnerAccount = partnerAccount.Id;
        wrapper.timeZone = 'Pacific Standard Time (GMT-08:00)';
        wrapper.platformAccountStatus = 'Active';
        
        // Setup mock response for PUT callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorCoreTrial());

        // Run the queueable job
        Test.startTest();
            // AccountTrialWrapper.createTrialAccount(new List<AccountTrialWrapper>{ wrapper });
            System.enqueueJob(new AccountPartnerClientQueueable(
                wrapper.partnerAccount, wrapper.accountId, wrapper.partnerOnboarding
            ));
        Test.stopTest();
        
        // Verify the callout behavior
        Account updatedPartnerAcc = [SELECT DEAR_Tenant_Id__c, Core_Last_Updated_Date__c FROM Account WHERE Id = :partnerAccount.Id];
        // Verify that Partner Account Core Last Updated Date was recent
        System.assertNotEquals(null, updatedPartnerAcc.Core_Last_Updated_Date__c);
        System.assertEquals(System.today(), updatedPartnerAcc.Core_Last_Updated_Date__c.date());
    }

    /**
     * Test the execution of the POST request for Partner-Client relationship on
     * update from null Partner Account to Partner Account.
     */
    @isTest
    public static void testAccountPartnerJobOnRelatedPartnerUpdate() {
        
        // Setup mock account and partner account data
        createAcctAndCon(true);
        Account clientAccount = [SELECT Id, Core_Trial_Days__c, Partner_Onboarding__c, Website, Platform_Account_Status__c, Related_Partner_Account__c, Free_Trial_Demo_Data__c, Core_Coupon_Referral_Code__c, Timezone__c, BillingStreet, Name, BillingCity, Core_Industry__c, BillingState, BillingPostalCode, BillingCountry, DEAR_Tenant_ID__c FROM Account WHERE Name = 'Test Client Account' LIMIT 1];
        clientAccount.Partner_Onboarding__c = false;
        clientAccount.Dear_Tenant_Id__c = '1245154416614';
        clientAccount.Related_Partner_Account__c = null;
        update clientAccount;
        
        Account partnerAccount = [SELECT Id, Core_Plan_Type__c, DEAR_Tenant_ID__c FROM Account WHERE Name = 'Partner Account' LIMIT 1];
        Contact clientContact = [SELECT Id, FirstName, LastName, Email, Phone FROM Contact WHERE FirstName LIKE '%Topher%' LIMIT 1];
        
        // Setup mock response for PUT callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorCoreTrial());

        // Run the queueable job on Partner Acct Update
        Test.startTest();
            clientAccount.Related_Partner_Account__c = partnerAccount.Id;
            update clientAccount;
        Test.stopTest();
        
        // Verify the callout behavior
        Account updatedPartnerAcc = [SELECT DEAR_Tenant_Id__c, Core_Last_Updated_Date__c FROM Account WHERE Id = :partnerAccount.Id];
        // Verify that Partner Account Core Last Updated Date was recent
        System.assertNotEquals(null, updatedPartnerAcc.Core_Last_Updated_Date__c);
        System.assertEquals(System.today(), updatedPartnerAcc.Core_Last_Updated_Date__c.date());
    }


    /**
     * Test the execution of the POST request for Partner-Client relationship on
     * update from one Partner Account to another Partner Account.
     */
    @isTest
    public static void testAccountPartnerJobOnRelatedPartnerChange() {
        
        // Setup mock account and partner account data
        createAcctAndCon(true);
        Account clientAccount = [SELECT Id, Core_Trial_Days__c, Partner_Onboarding__c, Website, Platform_Account_Status__c, Related_Partner_Account__c, Free_Trial_Demo_Data__c, Core_Coupon_Referral_Code__c, Timezone__c, BillingStreet, Name, BillingCity, Core_Industry__c, BillingState, BillingPostalCode, BillingCountry, DEAR_Tenant_ID__c FROM Account WHERE Name = 'Test Client Account' LIMIT 1];
        clientAccount.Dear_Tenant_Id__c = '1245154416614';
        update clientAccount;
        
        Account partnerAccount = [SELECT Id, Core_Plan_Type__c, DEAR_Tenant_ID__c FROM Account WHERE Name = 'Partner Account' LIMIT 1];
        Contact clientContact = [SELECT Id, FirstName, LastName, Email, Phone FROM Contact WHERE FirstName LIKE '%Topher%' LIMIT 1];
        
        Account newPartnerAccount = new Account(
                Name = 'New Partner Account',
                BillingStreet = '456 Cool Street',
                BillingCity = 'Sactown',
                BillingState = 'California',
                BillingPostalCode = '99999',
                BillingCountry = 'United States',
                Core_Industry__c = 'BWS',
                Core_Plan_Type__c = 'Referral',
                DEAR_Tenant_Id__c = '42545664-8350203-454556',
                Core_Trial_Days__c = 60,
                Free_Trial_Demo_Data__c = true,
                Timezone__c = 'Pacific Standard Time (GMT-08:00)'
        );
        insert newPartnerAccount;
        

        // Setup mock response for PUT callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorCoreTrial());

        // Run the queueable job on Partner Acct Update
        Test.startTest();
            clientAccount.Related_Partner_Account__c = newPartnerAccount.Id;
            update clientAccount;
        Test.stopTest();
        
        // Verify the callout behavior
        Account updatedPartnerAcc = [SELECT DEAR_Tenant_Id__c, Core_Last_Updated_Date__c FROM Account WHERE Id = :newPartnerAccount.Id];
        // Verify that Partner Account Core Last Updated Date was recent
        System.assertNotEquals(null, updatedPartnerAcc.Core_Last_Updated_Date__c);
        System.assertEquals(System.today(), updatedPartnerAcc.Core_Last_Updated_Date__c.date());
    }

    /**
     * Test the execution of the POST request for Partner-Client relationship when
     * Client Account "Partner Onboarding" value changes
     */
    @isTest
    public static void testAccountPartnerJobOnPartnerOnboardingUpdate() {
        
        // Setup mock account and partner account data
        createAcctAndCon(true);
        Account clientAccount = [SELECT Id, Core_Trial_Days__c, Partner_Onboarding__c, Website, Platform_Account_Status__c, Related_Partner_Account__c, Free_Trial_Demo_Data__c, Core_Coupon_Referral_Code__c, Timezone__c, BillingStreet, Name, BillingCity, Core_Industry__c, BillingState, BillingPostalCode, BillingCountry, DEAR_Tenant_ID__c FROM Account WHERE Name = 'Test Client Account' LIMIT 1];
        clientAccount.Partner_Onboarding__c = false;
        clientAccount.Dear_Tenant_Id__c = '1245154416614';
        update clientAccount;
        
        Account partnerAccount = [SELECT Id, Core_Plan_Type__c, DEAR_Tenant_ID__c FROM Account WHERE Name = 'Partner Account' LIMIT 1];
        Contact clientContact = [SELECT Id, FirstName, LastName, Email, Phone FROM Contact WHERE FirstName LIKE '%Topher%' LIMIT 1];
        
        // Setup mock response for PUT callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorCoreTrial());

        // Run the queueable job on Partner Acct Update
        Test.startTest();
            clientAccount.Partner_Onboarding__c = true;
            update clientAccount;
        Test.stopTest();
        
        // Verify the callout behavior
        Account updatedPartnerAcc = [SELECT DEAR_Tenant_Id__c, Core_Last_Updated_Date__c FROM Account WHERE Id = :partnerAccount.Id];
        // Verify that Partner Account Core Last Updated Date was recent
        System.assertNotEquals(null, updatedPartnerAcc.Core_Last_Updated_Date__c);
        System.assertEquals(System.today(), updatedPartnerAcc.Core_Last_Updated_Date__c.date());
    }

    

    /**
     * Test that passing an Account and Contact to AccountTrialWrapper
     * successfully deserializes into an AccountTrialWrapper object.
     */
    @isTest
    public static void testAccountWrapperDeserialize() {
        
        // Setup mock account and partner account data
        createAcctAndCon(true);
        Account clientAccount = [SELECT Id, Core_Trial_Days__c, Partner_Onboarding__c, Website, Platform_Account_Status__c, Related_Partner_Account__c, Free_Trial_Demo_Data__c, Core_Coupon_Referral_Code__c, Timezone__c, BillingStreet, Name, BillingCity, Core_Industry__c, BillingState, BillingPostalCode, BillingCountry, DEAR_Tenant_ID__c FROM Account WHERE Name = 'Test Client Account' LIMIT 1];
        clientAccount.Partner_Onboarding__c = true;
        update clientAccount;
        
        Account partnerAccount = [SELECT Id, Core_Plan_Type__c, DEAR_Tenant_ID__c FROM Account WHERE Name = 'Partner Account' LIMIT 1];
        Contact clientContact = [SELECT Id, FirstName, LastName, Email, Phone FROM Contact WHERE FirstName LIKE '%Topher%' LIMIT 1];
        AccountTrialWrapper atw;
        Test.startTest();
            atw = AccountTrialWrapper.deserializeAccountToWrapper(clientAccount, clientContact);
        Test.stopTest();
        
        // Verify wrapper attributes populated correctly
        System.assertEquals(atw.accountId, clientAccount.Id);
        System.assertEquals(atw.contactId, clientContact.Id);
        System.assertEquals(atw.accountName, clientAccount.Name);
        System.assertEquals(atw.contactEmail, clientContact.Email);
        System.assert(atw.contactName.contains(clientContact.FirstName));
        System.assertEquals(atw.contactPhone, clientContact.Phone);
        System.assertEquals(atw.billingStreet, clientAccount.BillingStreet);
        System.assertEquals(atw.billingCity, clientAccount.BillingCity);
        System.assertEquals(atw.billingState,  clientAccount.BillingState);
        System.assertEquals(atw.billingPostalCode, clientAccount.BillingPostalCode);
        System.assertEquals(atw.billingCountry, clientAccount.BillingCountry);
        System.assertEquals(atw.coreIndustry, clientAccount.Core_Industry__c);
        System.assertEquals(atw.trialDays, 60);
        System.assertEquals(atw.partnerOnboarding, true);
        System.assertEquals(atw.demoData, true);
        System.assertEquals(atw.partnerAccount, partnerAccount.Id);
        System.assertEquals(atw.timeZone, 'Pacific Standard Time (GMT-08:00)');
    }
}