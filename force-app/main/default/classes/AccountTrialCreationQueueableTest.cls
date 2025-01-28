@isTest
public class AccountTrialCreationQueueableTest {
    static final Id CUSTOMER_ACC_TYPE = [SELECT Id FROM RecordType WHERE Name = 'Customer Account'].Id;        
    static final string CONTACT_REC_TYPE = [SELECT Id FROM RecordType WHERE Name = 'New Contact'].Id;
    
    static void createAcctAndCon() {
        // 1. Insert the Account record with unique name
        static final Id CUSTOMER_ACC_TYPE = [SELECT Id FROM RecordType WHERE Name = 'Customer Account'].Id;
        static final string CONTACT_REC_TYPE = [SELECT Id FROM RecordType WHERE Name = 'New Contact'].Id;
    
        // Randomized values for the Account fields
        String randomStreet = 'Street ' + String.valueOf(Crypto.getRandomInteger()) + ' ' + String.valueOf(System.currentTimeMillis());
        String randomCity = 'City ' + String.valueOf(Crypto.getRandomInteger());
        String randomState = 'California';
        String randomPostalCode = String.valueOf(Crypto.getRandomInteger()).substring(0, 5); // Simulate postal code
        String randomPhone = '555-' + String.valueOf(Crypto.getRandomInteger()).substring(0, 3) + '-' + String.valueOf(Crypto.getRandomInteger()).substring(0, 4); // Random phone number
    
        // Create a unique Account name by appending the current timestamp and a random integer
        Account account = new Account(
            Name = 'Test Account ' + String.valueOf(Crypto.getRandomInteger()) + '_' + String.valueOf(System.currentTimeMillis()), // Unique Name
            BillingStreet = randomStreet,
            BillingCity = randomCity,
            BillingState = randomState,
            BillingPostalCode = randomPostalCode,
            BillingCountry = 'United States',
            Core_Industry__c = 'BWS',
            DEAR_Tenant_Id__c = null,
            Related_Partner_Account__c = '001Og000008stUaIAI', // Corrected: Added comma here
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

        // TODO: Create Related Partner Account

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
            Related_Partner_Account__c = '0019j00000YCiD5AAL',
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
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        // 4. Run the Queueable job
        Test.startTest();
        AccountTrialWrapper.createTrialAccount(wrappers);
        Test.stopTest();

        // 5. Verify: Check if the DEAR_Tenant_Id__c was updated on the Account record
        Account updatedAccount = [SELECT DEAR_Tenant_Id__c FROM Account WHERE Id = :account.Id];
        System.assertNotEquals(null, updatedAccount.DEAR_Tenant_Id__c, 'Tenant ID should be updated');
    }

    /**
     * Test the execution of the PUT request for Partner-Client relationship.
     * This test ensures the PUT request correctly handles the partner account data.
     */
    @isTest
    public static void testPartnerClientRelationshipPut() {
        // Setup mock account and partner account data
        Account partnerAccount = new Account(Name = 'Partner Account', DEAR_Tenant_Id__c = 'partnerTenant123', Core_Plan_Type__c = 'Premium');
        insert partnerAccount;

        Account clientAccount = new Account(Name = 'Client Account');
        insert clientAccount;

        Contact clientContact = new Contact(FirstName = 'Jane', LastName = 'Smith', Email = 'jane.smith@example.com');
        insert clientContact;

        // Create AccountTrialWrapper for the partner-client relationship
        AccountTrialWrapper wrapper = new AccountTrialWrapper();
        wrapper.accountId = clientAccount.Id;
        wrapper.contactId = clientContact.Id;
        wrapper.partnerAccount = partnerAccount.Id;
        wrapper.platformAccountStatus = 'Active';
        wrapper.contactName = clientContact.FirstName + ' ' + clientContact.LastName;
        wrapper.contactEmail = clientContact.Email;
        wrapper.timeZone = 'Pacific Standard Time (GMT-08:00)';
        wrapper.partnerOnboarding = true;

        // Setup mock response for PUT callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Run the queueable job
        Test.startTest();
        AccountTrialWrapper.createTrialAccount(new List<AccountTrialWrapper>{ wrapper });
        Test.stopTest();

        // Verify the callout behavior
        // In this case, you would verify that the PUT request was made to the correct endpoint
        // and the partner relationship was processed correctly (this will depend on how the mock response is handled).
    }
}

/**
 * Mock HTTP response generator for simulating callouts during tests.
 */
class MockHttpResponseGenerator implements HttpCalloutMock {
    /**
     * This method simulates the HTTP response for both POST and PUT requests.
     * 
     * @param req HttpRequest - The request object for the callout.
     * @return HTTPResponse - The simulated response.
     */
    public HTTPResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        
        // Simulate a 200 OK response for both POST and PUT endpoints
        res.setStatusCode(200);
        
        // Simulated response body for POST request (account creation)
        if (req.getEndpoint().contains('createaccount')) {
            res.setBody('{"StatusCode":"account_created","Data":{"TenantID":"newTenant123","RequestID":"request123"}}');
        }
        
        // Simulated response body for PUT request (partner-client relationship)
        if (req.getEndpoint().contains('partnerclientrelationship')) {
            res.setBody('{"StatusCode":"organization_created","Data":{"TenantID":"partnerTenant123","RequestID":"request456"}}');
        }

        return res;
    }
}
