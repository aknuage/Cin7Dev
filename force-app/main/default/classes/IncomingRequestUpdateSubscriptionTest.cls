@isTest
public with sharing class IncomingRequestUpdateSubscriptionTest {

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
            insert req;
        Test.stopTest();

        // Post-assert
        Assert.areEqual(2,[SELECT COUNT() FROM Contact]);
        Assert.areEqual(1, [SELECT COUNT() FROM Contact WHERE Name = 'John Doe']);
        Assert.areEqual(1, [SELECT COUNT() FROM Contact WHERE Name = 'Jane Doe']);
        Assert.areEqual(2, [SELECT COUNT() FROM Opportunity]);
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
        insert req;
        Test.stopTest();

        // Post-assert
        List<Contact> assertContact = [SELECT FirstName, LastName, Cin7_Core_User_Id__c FROM Contact];
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
        Assert.isTrue(foundJane && foundJohn);
        Assert.areEqual(2, [SELECT COUNT() FROM Opportunity]);
    }

    @isTest
    public static void testUpsellDownsell()
    {
        // Assemble
        Opportunity opp = [SELECT StageName, OwnerId FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];
        opp.StageName = 'Closed Won';
        update opp;

        Incoming_Request__c req = new Incoming_Request__c();
        req.Source__c = 'Cin7 Core';
        req.Message__c = 'UpdateSubscription';
        req.Tenant_ID__c = 'b12294de-e20c-4dc6-8772-416a5c5f5246';

        String getResponse = '{"Data":{"Subscribed": "2022-09-28T13:02:26.457","Cancelled": null,"SubscriptionName": "Standard Yearly 2021","SubscriptionExpirationDate": "2023-10-27T00:00:00","Source": "Partner Referral","ReferredByPartner": "Test","ReferredByPartnerId": "477a126d-e6b3-483f-b223-8c5655bebc9a","PlanType": "standard","IsNeedAttention": true,"CustomerDomain": "Yashodha","Utm_Campaign": null,"Utm_Source": null,"Utm_Medium": null,"Utm_Term": null,"Utm_Content": null,"PartnerType": null,"IsVarPartner": false,"ReferrerDomain": null,"AdditionalUsers": 10,"AdditionalUsersCost": 100,"SKUs": [{"Name": "Pro 2023","Quantity": 1,"Total": 1000.00,"Frequency": "Monthly"},{"Name": "Standard Yearly 2021","Quantity": 2,"Total": 200.00,"Frequency": "Yearly"}],"Country": "Australia","CreateDate": "2022-09-28T12:57:05.767","Email": "ep@dearsystems.com","LastUpdatedDate": null,"Organisation": "Test Var Client 1","SalesPersonEmail": "ele@gmail.com","TenantID": "b12294de-e20c-4dc6-8772-416a5c5f5246","WebsiteURL": "mail.com","Contacts":[{"Phone": "561526","Email": "p.p@dearsystems.com","FirstName": "DEFAULT","LastName": "business contact"}], "Users": [{"UserId": "765f9151-cf0d-439f-8811-b248080fdc31","Email": "bshaw@whitecaps.com","UserType": "owner","DisplayName": "Brendan Shaw"}]}}';
        MockHttpResponseHandler.SimpleMockResponse getResp = new MockHttpResponseHandler.SimpleMockResponse('GET', getResponse);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse('callout:Customer_Details', getResp);

        Assert.areEqual(2, [SELECT COUNT() FROM Opportunity]);

        // Act
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, mock);
            insert req;
        Test.stopTest();

        // Assert
        List<Opportunity> oppAssert = [SELECT Name, OwnerId, Is_Active__c, Dear_Tenant_Id__c, 
                (select Id, UnitPrice, Quantity, PricebookEntry.ProductCode, Billing_Frequency__c from OpportunityLineItems)
                FROM Opportunity WHERE Name = 'Test Opp' and StageName = 'Closed Won'];
        Assert.areEqual(2, oppAssert.size());

        Boolean foundNewOpp = false;
        Integer activeOppsCount = 0;
        Boolean matchedOwnerId = false;
        Boolean foundOriginalOpp = false;
        Boolean foundPro2023 = false;
        Boolean foundYearly2021 = false;
        Boolean foundUsers = false;
        for (Opportunity o : oppAssert)
        {
            assert.areEqual('b12294de-e20c-4dc6-8772-416a5c5f5246', o.Dear_Tenant_Id__c);

            if (o.Is_Active__c)
            {
                activeOppsCount++;
                assert.areEqual(3, o.OpportunityLineItems.size());
                foundNewOpp = true;
                assert.areEqual(opp.OwnerId, o.OwnerId);
                matchedOwnerId = true;

                for (OpportunityLineItem oli : o.OpportunityLineItems)
                {
                    if (oli.PricebookEntry.ProductCode == 'Pro 2023')
                    {
                        assert.areEqual(1, oli.Quantity);
                        assert.areEqual(1000, oli.UnitPrice);
                        foundPro2023 = true;
                    }
                    else if (oli.PricebookEntry.ProductCode == 'Standard Yearly 2021')
                    {
                        assert.areEqual(2, oli.Quantity);
                        Decimal up = 100/12;
                        up = up.setScale(2);
                        assert.areEqual(8.33, oli.UnitPrice);
                        foundYearly2021 = true;
                    }
                    else if (oli.PricebookEntry.ProductCode == 'Users')
                    {
                        assert.areEqual(10, oli.Quantity);
                        assert.areEqual(10, oli.UnitPrice);
                        assert.areEqual('Monthly', oli.Billing_Frequency__c);
                        foundUsers = true;
                    }
                }
            }
            else
            {
                // assert # opp lines didn't change and that they're as they were
                assert.areEqual(2, o.OpportunityLineItems.size());
                
                Boolean foundOrigUsers = false;
                Boolean foundOrigYearly2021 = false;
                for (OpportunityLineItem oli : o.OpportunityLineItems)
                {
                    if (oli.PricebookEntry.ProductCode == 'Standard Yearly 2021')
                    {
                        assert.areEqual(10, oli.Quantity);
                        assert.areEqual(100, oli.UnitPrice);
                        foundOrigYearly2021 = true;
                    }
                    else if (oli.PricebookEntry.ProductCode == 'Users')
                    {
                        assert.areEqual(1, oli.Quantity);
                        assert.areEqual(50, oli.UnitPrice);
                        foundOrigUsers = true;
                    }
                }
                assert.isTrue(foundOrigYearly2021);
                assert.isTrue(foundOrigUsers);
                foundOriginalOpp = true;
            }
                
        }
        Assert.areEqual(1, activeOppsCount);
        Assert.isTrue(foundnewOpp);
        Assert.isTrue(matchedOwnerId);
        Assert.isTrue(foundOriginalOpp);
        Assert.isTrue(FoundPro2023);
        Assert.isTrue(foundYearly2021);
        Assert.isTrue(foundUsers);
    }

     // Test method used to ensure that the upsell Opportunity record type is only created if there is a legit upsell
     @isTest
     public static void zeroDollarOpportunityUpsell_Test(){
         // assemble
         Incoming_Request__c req = new Incoming_Request__c();
         req.Source__c = 'Cin7 Core';
         req.Message__c = 'UpdateSubscription';
         req.Tenant_ID__c = 'b12294de-e20c-4dc6-8772-416a5c5f5247';
 
         // assign
         String getResponse = '{"Data":{"Subscribed": "2022-09-28T3:02:26.457","Cancelled": null,"SubscriptionName": "Standard Yearly 2021","SubscriptionExpirationDate": "2023-10-27T00:00:00","Source": "Partner Referral","ReferredByPartner": "Test","ReferredByPartnerId": "477a126d-e6b3-483f-b223-8c5655bebc9a","PlanType": "standard","IsNeedAttention": true,"CustomerDomain": "Yashodha","Utm_Campaign": null,"Utm_Source": null,"Utm_Medium": null,"Utm_Term": null,"Utm_Content": null,"PartnerType": null,"IsVarPartner": false,"ReferrerDomain": null,"AdditionalUsers": 10,"AdditionalUsersCost": 100.0000,"SKUs": [{"Name": "Pro 2023","Quantity": 1,"Total": 1000.00,"Frequency": "Monthly"},{"Name": "Standard Yearly 2021","Quantity": 1,"Total": 100.00,"Frequency": "Yearly"}],"Country": "Australia","CreateDate": "2022-09-28T12:57:05.767","Email": "ep@dearsystems.com","LastUpdatedDate": null,"Organisation": "Test Var Client 1","SalesPersonEmail": "ele@gmail.com","TenantID": "b12294de-e20c-4dc6-8772-416a5c5f5246","WebsiteURL": "mail.com","Contacts":[{"Phone": "561526","Email": "p.p@dearsystems.com","FirstName": "DEFAULT","LastName": "business contact"}], "Users": [{"UserId": "765f9151-cf0d-439f-8811-b248080fdc31","Email": "bshaw@whitecaps.com","UserType": "owner","DisplayName": "Brendan Shaw"}]}}';
         MockHttpResponseHandler.SimpleMockResponse getResp = new MockHttpResponseHandler.SimpleMockResponse('GET', getResponse);
         MockHttpResponseHandler mock = new MockHttpResponseHandler();
         mock.addResponse('callout:Customer_Details', getResp);
         
         Assert.areEqual(1,[SELECT COUNT() FROM Opportunity WHERE Name = 'Test Opp 1']);
         Assert.areEqual(1200,[SELECT Amount FROM Opportunity WHERE Name = 'Test Opp 1'].Amount);
 
         Test.startTest();
             Test.setMock(HttpCalloutMock.class, mock);
             insert req;
         Test.stopTest();
         Opportunity newOpp = [SELECT Name,Amount FROM Opportunity WHERE DEAR_Tenant_ID__c = 'b12294de-e20c-4dc6-8772-416a5c5f5247' AND Is_Active__c = true LIMIT 1];
 
         Assert.areEqual(3, [SELECT COUNT() FROM Opportunity]);
         Assert.areEqual(1, [SELECT COUNT() FROM Opportunity WHERE DEAR_Tenant_ID__c = 'b12294de-e20c-4dc6-8772-416a5c5f5247' AND Is_Active__c = true]);
         Assert.areEqual(3,[SELECT COUNT() FROM OpportunityLineItem WHERE OpportunityId =: newOpp.Id]);
     }

      // Test all SKU rows match existing, no new opp
    @isTest
    static void testAllRowsMatch()
    {
        // Assemble
        Opportunity opp = [SELECT StageName, OwnerId FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];
        opp.StageName = 'Closed Won';
        update opp;

        Incoming_Request__c req = new Incoming_Request__c();
        req.Source__c = 'Cin7 Core';
        req.Message__c = 'UpdateSubscription';
        req.Tenant_ID__c = 'b12294de-e20c-4dc6-8772-416a5c5f5246';

        String getResponse = '{"Data":{"Subscribed": "2022-09-28T13:02:26.457","Cancelled": null,"SubscriptionName": "Standard Yearly 2021","SubscriptionExpirationDate": "2023-10-27T00:00:00","Source": "Partner Referral","ReferredByPartner": "Test","ReferredByPartnerId": "477a126d-e6b3-483f-b223-8c5655bebc9a","PlanType": "standard","IsNeedAttention": true,"CustomerDomain": "Yashodha","Utm_Campaign": null,"Utm_Source": null,"Utm_Medium": null,"Utm_Term": null,"Utm_Content": null,"PartnerType": null,"IsVarPartner": false,"ReferrerDomain": null,"AdditionalUsers": 1,"AdditionalUsersCost": 600,"SKUs": [{"Name": "Standard Yearly 2021","Quantity": 10,"Total": 12000,"Frequency": "Yearly"}],"Country": "Australia","CreateDate": "2022-09-28T12:57:05.767","Email": "ep@dearsystems.com","LastUpdatedDate": null,"Organisation": "Test Var Client 1","SalesPersonEmail": "ele@gmail.com","TenantID": "b12294de-e20c-4dc6-8772-416a5c5f5246","WebsiteURL": "mail.com","Contacts":[{"Phone": "561526","Email": "p.p@dearsystems.com","FirstName": "DEFAULT","LastName": "business contact"}], "Users": [{"UserId": "765f9151-cf0d-439f-8811-b248080fdc31","Email": "bshaw@whitecaps.com","UserType": "owner","DisplayName": "Brendan Shaw"}]}}';
        MockHttpResponseHandler.SimpleMockResponse getResp = new MockHttpResponseHandler.SimpleMockResponse('GET', getResponse);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse('callout:Customer_Details', getResp);

        Assert.areEqual(2, [SELECT COUNT() FROM Opportunity]);

        // Act
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, mock);
            insert req;
        Test.stopTest();

        // Assert
        // No new opps created
        Assert.areEqual(2, [SELECT COUNT() FROM Opportunity]);
    }

    // Test user yearly (unit price <= 50)
    @isTest
    static void testUserMonthly()
    {
        // Assemble
        Opportunity opp = [SELECT StageName, OwnerId FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];
        opp.StageName = 'Closed Won';
        update opp;

        Incoming_Request__c req = new Incoming_Request__c();
        req.Source__c = 'Cin7 Core';
        req.Message__c = 'UpdateSubscription';
        req.Tenant_ID__c = 'b12294de-e20c-4dc6-8772-416a5c5f5246';

        String getResponse = '{"Data":{"Subscribed": "2022-09-28T13:02:26.457","Cancelled": null,"SubscriptionName": "Standard Yearly 2021","SubscriptionExpirationDate": "2023-10-27T00:00:00","Source": "Partner Referral","ReferredByPartner": "Test","ReferredByPartnerId": "477a126d-e6b3-483f-b223-8c5655bebc9a","PlanType": "standard","IsNeedAttention": true,"CustomerDomain": "Yashodha","Utm_Campaign": null,"Utm_Source": null,"Utm_Medium": null,"Utm_Term": null,"Utm_Content": null,"PartnerType": null,"IsVarPartner": false,"ReferrerDomain": null,"AdditionalUsers": 10,"AdditionalUsersCost": 500,"SKUs": [{"Name": "Pro 2023","Quantity": 1,"Total": 100.00,"Frequency": "Monthly"},{"Name": "Standard Yearly 2021","Quantity": 2,"Total": 200.00,"Frequency": "Monthly"}],"Country": "Australia","CreateDate": "2022-09-28T12:57:05.767","Email": "ep@dearsystems.com","LastUpdatedDate": null,"Organisation": "Test Var Client 1","SalesPersonEmail": "ele@gmail.com","TenantID": "b12294de-e20c-4dc6-8772-416a5c5f5246","WebsiteURL": "mail.com","Contacts":[{"Phone": "561526","Email": "p.p@dearsystems.com","FirstName": "DEFAULT","LastName": "business contact"}], "Users": [{"UserId": "765f9151-cf0d-439f-8811-b248080fdc31","Email": "bshaw@whitecaps.com","UserType": "owner","DisplayName": "Brendan Shaw"}]}}';
        MockHttpResponseHandler.SimpleMockResponse getResp = new MockHttpResponseHandler.SimpleMockResponse('GET', getResponse);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse('callout:Customer_Details', getResp);

        Assert.areEqual(2, [SELECT COUNT() FROM Opportunity]);

        // Act
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, mock);
            insert req;
        Test.stopTest();

        // Assert
        List<Opportunity> oppAssert = [SELECT Name, OwnerId, Is_Active__c, Dear_Tenant_Id__c, 
                (select Id, UnitPrice, Quantity, PricebookEntry.ProductCode, Billing_Frequency__c from OpportunityLineItems)
                FROM Opportunity WHERE Name = 'Test Opp' and StageName = 'Closed Won'];
        Assert.areEqual(2, oppAssert.size());

        Boolean foundNewOpp = false;
        Integer activeOppsCount = 0;
        Boolean matchedOwnerId = false;
        Boolean foundOriginalOpp = false;
        Boolean foundPro2023 = false;
        Boolean foundYearly2021 = false;
        Boolean foundUsers = false;
        for (Opportunity o : oppAssert)
        {
            assert.areEqual('b12294de-e20c-4dc6-8772-416a5c5f5246', o.Dear_Tenant_Id__c);

            if (o.Is_Active__c)
            {
                activeOppsCount++;
                assert.areEqual(3, o.OpportunityLineItems.size());
                foundNewOpp = true;
                assert.areEqual(opp.OwnerId, o.OwnerId);
                matchedOwnerId = true;

                for (OpportunityLineItem oli : o.OpportunityLineItems)
                {
                    if (oli.PricebookEntry.ProductCode == 'Pro 2023')
                    {
                        assert.areEqual(1, oli.Quantity);
                        assert.areEqual(100, oli.UnitPrice);
                        foundPro2023 = true;
                    }
                    else if (oli.PricebookEntry.ProductCode == 'Standard Yearly 2021')
                    {
                        assert.areEqual(2, oli.Quantity);
                        assert.areEqual(100, oli.UnitPrice);
                        foundYearly2021 = true;
                    }
                    else if (oli.PricebookEntry.ProductCode == 'Users')
                    {
                        assert.areEqual(10, oli.Quantity);
                        assert.areEqual(50, oli.UnitPrice);
                        assert.areEqual('Monthly', oli.Billing_Frequency__c);
                        foundUsers = true;
                    }
                }
            }
            else
            {
                // assert # opp lines didn't change and that they're as they were
                assert.areEqual(2, o.OpportunityLineItems.size());
                
                Boolean foundOrigUsers = false;
                Boolean foundOrigYearly2021 = false;
                for (OpportunityLineItem oli : o.OpportunityLineItems)
                {
                    if (oli.PricebookEntry.ProductCode == 'Standard Yearly 2021')
                    {
                        assert.areEqual(10, oli.Quantity);
                        assert.areEqual(100, oli.UnitPrice);
                        foundOrigYearly2021 = true;
                    }
                    else if (oli.PricebookEntry.ProductCode == 'Users')
                    {
                        assert.areEqual(1, oli.Quantity);
                        assert.areEqual(50, oli.UnitPrice);
                        foundOrigUsers = true;
                    }
                }
                assert.isTrue(foundOrigYearly2021);
                assert.isTrue(foundOrigUsers);
                foundOriginalOpp = true;
            }
                
        }
        Assert.areEqual(1, activeOppsCount);
        Assert.isTrue(foundnewOpp);
        Assert.isTrue(matchedOwnerId);
        Assert.isTrue(foundOriginalOpp);
        Assert.isTrue(FoundPro2023);
        Assert.isTrue(foundYearly2021);
        Assert.isTrue(foundUsers);        
    }

}