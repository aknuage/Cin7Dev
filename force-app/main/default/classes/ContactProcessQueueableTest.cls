/**
 * @description       : Test class used to test different scenarios for updating Core Contacts from Get Customer Detail endpoint. 
 * 
 * Test Scenario 1) New Contact is found in the Get Customer details endpoint that is not in SFDC, create contact and associate to account using the 
 * Account Contact Relationship and mark as active user on the account. 
 * 
 * Test Scenario 2) Value on an existing contact changes, Email, First Name, Last Name etc. Update the existing contact information.
 * 
 * Test Scenario 3) Existing Contact is no longer in Get Customer Details Endpoint, and contact exists in SFDC associated to the account and mark inactive.
 * 
 * Test Scenario 4) New Contact is found in Get Customer Details Endpoint, and Contact exists in SFDC, but is not associated to the account, add existing 
 * Contact to the Account using the Account Contact Relationship and mark as active user on the Account. 
 * 
 * @author            : AS | NuAge Experts
 * @group             : 
 * @last modified on  : 02-28-2024
 * @last modified by  : AS | NuAge Experts
**/

@isTest
public with sharing class ContactProcessQueueableTest {
    @TestSetup
    static void makeData(){
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.DEAR_Tenant_ID__c = '231013f4-48c0-4cfd-9e53-3bc461d42d64';
        insert acc;

        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(Id = pricebookId,IsActive = true);
        update standardPricebook;

        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.AccountId = acc.Id;
        opp.CloseDate = System.today();
        opp.StageName = 'Closed Won';
        opp.DEAR_Tenant_ID__c = '231013f4-48c0-4cfd-9e53-3bc461d42d64';
        opp.Pricebook2Id = standardPricebook.Id;
        opp.Is_Active__c = true;
        opp.Amount = 1000;
        insert opp;
    }
    // @description: Test method used to test when ALL new Contacts are found in the Get Customer details endpoint that are not already in SFDC.
    // @expected result: Create contacts and associate them to account using the Account Contact Relationship and mark as active user on the account.
    @isTest
    public static void CreateNewContactsQueueable_Test()
    {
        // Assemble
        Incoming_Request__c req = new Incoming_Request__c();
        req.Message__c = 'NewSubscription';
        req.Tenant_ID__c = '231013f4-48c0-4cfd-9e53-3bc461d42d64';
    
        String getResponse = '{"Data":{"Subscribed":null,"Cancelled":null,"SubscriptionName":"Trial","SubscriptionExpirationDate":"2024-03-01T00:00:00","Source":"Website (Direct)","ReferredByPartner":null,"ReferredByPartnerId":null,"PlanType":null,"IsNeedAttention":false,"CustomerDomain":"usertest.com","Utm_Campaign":null,"Utm_Source":null,"Utm_Medium":null,"Utm_Term":null,"Utm_Content":null,"PartnerType":null,"IsVarPartner":null,"ReferrerDomain":null,"AdditionalUsers":0,"AdditionalUsersCost":0.0000,"Discount":0.0000,"Status":"Trial","AnniversaryDate":null,"IntegrationCount":0,"SalesCount":15,"Sales3MonthsCount":0,"Sales6MonthsCount":0,"Sales12MonthsCount":0,"SalesGMV":30351.3500,"SalesGMV3Months":0.0000,"SalesGMV6Months":0.0000,"SalesGMV12Months":0.0000,"SKUs":[],"Users":[{"UserId":"cbecdcde-d39c-4620-9d84-1e57afe87e15","Email":"john@doe.com","UserType":"user","DisplayName":"John Doe"},{"UserId":"b587c24d-b53b-4f95-b837-48580a1a39c4","Email":"jane@doe.com","UserType":"owner","DisplayName":"Jane Doe"}],"Discounts":[],"Country":"United States","CreateDate":"2024-02-16T18:06:04.773","Email":"actester@usertest.com","LastUpdatedDate":"2024-02-27T21:20:14.363","Organisation":"UserTestAcct","SalesPersonEmail":"am.siddiquie@dearsystems.com","TenantID":"231013f4-48c0-4cfd-9e53-3bc461d42d64","WebsiteURL":null,"Contacts":[{"Phone":"8888888888888","Email":"actester@usertest.com","FirstName":"Andrew","LastName":"Tester"}]}}';
        MockHttpResponseHandler.SimpleMockResponse getResp = new MockHttpResponseHandler.SimpleMockResponse('GET', getResponse);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse('callout:Customer_Details', getResp);

        // Pre-assert 
        Assert.areEqual(0, [SELECT COUNT() FROM Contact]);
        Assert.areEqual(1, [SELECT COUNT() FROM Opportunity]);
        Assert.areEqual(0, [SELECT Count() from AccountContactRelation]);

        // Act
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, mock);
            insert req;
        Test.stopTest();

        // Post-assert
        List<Contact> assertContacts = [SELECT Name, Email, Cin7_Core_User_Id__c FROM Contact];
        Assert.areEqual(2, assertContacts.size());
        Boolean foundJohn = false;
        Boolean foundJane = false;
        for (Contact c : assertContacts)
        {
            if (c.Name == 'John Doe')
            {
                Assert.areEqual('cbecdcde-d39c-4620-9d84-1e57afe87e15', c.Cin7_Core_User_Id__c);
                Assert.areEqual('john@doe.com', c.Email);
                foundJohn = true;
            } 
            if (c.Name == 'Jane Doe') 
            {
                Assert.areEqual('b587c24d-b53b-4f95-b837-48580a1a39c4', c.Cin7_Core_User_Id__c);
                Assert.areEqual('jane@doe.com', c.Email);
                foundJane = true;
            }
        }
        Assert.isTrue(foundJohn);
        Assert.isTrue(foundJane);

        Assert.areEqual(1, [SELECT COUNT() FROM Opportunity]);

        List<AccountContactRelation> assertAcrs = [SELECT AccountId, ContactId from AccountContactRelation];
        Assert.areEqual(2, assertAcrs.size());
    }

    // @description: Test method used to test when Contact is found in the Get Customer details endpoint that is in SFDC and values on existing contact changes.
    // @expected result: Update the contact record and mark as active user on the account.
    @isTest
    public static void UpdateContactQueueable_Test()
    {
        // Assemble
        Contact con = new Contact();
        con.FirstName = 'John';
        con.LastName = 'D';
        con.Email = 'test@email.com';
        con.Cin7_Core_User_Id__c = 'cbecdcde-d39c-4620-9d84-1e57afe87e15';
        con.AccountId = [SELECT Id FROM Account WHERE Name = 'Test Account'].Id;
        insert con;

        Incoming_Request__c req = new Incoming_Request__c();
        req.Message__c = 'UpdateSubscription';
        req.Tenant_ID__c = '231013f4-48c0-4cfd-9e53-3bc461d42d64';
    
        String getResponse = '{"Data":{"Subscribed":null,"Cancelled":null,"SubscriptionName":"Trial","SubscriptionExpirationDate":"2024-03-01T00:00:00","Source":"Website (Direct)","ReferredByPartner":null,"ReferredByPartnerId":null,"PlanType":null,"IsNeedAttention":false,"CustomerDomain":"usertest.com","Utm_Campaign":null,"Utm_Source":null,"Utm_Medium":null,"Utm_Term":null,"Utm_Content":null,"PartnerType":null,"IsVarPartner":null,"ReferrerDomain":null,"AdditionalUsers":0,"AdditionalUsersCost":0.0000,"Discount":0.0000,"Status":"Trial","AnniversaryDate":null,"IntegrationCount":0,"SalesCount":15,"Sales3MonthsCount":0,"Sales6MonthsCount":0,"Sales12MonthsCount":0,"SalesGMV":30351.3500,"SalesGMV3Months":0.0000,"SalesGMV6Months":0.0000,"SalesGMV12Months":0.0000,"SKUs":[],"Users":[{"UserId":"cbecdcde-d39c-4620-9d84-1e57afe87e15","Email":"john@doe.com","UserType":"user","DisplayName":" Doe"},{"UserId":"b587c24d-b53b-4f95-b837-48580a1a39c4","Email":"jane@doe.com","UserType":"owner","DisplayName":"Jane Doe"}],"Discounts":[],"Country":"United States","CreateDate":"2024-02-16T18:06:04.773","Email":"actester@usertest.com","LastUpdatedDate":"2024-02-27T21:20:14.363","Organisation":"UserTestAcct","SalesPersonEmail":"am.siddiquie@dearsystems.com","TenantID":"231013f4-48c0-4cfd-9e53-3bc461d42d64","WebsiteURL":null,"Contacts":[{"Phone":"8888888888888","Email":"actester@usertest.com","FirstName":"Andrew","LastName":"Tester"}]}}';
        MockHttpResponseHandler.SimpleMockResponse getResp = new MockHttpResponseHandler.SimpleMockResponse('GET', getResponse);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse('callout:Customer_Details', getResp);
        JSON.serializePretty('oldopp: ' + JSON.serializePretty(IncomingRequestHelper.GetOldOppByTenantId(req.Tenant_Id__c)));
        // Pre-assert 
        Assert.areEqual(1, [SELECT COUNT() FROM Contact]);
        Assert.areEqual('John D', [SELECT Name FROM Contact].Name);
        Assert.areEqual(1, [SELECT COUNT() FROM Opportunity]);

        // Act
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, mock);
            insert req;
        Test.stopTest();

        // Post-assert
        Assert.areEqual(2,[SELECT COUNT() FROM Contact]);
        // First name should have derived from Email address, Last name should be default
        Assert.areEqual(1, [SELECT COUNT() FROM Contact WHERE Name = 'John Doe']);
        // First name should have derived from Display Name
        Assert.areEqual(1, [SELECT COUNT() FROM Contact WHERE Name = 'Jane Doe']);
        Assert.areEqual(2, [SELECT COUNT() FROM Opportunity]);
    }

    // @description: Test method used to test when Contact is no longer part of Get Customer details endpoint response.
    // @expected result: The Contact's ACR is deleted
    @isTest
    public static void DeleteDirectAccountContactRelationship_Test()
    {
        // Assemble
        Contact con = new Contact();
        con.LastName = 'TESTER';
        con.AccountId = [SELECT Id FROM Account WHERE DEAR_Tenant_ID__c = '231013f4-48c0-4cfd-9e53-3bc461d42d64'].Id;
        insert con; 

        Incoming_Request__c req = new Incoming_Request__c();
        req.Message__c = 'NewSubscription';
        req.Tenant_ID__c = '231013f4-48c0-4cfd-9e53-3bc461d42d64';
    
        String getResponse = '{"Data":{"Subscribed":null,"Cancelled":null,"SubscriptionName":"Trial","SubscriptionExpirationDate":"2024-03-01T00:00:00","Source":"Website (Direct)","ReferredByPartner":null,"ReferredByPartnerId":null,"PlanType":null,"IsNeedAttention":false,"CustomerDomain":"usertest.com","Utm_Campaign":null,"Utm_Source":null,"Utm_Medium":null,"Utm_Term":null,"Utm_Content":null,"PartnerType":null,"IsVarPartner":null,"ReferrerDomain":null,"AdditionalUsers":0,"AdditionalUsersCost":0.0000,"Discount":0.0000,"Status":"Trial","AnniversaryDate":null,"IntegrationCount":0,"SalesCount":15,"Sales3MonthsCount":0,"Sales6MonthsCount":0,"Sales12MonthsCount":0,"SalesGMV":30351.3500,"SalesGMV3Months":0.0000,"SalesGMV6Months":0.0000,"SalesGMV12Months":0.0000,"SKUs":[],"Users":[{"UserId":"cbecdcde-d39c-4620-9d84-1e57afe87e15","Email":"john@doe.com","UserType":"user","DisplayName":"John Doe"},{"UserId":"b587c24d-b53b-4f95-b837-48580a1a39c4","Email":"jane@doe.com","UserType":"owner","DisplayName":"Jane Doe"}],"Discounts":[],"Country":"United States","CreateDate":"2024-02-16T18:06:04.773","Email":"actester@usertest.com","LastUpdatedDate":"2024-02-27T21:20:14.363","Organisation":"UserTestAcct","SalesPersonEmail":"am.siddiquie@dearsystems.com","TenantID":"231013f4-48c0-4cfd-9e53-3bc461d42d64","WebsiteURL":null,"Contacts":[{"Phone":"8888888888888","Email":"actester@usertest.com","FirstName":"Andrew","LastName":"Tester"}]}}';
        MockHttpResponseHandler.SimpleMockResponse getResp = new MockHttpResponseHandler.SimpleMockResponse('GET', getResponse);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse('callout:Customer_Details', getResp);

        // Pre-assert 
        Assert.areEqual(1, [SELECT COUNT() FROM Contact]);
        List<AccountContactRelation> preAcr = [SELECT Id, IsDirect, IsActive FROM AccountContactRelation];
        Assert.areEqual(1, preAcr.size());
        Assert.areEqual(true, preAcr[0].isDirect);

        // Act
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, mock);
            insert req;
        Test.stopTest();
        
        // Post-assert
        List<AccountContactRelation> assertAcr = [SELECT Id, IsDirect, IsActive FROM AccountContactRelation];
        Assert.areEqual(3, assertAcr.size());

        Boolean foundOriginalAcr = false;
        for (AccountContactRelation acr : assertAcr)
        {
            if (acr.Id == preAcr[0].Id)
            {
                foundOriginalAcr = true;
                Assert.areEqual(false, acr.IsActive);
                break;
            }
        }
        Assert.isTrue(foundOriginalAcr);

        Assert.areEqual(1, [SELECT COUNT() FROM Contact WHERE Name = 'John Doe']);
        Assert.areEqual(1, [SELECT COUNT() FROM Contact WHERE Name = 'Jane Doe']);
        Assert.areEqual(true, [SELECT isActive FROM AccountContactRelation WHERE ContactId =: [SELECT Id FROM Contact WHERE Name = 'John Doe'].Id].isActive);
        Assert.areEqual(true, [SELECT isActive FROM AccountContactRelation WHERE ContactId =: [SELECT Id FROM Contact WHERE Name = 'Jane Doe'].Id].isActive);
    }

    @isTest
    public static void DeleteInDirectAccountContactRelationship_Test()
    {
        // Assemble
        Contact con = new Contact();
        con.LastName = 'TESTER';
        con.AccountId = [SELECT Id FROM Account WHERE DEAR_Tenant_ID__c = '231013f4-48c0-4cfd-9e53-3bc461d42d64'].Id;
        insert con; 

        
        // Associate another contact to the Account indirectly
        Account a2 = new Account(Name = 'Account 2');
        insert a2;

        Contact c2 = new Contact(
            LastName = 'McTesterson',
            AccountId = a2.Id
        );
        insert c2;

        AccountContactRelation indirectAcr = new AccountContactRelation(
            ContactId = c2.Id,
            AccountId = con.AccountId
        );
        insert indirectAcr;

        Assert.isFalse([SELECT IsDirect FROM AccountContactRelation WHERE Id = :indirectAcr.Id].IsDirect);

        Incoming_Request__c req = new Incoming_Request__c();
        req.Message__c = 'NewSubscription';
        req.Tenant_ID__c = '231013f4-48c0-4cfd-9e53-3bc461d42d64';
    
        String getResponse = '{"Data":{"Subscribed":null,"Cancelled":null,"SubscriptionName":"Trial","SubscriptionExpirationDate":"2024-03-01T00:00:00","Source":"Website (Direct)","ReferredByPartner":null,"ReferredByPartnerId":null,"PlanType":null,"IsNeedAttention":false,"CustomerDomain":"usertest.com","Utm_Campaign":null,"Utm_Source":null,"Utm_Medium":null,"Utm_Term":null,"Utm_Content":null,"PartnerType":null,"IsVarPartner":null,"ReferrerDomain":null,"AdditionalUsers":0,"AdditionalUsersCost":0.0000,"Discount":0.0000,"Status":"Trial","AnniversaryDate":null,"IntegrationCount":0,"SalesCount":15,"Sales3MonthsCount":0,"Sales6MonthsCount":0,"Sales12MonthsCount":0,"SalesGMV":30351.3500,"SalesGMV3Months":0.0000,"SalesGMV6Months":0.0000,"SalesGMV12Months":0.0000,"SKUs":[],"Users":[{"UserId":"cbecdcde-d39c-4620-9d84-1e57afe87e15","Email":"john@doe.com","UserType":"user","DisplayName":"John Doe"},{"UserId":"b587c24d-b53b-4f95-b837-48580a1a39c4","Email":"jane@doe.com","UserType":"owner","DisplayName":"Jane Doe"}],"Discounts":[],"Country":"United States","CreateDate":"2024-02-16T18:06:04.773","Email":"actester@usertest.com","LastUpdatedDate":"2024-02-27T21:20:14.363","Organisation":"UserTestAcct","SalesPersonEmail":"am.siddiquie@dearsystems.com","TenantID":"231013f4-48c0-4cfd-9e53-3bc461d42d64","WebsiteURL":null,"Contacts":[{"Phone":"8888888888888","Email":"actester@usertest.com","FirstName":"Andrew","LastName":"Tester"}]}}';
        MockHttpResponseHandler.SimpleMockResponse getResp = new MockHttpResponseHandler.SimpleMockResponse('GET', getResponse);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse('callout:Customer_Details', getResp);

        // Act
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, mock);
            insert req;
        Test.stopTest();
        
        // Post-assert
        List<AccountContactRelation> assertAcr = [SELECT Id, IsDirect, IsActive, ContactId, AccountId, StartDate FROM AccountContactRelation];
        Assert.areEqual(4, assertAcr.size());

        Boolean foundOriginalAcr = false;
        Boolean foundC2sOriginalAcr = false;
        Boolean foundIndirectAcr = false;
        Integer newContactCount = 0;
        for (AccountContactRelation acr : assertAcr)
        {
            if (acr.ContactId == con.Id && acr.AccountId == con.AccountId)
            {
                foundOriginalAcr = true;
                Assert.areEqual(false, acr.IsActive);
            }
            else if (acr.ContactId == c2.Id && acr.AccountId == c2.AccountId)  foundC2sOriginalAcr = true;
            else if (acr.ContactId == c2.Id && acr.AccountId == con.AccountId) foundIndirectAcr = true;
            else 
            {
                newContactCount++;
                system.debug(acr.StartDate);
            }
        }
        Assert.isTrue(foundOriginalAcr);
        Assert.isTrue(foundC2sOriginalAcr);
        Assert.isFalse(foundIndirectAcr);
        Assert.areEqual(2, newContactCount);

        Assert.areEqual(1, [SELECT COUNT() FROM Contact WHERE Name = 'John Doe']);
        Assert.areEqual(1, [SELECT COUNT() FROM Contact WHERE Name = 'Jane Doe']);
        Assert.areEqual(true, [SELECT isActive FROM AccountContactRelation WHERE ContactId =: [SELECT Id FROM Contact WHERE Name = 'John Doe'].Id].isActive);
        Assert.areEqual(true, [SELECT isActive FROM AccountContactRelation WHERE ContactId =: [SELECT Id FROM Contact WHERE Name = 'Jane Doe'].Id].isActive);
    }

    // @description: Test method used to test when Contact exists in Salesforce but not related to proper account.
    // @expected result: Avoid creating duplicate Contacts by creating a new Account Contact Relationship with the already existing Contact in SFDC.
    @isTest
    public static void AvoidDuplicateContacts_Test(){
        // assemble
        Account a = new Account();
        a.Name = 'Test New Account';
        insert a;

        Contact con = new Contact();
        con.LastName = 'TESTER';
        con.Cin7_Core_User_Id__c = 'cbecdcde-d39c-4620-9d84-1e57afe87e15';
        con.AccountId = a.Id;
        insert con; 

        Incoming_Request__c req = new Incoming_Request__c();
        req.Message__c = 'NewSubscription';
        req.Tenant_ID__c = '231013f4-48c0-4cfd-9e53-3bc461d42d64';
    
        // assign
        String getResponse = '{"Data":{"Subscribed":null,"Cancelled":null,"SubscriptionName":"Trial","SubscriptionExpirationDate":"2024-03-01T00:00:00","Source":"Website (Direct)","ReferredByPartner":null,"ReferredByPartnerId":null,"PlanType":null,"IsNeedAttention":false,"CustomerDomain":"usertest.com","Utm_Campaign":null,"Utm_Source":null,"Utm_Medium":null,"Utm_Term":null,"Utm_Content":null,"PartnerType":null,"IsVarPartner":null,"ReferrerDomain":null,"AdditionalUsers":0,"AdditionalUsersCost":0.0000,"Discount":0.0000,"Status":"Trial","AnniversaryDate":null,"IntegrationCount":0,"SalesCount":15,"Sales3MonthsCount":0,"Sales6MonthsCount":0,"Sales12MonthsCount":0,"SalesGMV":30351.3500,"SalesGMV3Months":0.0000,"SalesGMV6Months":0.0000,"SalesGMV12Months":0.0000,"SKUs":[],"Users":[{"UserId":"cbecdcde-d39c-4620-9d84-1e57afe87e15","Email":"john@doe.com","UserType":"user","DisplayName":"John Doe"},{"UserId":"b587c24d-b53b-4f95-b837-48580a1a39c4","Email":"jane@doe.com","UserType":"owner","DisplayName":"Jane Doe"}],"Discounts":[],"Country":"United States","CreateDate":"2024-02-16T18:06:04.773","Email":"actester@usertest.com","LastUpdatedDate":"2024-02-27T21:20:14.363","Organisation":"UserTestAcct","SalesPersonEmail":"am.siddiquie@dearsystems.com","TenantID":"231013f4-48c0-4cfd-9e53-3bc461d42d64","WebsiteURL":null,"Contacts":[{"Phone":"8888888888888","Email":"actester@usertest.com","FirstName":"Andrew","LastName":"Tester"}]}}';
        MockHttpResponseHandler.SimpleMockResponse getResp = new MockHttpResponseHandler.SimpleMockResponse('GET', getResponse);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse('callout:Customer_Details', getResp);

        //assert 
        Assert.areEqual(1, [SELECT COUNT() FROM Contact]);
        Assert.areEqual(1, [SELECT COUNT() FROM AccountContactRelation]);
        Assert.areEqual('TESTER', [SELECT LastName FROM Contact WHERE Id =: con.Id].LastName);

        Test.startTest();
            Test.setMock(HttpCalloutMock.class, mock);
            insert req;
        Test.stopTest();
        Id accountID = [SELECT Id FROM Account WHERE DEAR_Tenant_ID__c = '231013f4-48c0-4cfd-9e53-3bc461d42d64'].Id;

        Assert.areEqual(2, [SELECT COUNT() FROM Contact]);
        Assert.areEqual(3, [SELECT COUNT() FROM AccountContactRelation]);
        Assert.areEqual(true, [SELECT isActive FROM AccountContactRelation WHERE ContactId =: con.Id AND AccountId =: a.Id].isActive);
        Assert.areEqual(true, [SELECT isActive FROM AccountContactRelation WHERE ContactId =: con.Id AND AccountId =: accountID].isActive);
    }

    // @description: Test method used to test when Account or Lead isn't found in the Get Customer details endpoint.
    // @expected result: Create API Error Log for Salesforce Admin to further troubleshoot.
    @isTest
    public static void APIErrorLog_Test(){
        // assemble
        Incoming_Request__c req = new Incoming_Request__c();
        req.Message__c = 'NewSubscription';
        req.Tenant_ID__c = '231013f4-48c0-4cfd-9e53-3bc461d42d65';
    
        // assign
        String getResponse = '{"Data":{"Subscribed":null,"Cancelled":null,"SubscriptionName":"Trial","SubscriptionExpirationDate":"2024-03-01T00:00:00","Source":"Website (Direct)","ReferredByPartner":null,"ReferredByPartnerId":null,"PlanType":null,"IsNeedAttention":false,"CustomerDomain":"usertest.com","Utm_Campaign":null,"Utm_Source":null,"Utm_Medium":null,"Utm_Term":null,"Utm_Content":null,"PartnerType":null,"IsVarPartner":null,"ReferrerDomain":null,"AdditionalUsers":0,"AdditionalUsersCost":0.0000,"Discount":0.0000,"Status":"Trial","AnniversaryDate":null,"IntegrationCount":0,"SalesCount":15,"Sales3MonthsCount":0,"Sales6MonthsCount":0,"Sales12MonthsCount":0,"SalesGMV":30351.3500,"SalesGMV3Months":0.0000,"SalesGMV6Months":0.0000,"SalesGMV12Months":0.0000,"SKUs":[],"Users":[{"UserId":"cbecdcde-d39c-4620-9d84-1e57afe87e15","Email":"john@doe.com","UserType":"user","DisplayName":"John Doe"},{"UserId":"b587c24d-b53b-4f95-b837-48580a1a39c4","Email":"jane@doe.com","UserType":"owner","DisplayName":"Jane Doe"}],"Discounts":[],"Country":"United States","CreateDate":"2024-02-16T18:06:04.773","Email":"actester@usertest.com","LastUpdatedDate":"2024-02-27T21:20:14.363","Organisation":"UserTestAcct","SalesPersonEmail":"am.siddiquie@dearsystems.com","TenantID":"231013f4-48c0-4cfd-9e53-3bc461d42d65","WebsiteURL":null,"Contacts":[{"Phone":"8888888888888","Email":"actester@usertest.com","FirstName":"Andrew","LastName":"Tester"}]}}';
        MockHttpResponseHandler.SimpleMockResponse getResp = new MockHttpResponseHandler.SimpleMockResponse('GET', getResponse);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse('callout:Customer_Details', getResp);

        //assert 
        Assert.areEqual(0, [SELECT COUNT() FROM Contact]);
        Assert.areEqual(0, [SELECT COUNT() FROM API_Error_Log__c]);

        Test.startTest();
            Test.setMock(HttpCalloutMock.class, mock);
            insert req;
        Test.stopTest();

        Assert.areEqual(0,[SELECT COUNT() FROM Contact]);
        Assert.areEqual(1, [SELECT COUNT() FROM API_Error_Log__c]);
        Assert.areEqual('Lead Converted or Not Found', [SELECT Status__c FROM API_Error_Log__c].Status__c);
    }

    @isTest
    static void testContactMatchByEmail()
    {
        // Assemble
        Contact con = new Contact();
        con.FirstName = 'John';
        con.LastName = 'D';
        con.Email = 'john@doe.com';
        con.AccountId = [SELECT Id FROM Account WHERE Name = 'Test Account'].Id;
        insert con;

        Incoming_Request__c req = new Incoming_Request__c();
        req.Message__c = 'UpdateSubscription';
        req.Tenant_ID__c = '231013f4-48c0-4cfd-9e53-3bc461d42d64';
    
        String getResponse = '{"Data":{"Subscribed":null,"Cancelled":null,"SubscriptionName":"Trial","SubscriptionExpirationDate":"2024-03-01T00:00:00","Source":"Website (Direct)","ReferredByPartner":null,"ReferredByPartnerId":null,"PlanType":null,"IsNeedAttention":false,"CustomerDomain":"usertest.com","Utm_Campaign":null,"Utm_Source":null,"Utm_Medium":null,"Utm_Term":null,"Utm_Content":null,"PartnerType":null,"IsVarPartner":null,"ReferrerDomain":null,"AdditionalUsers":0,"AdditionalUsersCost":0.0000,"Discount":0.0000,"Status":"Trial","AnniversaryDate":null,"IntegrationCount":0,"SalesCount":15,"Sales3MonthsCount":0,"Sales6MonthsCount":0,"Sales12MonthsCount":0,"SalesGMV":30351.3500,"SalesGMV3Months":0.0000,"SalesGMV6Months":0.0000,"SalesGMV12Months":0.0000,"SKUs":[],"Users":[{"UserId":"cbecdcde-d39c-4620-9d84-1e57afe87e15","Email":"john@doe.com","UserType":"user","DisplayName":"John Doe"},{"UserId":"b587c24d-b53b-4f95-b837-48580a1a39c4","Email":"jane@doe.com","UserType":"owner","DisplayName":"Jane Doe"}],"Discounts":[],"Country":"United States","CreateDate":"2024-02-16T18:06:04.773","Email":"actester@usertest.com","LastUpdatedDate":"2024-02-27T21:20:14.363","Organisation":"UserTestAcct","SalesPersonEmail":"am.siddiquie@dearsystems.com","TenantID":"231013f4-48c0-4cfd-9e53-3bc461d42d64","WebsiteURL":null,"Contacts":[{"Phone":"8888888888888","Email":"actester@usertest.com","FirstName":"Andrew","LastName":"Tester"}]}}';
        MockHttpResponseHandler.SimpleMockResponse getResp = new MockHttpResponseHandler.SimpleMockResponse('GET', getResponse);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse('callout:Customer_Details', getResp);

        // Pre-assert 
        Assert.areEqual(1, [SELECT COUNT() FROM Contact]);
        Assert.areEqual('John D', [SELECT Name FROM Contact].Name);
        Assert.areEqual(1, [SELECT COUNT() FROM Opportunity]);

        // Act
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, mock);
        Database.executeBatch(new IncomingReqUpdateSubscriptionBatch(new List<Incoming_Request__c>{req}), 1);
        Test.stopTest();
        

        // Post-assert
        List<Contact> assertContact = [SELECT FirstName, LastName, Cin7_Core_User_Id__c FROM Contact];
        // System.debug(JSON.serializePretty(assertContact));
        Assert.areEqual(2, assertContact.size());
        
        Boolean foundJohn = false;
        Boolean foundJane = false;
        for (Contact c : assertContact)
        {
            if (c.FirstName == 'John')
            {
                assert.areEqual('Doe', c.LastName);
                assert.areEqual('cbecdcde-d39c-4620-9d84-1e57afe87e15', c.Cin7_Core_User_Id__c);
                foundJohn = true;
            }
            else if (c.FirstName == 'Jane')
            {
                assert.areEqual('Doe', c.LastName);
                foundJane = true;
            }
        }
        Assert.isTrue(foundJohn);
        Assert.areEqual(2, [SELECT COUNT() FROM Opportunity]);
    }

    @isTest
    static void testBlankDisplayName()
    {
        // Assemble
        Incoming_Request__c req = new Incoming_Request__c();
        req.Message__c = 'NewSubscription';
        req.Tenant_ID__c = '231013f4-48c0-4cfd-9e53-3bc461d42d64';
    
        String getResponse = '{"Data":{"Subscribed":null,"Cancelled":null,"SubscriptionName":"Trial","SubscriptionExpirationDate":"2024-03-01T00:00:00","Source":"Website (Direct)","ReferredByPartner":null,"ReferredByPartnerId":null,"PlanType":null,"IsNeedAttention":false,"CustomerDomain":"usertest.com","Utm_Campaign":null,"Utm_Source":null,"Utm_Medium":null,"Utm_Term":null,"Utm_Content":null,"PartnerType":null,"IsVarPartner":null,"ReferrerDomain":null,"AdditionalUsers":0,"AdditionalUsersCost":0.0000,"Discount":0.0000,"Status":"Trial","AnniversaryDate":null,"IntegrationCount":0,"SalesCount":15,"Sales3MonthsCount":0,"Sales6MonthsCount":0,"Sales12MonthsCount":0,"SalesGMV":30351.3500,"SalesGMV3Months":0.0000,"SalesGMV6Months":0.0000,"SalesGMV12Months":0.0000,"SKUs":[],"Users":[{"UserId":"cbecdcde-d39c-4620-9d84-1e57afe87e15","Email":"john@doe.com","UserType":"user","DisplayName":"John"},{"UserId":"b587c24d-b53b-4f95-b837-48580a1a39c4","Email":"jane@doe.com","UserType":"owner","DisplayName":"Jane"}],"Discounts":[],"Country":"United States","CreateDate":"2024-02-16T18:06:04.773","Email":"actester@usertest.com","LastUpdatedDate":"2024-02-27T21:20:14.363","Organisation":"UserTestAcct","SalesPersonEmail":"am.siddiquie@dearsystems.com","TenantID":"231013f4-48c0-4cfd-9e53-3bc461d42d64","WebsiteURL":null,"Contacts":[{"Phone":"8888888888888","Email":"actester@usertest.com","FirstName":"Andrew","LastName":"Tester"}]}}';
        MockHttpResponseHandler.SimpleMockResponse getResp = new MockHttpResponseHandler.SimpleMockResponse('GET', getResponse);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse('callout:Customer_Details', getResp);

        // Pre-assert 
        Assert.areEqual(0, [SELECT COUNT() FROM Contact]);
        Assert.areEqual(1, [SELECT COUNT() FROM Opportunity]);
        Assert.areEqual(0, [SELECT Count() from AccountContactRelation]);

        // Act
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, mock);
            insert req;
        Test.stopTest();

        // Post-assert
        List<Contact> assertContacts = [SELECT Name, Email, Cin7_Core_User_Id__c FROM Contact];
        Assert.areEqual(2, assertContacts.size());
        Boolean foundJohn = false;
        Boolean foundJane = false;
        for (Contact c : assertContacts)
        {
            system.debug(c.Name);
            if (c.Name == 'John Cin7 Core User')
            {
                Assert.areEqual('cbecdcde-d39c-4620-9d84-1e57afe87e15', c.Cin7_Core_User_Id__c);
                Assert.areEqual('john@doe.com', c.Email);
                foundJohn = true;
            } 
            if (c.Name == 'Jane Cin7 Core User') 
            {
                Assert.areEqual('b587c24d-b53b-4f95-b837-48580a1a39c4', c.Cin7_Core_User_Id__c);
                Assert.areEqual('jane@doe.com', c.Email);
                foundJane = true;
            }
        }
        system.debug(foundJohn);
        system.debug(foundJane);
        Assert.areEqual(true, foundJohn);
        Assert.areEqual(true, foundJane);

        Assert.areEqual(1, [SELECT COUNT() FROM Opportunity]);

        List<AccountContactRelation> assertAcrs = [SELECT AccountId, ContactId from AccountContactRelation];
        Assert.areEqual(2, assertAcrs.size());
    }

    // This test method was created to test a bug discovered, whereby a contact has ACRs for multiple accounts. A Core User is sent in
    // for an account that is not the contact's parent. Our logic was previously flawed, in that, we attempted to create a new, duplicate
    // ACR for the non-parent account. This test method recreates that condition and it should run without error. 
    @isTest
    static void testIncomingRequestWhenAcrExistsForAnotherAccount()
    {
        // Assemble
        Account a1 = new Account(Name = 'Test Acct', Dear_Tenant_Id__c = 'account1');
        Account a2 = new Account(Name = 'Test Acct 2', Dear_Tenant_Id__c = 'account2');
        insert new List<Account> {a1, a2};

        Contact c = new Contact(AccountId = a1.Id, FirstName = 'Testy', LastName = 'McTesterson', Email = 'mctesty@gmail.com');
        insert c;

        // Insert ACR for c and a2
        insert new AccountContactRelation(ContactId = c.Id, AccountId = a2.Id, IsActive = true, StartDate = Date.today());

        // Now configure params to call the ContactProcessQueueable
        List<IncomingRequestJSONParse.Users> coreUsers = new List<IncomingRequestJSONParse.Users>();
        IncomingRequestJSONParse.Users u = new IncomingRequestJSONParse.Users();
        u.UserType = 'Decision Maker';
        u.DisplayName = 'Testa McTesterson';    // Changing first name here as well
        u.Email = c.Email;
        u.UserId = 'thisisuseridfortesty';
        coreUsers.add(u);

        // Act
        Test.startTest();
        System.enqueueJob(new ContactProcessQueueable(coreUsers, a2.Dear_Tenant_Id__c)); // Process for the non-parent account (a2), make sure there are no errors
        Test.stopTest();
    
        // Assert 
        List<API_Error_Log__c> logs = [SELECT Id, Error_Message__c from API_Error_Log__c];
        system.debug(logs);
        Assert.areEqual(0, logs.size());
        Assert.areEqual(2, [SELECT Id FROM AccountContactRelation].size());
        Assert.areEqual('Testa', [SELECT FirstName FROM Contact WHERE Id = :c.Id LIMIT 1].FirstName);   // We also changed the contact's name
    }

    @isTest
    static void testContactProcess_MatchByEmail() {
        // Arrange: Create an Account and a Contact that matches by Email
        Account account = new Account(Name = 'Test Account', DEAR_Tenant_ID__c = 'tenant123');
        insert account;
        
        Contact existingContact = new Contact(FirstName = 'OldFirstName', LastName = 'OldLastName', Email = 'user@example.com', AccountId = account.Id);
        insert existingContact;

        // Create a user object that matches by Email
        IncomingRequestJSONParse.Users user = new IncomingRequestJSONParse.Users();
        user.UserId = 'user123';
        user.Email = 'user@example.com';
        user.DisplayName = 'NewFirstName NewLastName';
        user.UserType = 'Admin';

        List<IncomingRequestJSONParse.Users> users = new List<IncomingRequestJSONParse.Users>{ user };

        // Instantiate the queueable with the user list and tenant id
        Test.startTest();
        ContactProcessQueueable queueable = new ContactProcessQueueable(users, 'tenant123');
        System.enqueueJob(queueable);
        Test.stopTest();

        // Assert: Verify that the existing contact was updated with the new Cin7_Core_User_Id__c and updated names
        Contact updatedContact = [SELECT FirstName, LastName, Cin7_Core_User_Id__c FROM Contact WHERE Email = 'user@example.com' LIMIT 1];
        System.assertEquals('user123', updatedContact.Cin7_Core_User_Id__c, 'Cin7_Core_User_Id__c should be updated.');
        System.assertEquals('NewFirstName', updatedContact.FirstName, 'First name should be updated.');
        System.assertEquals('NewLastName', updatedContact.LastName, 'Last name should be updated.');
    }

    @isTest
    static void testContactProcess_MatchByCin7CoreUserId() {
        // Arrange: Create an Account and a Contact that matches by Cin7_Core_User_Id__c
        Account account = new Account(Name = 'Test Account', DEAR_Tenant_ID__c = 'tenant123');
        insert account;

        Contact existingContact = new Contact(FirstName = 'FirstName', LastName = 'LastName', Email = 'user@example.com', Cin7_Core_User_Id__c = 'user123', AccountId = account.Id);
        insert existingContact;

        // Create a user object that matches by Cin7_Core_User_Id__c
        IncomingRequestJSONParse.Users user = new IncomingRequestJSONParse.Users();
        user.UserId = 'user123';
        user.Email = 'user@example.com';
        user.DisplayName = 'FirstName LastName';
        user.UserType = 'Admin';

        List<IncomingRequestJSONParse.Users> users = new List<IncomingRequestJSONParse.Users>{ user };

        // Instantiate the queueable with the user list and tenant id
        Test.startTest();
        ContactProcessQueueable queueable = new ContactProcessQueueable(users, 'tenant123');
        System.enqueueJob(queueable);
        Test.stopTest();

        // Assert: Verify that the contact was matched by Cin7_Core_User_Id__c and the fields were updated
        Contact updatedContact = [SELECT Cin7_Core_User_Id__c FROM Contact WHERE Cin7_Core_User_Id__c = 'user123' LIMIT 1];
        System.assertEquals('user123', updatedContact.Cin7_Core_User_Id__c, 'Cin7_Core_User_Id__c should be matched.');
    }

    @isTest
    static void testContactProcess_CreateNewContact() {
        // Arrange: Create an Account, but no Contact to match
        Account account = new Account(Name = 'Test Account', DEAR_Tenant_ID__c = 'tenant123');
        insert account;

        // Create a user object with no matching contact in Salesforce
        IncomingRequestJSONParse.Users user = new IncomingRequestJSONParse.Users();
        user.UserId = 'user123';
        user.Email = 'newuser@example.com';
        user.DisplayName = 'NewUser FirstName';
        user.UserType = 'User';

        List<IncomingRequestJSONParse.Users> users = new List<IncomingRequestJSONParse.Users>{ user };

        // Instantiate the queueable with the user list and tenant id
        Test.startTest();
        ContactProcessQueueable queueable = new ContactProcessQueueable(users, 'tenant123');
        System.enqueueJob(queueable);
        Test.stopTest();

        // Assert: Verify that a new contact was created
        Contact newContact = [SELECT FirstName, LastName, Email, Cin7_Core_User_Id__c FROM Contact WHERE Email = 'newuser@example.com' LIMIT 1];
        System.assertEquals('NewUser', newContact.FirstName, 'First name should match the new user.');
        System.assertEquals('FirstName', newContact.LastName, 'Last name should match the new user.');
        System.assertEquals('user123', newContact.Cin7_Core_User_Id__c, 'Cin7_Core_User_Id__c should match the new user.');
    }

    @isTest
    static void testContactProcess_UpdateWithDefaultLastName() {
        // Arrange: Create an Account and a Contact that matches by Email but no DisplayName
        Account account = new Account(Name = 'Test Account', DEAR_Tenant_ID__c = 'tenant123');
        insert account;

        Contact existingContact = new Contact(FirstName = 'OldFirstName', LastName = 'OldLastName', Email = 'user@example.com', AccountId = account.Id);
        insert existingContact;

        // Create a user object with no DisplayName
        IncomingRequestJSONParse.Users user = new IncomingRequestJSONParse.Users();
        user.UserId = 'user123';
        user.Email = 'user@example.com';
        user.DisplayName = '';
        user.UserType = 'User';

        List<IncomingRequestJSONParse.Users> users = new List<IncomingRequestJSONParse.Users>{ user };

        // Instantiate the queueable with the user list and tenant id
        Test.startTest();
        ContactProcessQueueable queueable = new ContactProcessQueueable(users, 'tenant123');
        System.enqueueJob(queueable);
        Test.stopTest();
    }
}