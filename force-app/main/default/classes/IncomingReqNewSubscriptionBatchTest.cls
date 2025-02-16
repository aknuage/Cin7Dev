@IsTest
public with sharing class IncomingReqNewSubscriptionBatchTest {
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

    // Test brand new subscription, with all desired outcomes achieved
    @isTest
    static void testComprehensiveNewSubscription() {
        // Prepare pricebook and product setup
        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(Id = pricebookId, IsActive = true);
        update standardPricebook;

        Product2 prod1 = new Product2(Name = 'Product 1', ProductCode = 'Prod1', IsActive = true);
        Product2 prod2 = new Product2(Name = 'Product 2', ProductCode = 'Prod2', IsActive = true);
        insert new List<Product2>{prod1, prod2};

        PricebookEntry pbe1 = new PricebookEntry(Pricebook2Id = standardPricebook.Id, Product2Id = prod1.Id, UnitPrice = 100.00, IsActive = true);
        PricebookEntry pbe2 = new PricebookEntry(Pricebook2Id = standardPricebook.Id, Product2Id = prod2.Id, UnitPrice = 200.00, IsActive = true);
        insert new List<PricebookEntry>{pbe1, pbe2};

        String tenantId = 'F23932F1-54EB-4BFE-B929-B25FB029056D';

        // Account and related opportunity
        Account acc = new Account(
            Name = 'Nuage Test',
            DEAR_Tenant_ID__c = tenantId,
            Dear_CRM_Status__c = 'Client',
            Subscription_Expiration_Date__c = Date.today().addDays(365),
            BillingCity = 'Sacramento',
            BillingCountry = 'United States',
            BillingCountryCode = 'US',
            AccountSource = 'Direct Traffic',
            BillingStreet = '123 Any Street',
            BillingPostalCode = '95811',
            Cin7_Username__c = 'Cin7-User-1727480561844'
        );
        insert acc;

        Opportunity currentOpp = new Opportunity(
            AccountId = acc.Id,
            Amount = 50000,
            Name = 'Nuage Test-',
            DEAR_Tenant_ID__c = tenantId,
            StageName = 'Closed Won',
            CloseDate = System.today().addDays(30),
            Pricebook2Id = standardPricebook.Id,
            Is_Active__c = true
        );
        insert currentOpp;

        OpportunityLineItem oli1 = new OpportunityLineItem(
            OpportunityId = currentOpp.Id,
            PricebookEntryId = pbe1.Id,
            Quantity = 1,
            UnitPrice = pbe1.UnitPrice
        );
        insert oli1;

        Incoming_Request__c req = new Incoming_Request__c();
        req.Source__c = 'Cin7 Core';
        req.Message__c = 'NewSubscription';
        req.Tenant_ID__c = tenantId;

        // Mock callout setup
        String getResponse = '{"Errors":null,"Data":{"WebsiteURL":null,"Utm_Term":null,"Utm_Source":null,"Utm_Medium":null,"Utm_Content":null,"Utm_Campaign":null,"Users":[],"TenantID":"f23932f1-54eb-4bfe-b929-b25fb029056d","SubscriptionName":"Pro 2024.01","SubscriptionExpirationDate":"2026-04-22T00:00:00","Subscribed":"2024-04-10T19:13:34.807Z","Status":"Client","Source":"Website (Direct)","AdditionalUsers": 10,"AdditionalUsersCost": 100.0000,"SKUs": [{"Name": "Prod1","Quantity": 2,"Total": 1200.0000,"Frequency": "Yearly"}, {"Name": "Prod2","Quantity": 2,"Total": 1200.0000,"Frequency": "onetime"}],"SalesPersonEmail":"indeewari.k@dearsystems.com","SalesGMV6Months":437.0000,"SalesGMV3Months":437.0000,"SalesGMV12Months":437.0000,"SalesGMV":437.0000,"SalesCount":1,"Sales6MonthsCount":1,"Sales3MonthsCount":1,"Sales12MonthsCount":1,"ReferrerDomain":null,"ReferredByPartnerId":null,"ReferredByPartner":null,"PlanType":null,"PartnerType":null,"Organisation":"Andrew Trial","LastUpdatedDate":"2024-12-07T21:20:21.370Z","IsVarPartner":"false","IsOnboardingOptional":null,"IsNeedAttention":false,"IntegrationCount":0,"Email":"andrew.cooper@cin7.com","Discounts":[],"Discount":50.0000,"CustomerDomain":"cin7.com","CreateDate":"2023-07-14T15:55:51.453Z","Country":"United States","Contacts":[{"Phone":"90909099099","LastName":"Cooper","FirstName":"Andrew","Email":"andrew.cooper@cin7.com"}],"Cancelled":null,"AnniversaryDate":"2025-04-09T00:00:00"}}';
        MockHttpResponseHandler.SimpleMockResponse getResp = new MockHttpResponseHandler.SimpleMockResponse('GET', getResponse);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse('callout:Customer_Details', getResp);

        // Execute test
        Test.startTest();

        Test.setMock(HttpCalloutMock.class, mock);
        Database.executeBatch(new IncomingReqNewSubscriptionBatch(new List<Incoming_Request__c>{req}));

        Test.stopTest();

        // Assertions
        List<Opportunity> opportunities = [SELECT StageName, CurrencyIsoCode, Is_Active__c, Name, AccountId, CloseDate, DEAR_Tenant_ID__c, 
        Amount, Amount_Onboarding_Fee__c, OwnerId, (select Id, PriceBookEntry.ProductCode, Quantity, UnitPrice from OpportunityLineItems) 
        FROM Opportunity WHERE Is_Active__c = true AND DEAR_Tenant_ID__c =: tenantId 
            AND Amount != null 
            AND StageName = 'Closed Won'
        ];
        //System.debug('opportunities: ' + JSON.serializePretty(opportunities));

        System.assert(opportunities.size() == 1, 'Opportunities should be updated based on the incoming request.');
        for (Opportunity opp : opportunities) {
            if (opp.Is_Active__c) {
                // Assertions for the active opportunity
                System.assertEquals('Closed Won', opp.StageName, 'Active opportunity should be Closed Won.');
                System.assert(opp.Amount > 0, 'Active opportunity should have a non-zero amount.');

                // Line item assertions
                System.assertEquals(2, opp.OpportunityLineItems.size(), 'Active opportunity should have two line items.');
                for (OpportunityLineItem oli : opp.OpportunityLineItems) {
                    if (oli.PricebookEntry.ProductCode == 'Users') {
                        System.assertEquals(10, oli.Quantity, 'Quantity for Users should be 10.');
                        System.assertEquals(10.00, oli.UnitPrice, 'Unit price for Users should be 10.');
                    } else if (oli.PricebookEntry.ProductCode == 'Standard Yearly 2021') {
                        System.assertEquals(2, oli.Quantity, 'Quantity for Standard Yearly 2021 should be 2.');
                        System.assertEquals(50.00, oli.UnitPrice, 'Unit price for Standard Yearly 2021 should be recalculated properly.');
                    }
                }
            }
        }

        // Account Name should not change even if Organization is passed as a param in the response
        System.assertEquals('Nuage Test', [SELECT Name FROM Account WHERE DEAR_Tenant_ID__c = :tenantId LIMIT 1].Name, 'Account name should remain unchanged.');
    }

    @isTest
    public static void testResponseWithErrors() {
        // Prepare pricebook and product setup
        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(Id = pricebookId, IsActive = true);
        update standardPricebook;
    
        Product2 prod1 = new Product2(Name = 'Product 1', ProductCode = 'Prod1', IsActive = true);
        Product2 prod2 = new Product2(Name = 'Product 2', ProductCode = 'Prod2', IsActive = true);
        insert new List<Product2>{prod1, prod2};
    
        PricebookEntry pbe1 = new PricebookEntry(Pricebook2Id = standardPricebook.Id, Product2Id = prod1.Id, UnitPrice = 100.00, IsActive = true);
        PricebookEntry pbe2 = new PricebookEntry(Pricebook2Id = standardPricebook.Id, Product2Id = prod2.Id, UnitPrice = 200.00, IsActive = true);
        insert new List<PricebookEntry>{pbe1, pbe2};
        
        String tenantId = 'F23932F1-54EB-4BFE-B929-B25FB029056D';

        // Account and related opportunity
        Account acc = new Account(
            Name = 'Nuage Test',
            DEAR_Tenant_ID__c = tenantId,
            Dear_CRM_Status__c = 'Client',
            Subscription_Expiration_Date__c = Date.today().addDays(365),
            BillingCity = 'Sacramento',
            BillingCountry = 'United States',
            BillingCountryCode = 'US',
            AccountSource = 'Direct Traffic',
            BillingStreet = '123 Any Street',
            BillingPostalCode = '95811',
            Cin7_Username__c = 'Cin7-User-1727480561844'
        );
        insert acc;
    
        Opportunity currentOpp = new Opportunity(
            AccountId = acc.Id,
            Amount = 50000,
            Name = 'Nuage Test-',
            DEAR_Tenant_ID__c = tenantId,
            StageName = 'Prospecting',
            CloseDate = System.today().addDays(30),
            Pricebook2Id = standardPricebook.Id,
            Is_Active__c = true
        );
        insert currentOpp;

        Incoming_Request__c req = new Incoming_Request__c();
        req.Message__c = 'NewSubscription';
        req.Tenant_ID__c = tenantId;
    
    

        // Mock callout setup
        String getResponse = '{"Errors":["We have", "an error"],"Data":{"WebsiteURL":null,"Utm_Term":null,"Utm_Source":null,"Utm_Medium":null,"Utm_Content":null,"Utm_Campaign":null,"Users":[{"UserType":"owner","UserId":"cbecdcde-d39c-4620-9d84-1e57afe87e15","Email":"andrew.cooper@cin7.com","DisplayName":"Andrew Cooper"}],"TenantID":"f23932f1-54eb-4bfe-b929-b25fb029056d","SubscriptionName":"Pro 2024.01","SubscriptionExpirationDate":"2026-04-22T00:00:00","Subscribed":"2024-04-10T19:13:34.807Z","Status":"Client","Source":"Website (Direct)","AdditionalUsers": 10,"AdditionalUsersCost": 100.0000,"SKUs": [{"Name": "Standard Yearly 2021","Quantity": 2,"Total": 1200.0000,"Frequency": "monthly"}],"SalesPersonEmail":"indeewari.k@dearsystems.com","SalesGMV6Months":437.0000,"SalesGMV3Months":437.0000,"SalesGMV12Months":437.0000,"SalesGMV":437.0000,"SalesCount":1,"Sales6MonthsCount":1,"Sales3MonthsCount":1,"Sales12MonthsCount":1,"ReferrerDomain":null,"ReferredByPartnerId":null,"ReferredByPartner":null,"PlanType":null,"PartnerType":null,"Organisation":"Andrew Trial","LastUpdatedDate":"2024-12-07T21:20:21.370Z","IsVarPartner":"false","IsOnboardingOptional":null,"IsNeedAttention":false,"IntegrationCount":0,"Email":"andrew.cooper@cin7.com","Discounts":[],"Discount":50.0000,"CustomerDomain":"cin7.com","CreateDate":"2023-07-14T15:55:51.453Z","Country":"United States","Contacts":[{"Phone":"90909099099","LastName":"Cooper","FirstName":"Andrew","Email":"andrew.cooper@cin7.com"}],"Cancelled":null,"AnniversaryDate":"2025-04-09T00:00:00"}}';
        MockHttpResponseHandler.SimpleMockResponse getResp = new MockHttpResponseHandler.SimpleMockResponse('GET', getResponse);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse('callout:Customer_Details', getResp);

        // Execute test
        Test.startTest();

        Test.setMock(HttpCalloutMock.class, mock);
        Database.executeBatch(new IncomingReqNewSubscriptionBatch(new List<Incoming_Request__c>{req}));

        Test.stopTest();
        
        API_Error_Log__c err = [SELECT Error_Message__c FROM API_Error_Log__c LIMIT 1];
        // Assertions
        System.assertEquals('We have,an error', err.Error_Message__c);       
        
    }

    @isTest
    public static void deleteUnknownSKUsTest()
    {
        String tenantId = '111013f4-48c0-4cdd-9e53-3bc461d42d64';
        // Assemble
        Incoming_Request__c req = new Incoming_Request__c();
        req.Message__c = 'NewSubscription';
        req.Tenant_ID__c = tenantId;
    
        String getResponse = '{"Data":{"Subscribed":null,"Cancelled":null,"SubscriptionName":"Trial","SubscriptionExpirationDate":"2024-03-01T00:00:00","Source":"Website (Direct)","ReferredByPartner":null,"ReferredByPartnerId":null,"PlanType":null,"IsNeedAttention":false,"CustomerDomain":"usertest.com","Utm_Campaign":null,"Utm_Source":null,"Utm_Medium":null,"Utm_Term":null,"Utm_Content":null,"PartnerType":null,"IsVarPartner":null,"ReferrerDomain":null,"AdditionalUsers":0,"AdditionalUsersCost":0.0000,"Discount":0.0000,"Status":"Trial","AnniversaryDate":null,"IntegrationCount":0,"SalesCount":15,"Sales3MonthsCount":0,"Sales6MonthsCount":0,"Sales12MonthsCount":0,"SalesGMV":30351.3500,"SalesGMV3Months":0.0000,"SalesGMV6Months":0.0000,"SalesGMV12Months":0.0000,"SKUs":["SKUs": [{"Name": "Standard Yearly 2021","Quantity": 2,"Total": 1200.0000,"Frequency": "monthly"}, {"Name": "Prod2","Quantity": 2,"Total": 1200.0000,"Frequency": "monthly"}],"Users":[{"UserId":"cbecdcde-d39c-4620-9d84-1e57afe87e15","Email":"john@doe.com","UserType":"user","DisplayName":"John Doe"},{"UserId":"b587c24d-b53b-4f95-b837-48580a1a39c4","Email":"jane@doe.com","UserType":"owner","DisplayName":"Jane Doe"}],"Discounts":[],"Country":"United States","CreateDate":"2024-02-16T18:06:04.773","Email":"actester@usertest.com","LastUpdatedDate":"2024-02-27T21:20:14.363","Organisation":"UserTestAcct","SalesPersonEmail":"am.siddiquie@dearsystems.com","TenantID":"111013f4-48c0-4cdd-9e53-3bc461d42d64","WebsiteURL":null,"Contacts":[{"Phone":"8888888888888","Email":"actester@usertest.com","FirstName":"Andrew","LastName":"Tester"}]}}';
        MockHttpResponseHandler.SimpleMockResponse getResp = new MockHttpResponseHandler.SimpleMockResponse('GET', getResponse);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse('callout:Customer_Details', getResp);

        Account acc = new Account(
            Name = 'Nuage AK Test',
            DEAR_Tenant_ID__c = tenantId,
            Dear_CRM_Status__c = 'Client',
            Subscription_Expiration_Date__c = Date.today().addDays(365),
            BillingCity = 'Chino',
            BillingCountry = 'United States',
            BillingCountryCode = 'US',
            AccountSource = 'Direct Traffic',
            BillingStreet = '245 Elm Street',
            BillingPostalCode = '95811',
            Cin7_Username__c = 'Cin7-User-1727480561844'
        );
        insert acc;
    
        Opportunity currentOpp = new Opportunity(
            AccountId = acc.Id,
            Amount = 50000,
            Name = 'Nuage Test-',
            DEAR_Tenant_ID__c = tenantId,
            StageName = 'Prospecting',
            CloseDate = System.today().addDays(30),
            Pricebook2Id = Test.getStandardPricebookId(),
            Is_Active__c = true
        );
        insert currentOpp; 


        // Act
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, mock);
            Database.executeBatch(new IncomingReqNewSubscriptionBatch(new List<Incoming_Request__c>{req}));
        Test.stopTest();

        // Post-assert
        // List<Contact> assertContacts = [SELECT Name, Email, Cin7_Core_User_Id__c FROM Contact];
        // Assert.areEqual(2, assertContacts.size());
        // Boolean foundJohn = false;
        // Boolean foundJane = false;
        // for (Contact c : assertContacts)
        // {
        //     if (c.Name == 'John Doe')
        //     {
        //         Assert.areEqual('cbecdcde-d39c-4620-9d84-1e57afe87e15', c.Cin7_Core_User_Id__c);
        //         Assert.areEqual('john@doe.com', c.Email);
        //         foundJohn = true;
        //     } 
        //     if (c.Name == 'Jane Doe') 
        //     {
        //         Assert.areEqual('b587c24d-b53b-4f95-b837-48580a1a39c4', c.Cin7_Core_User_Id__c);
        //         Assert.areEqual('jane@doe.com', c.Email);
        //         foundJane = true;
        //     }
        // }
        // Assert.isTrue(foundJohn);
        // Assert.isTrue(foundJane);

        // Assert.areEqual(1, [SELECT COUNT() FROM Opportunity]);

        // List<AccountContactRelation> assertAcrs = [SELECT AccountId, ContactId from AccountContactRelation];
        // Assert.areEqual(2, assertAcrs.size());
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
            Database.executeBatch(new IncomingReqNewSubscriptionBatch(new List<Incoming_Request__c>{req}));
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
            Database.executeBatch(new IncomingReqNewSubscriptionBatch(new List<Incoming_Request__c>{req}));
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



    
}