/**
 * @description       : 
 * @author            : AS | NuAge Experts
 * @group             : 
 * @last modified on  : 04-02-2024
 * @last modified by  : AS | NuAge Experts
**/
@isTest
public with sharing class IncomingRequestTest {

    @TestSetup
    static void setup(){
        //assign
        Account acc = new Account();
            acc.Name = 'Test Account';
            acc.DEAR_Tenant_ID__c = 'b12294de-e20c-4dc6-8772-416a5c5f5246';
        Account acc1 = new Account();
            acc1.Name = 'Test Account 1';
            acc1.DEAR_Tenant_ID__c = 'b12294de-e20c-4dc6-8772-416a5c5f5247';
        insert new List<Account> {acc, acc1};

        Contact con = new Contact();
            con.FirstName = 'Test';
            con.LastName = 'Contact';
            con.Email = 'test@email.com';
            con.DEAR_Tenant_ID__c = 'b12294de-e20c-4dc6-8772-416a5c5f5246';
        insert con;

        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(Id = pricebookId,IsActive = true);
        update standardPricebook;

        Opportunity opp = new Opportunity();
            opp.Name = 'Test Opp';
            opp.AccountId = acc.Id;
            opp.CloseDate = System.today();
            opp.StageName = 'New';
            opp.DEAR_Tenant_ID__c = 'b12294de-e20c-4dc6-8772-416a5c5f5246';
            opp.Pricebook2Id = standardPricebook.Id;
            opp.Is_Active__c = true;
        Opportunity opp1 = new Opportunity();
            opp1.Name = 'Test Opp 1';
            opp1.AccountId = acc.Id;
            opp1.CloseDate = System.today();
            opp1.StageName = 'Closed Won';
            opp1.DEAR_Tenant_ID__c = 'b12294de-e20c-4dc6-8772-416a5c5f5247';
            opp1.Pricebook2Id = standardPricebook.Id;
            opp1.Is_Active__c = true;
            opp1.Amount = 1200;
        insert new List<Opportunity> {opp, opp1};

        Product2 prod = new Product2();
            prod.Name = 'Standard Yearly 2021';
            prod.ProductCode = 'Standard Yearly 2021';
            prod.IsActive = true;
        Product2 prod2 = new Product2();
            prod2.Name = 'Users';
            prod2.ProductCode = 'Users';
            prod2.IsActive = true;
        Product2 prod3 = new Product2();
            prod3.Name = 'Pro 2023';
            prod3.ProductCode = 'Pro 2023';
            prod3.IsActive = true;
        insert new List<Product2> {prod, prod2, prod3};

        PriceBookEntry pbe = new PriceBookEntry();
            pbe.Pricebook2Id = standardPricebook.Id;
            pbe.Product2Id = prod.Id;
            pbe.UnitPrice = 100;
            pbe.IsActive = true;
        PriceBookEntry pbe2 = new PriceBookEntry();
            pbe2.Pricebook2Id = standardPricebook.Id;
            pbe2.Product2Id = prod2.Id;
            pbe2.UnitPrice = 500;
            pbe2.IsActive = true;
        PriceBookEntry pbe3 = new PriceBookEntry();
            pbe3.Pricebook2Id = standardPricebook.Id;
            pbe3.Product2Id = prod3.Id;
            pbe3.UnitPrice = 999;
            pbe3.IsActive = true;
        insert new List<PricebookEntry> {pbe, pbe2, pbe3};

        OpportunityLineItem oppLine = new OpportunityLineItem(
            UnitPrice = 100,
            Quantity = 10,
            OpportunityId = opp.Id,
            PricebookEntryId = pbe.Id);            
        OpportunityLineItem oppLine2 = new OpportunityLineItem(
            UnitPrice = 50,
            Quantity = 1,
            OpportunityId = opp.Id,
            PricebookEntryId = pbe2.Id);

            insert new List<OpportunityLineItem> {oppLine, oppLine2};
        
        Lead newLead = new Lead();
            newLead.FirstName = 'Yoshi';
            newLead.LastName = 'Toyota';
            newLead.Company = 'Toyota Inc.';
            newLead.Email = 'toyota@cars.com';
            newLead.Phone = '+18009996678';
            newLead.street = '';
            newLead.City = 'Kyoto';
            newLead.State = '';
            newLead.Country = 'Japan';
            newLead.Timezone__c = 'Central Asia Standard Time (GMT+06:00)';
            newLead.Industry = 'AGP';
            newLead.Website = '';
            newLead.Core_Trial_Days__c = 14;
            newLead.Interested_in_demo__c = true;
            newLead.Free_Trial_Creation__c = true;
            newLead.isTest__c = true;
            newLead.Type__c ='Customer';

        MockHttpResponseHandler mock = new MockHttpResponseHandler();

        //successful POST which returns data in JSON body
        String postResponse = '{"StatusCode":"organisation_created","Data":{"TenantID":"998a3592-3460-4882-b11d-47e9ef67a519","RequestID":"88220c39-c9da-48b8-b71e-5b8e8bd8c31f"}}';
        MockHttpResponseHandler.SimpleMockResponse postResp = new MockHttpResponseHandler.SimpleMockResponse('POST', postResponse);
        mock.addResponse('callout:Account_Provisions', postResp);

        Test.startTest();
            Test.setMock(HttpCalloutMock.class, mock);
            insert newLead;
        Test.stopTest();
    }
    /*
    @isTest
    public static void leadConvert_Test(){
        Lead convertLead = [SELECT FirstName,LastName,Company,Email,Phone,Street,City,State,Country,Timezone__c,DEAR_Tenant_ID__c,isTest__c FROM Lead WHERE Company = 'Toyota Inc.'];

        Incoming_Request__c req = new Incoming_Request__c();
        req.Source__c = 'Cin7 Core';
        req.Message__c = IncomingRequestHelper.NEW_SUBSCRIPTION;
        req.Tenant_ID__c = '998a3592-3460-4882-b11d-47e9ef67a519';

        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(Id = pricebookId,IsActive = true);
        update standardPricebook;

        String getResponse = '{"Data": {"Subscribed": null,"Cancelled": null,"SubscriptionName": "Trial","SubscriptionExpirationDate": "2023-07-06T00:00:00","Source": "Website (Direct)","ReferredByPartner": null,"ReferredByPartnerId": null,"PlanType": null,"IsNeedAttention": false,"CustomerDomain": "test@email.com","Utm_Campaign": null,"Utm_Source": null,"Utm_Medium": null,"Utm_Term": null,"Utm_Content": null,"PartnerType": null,"IsVarPartner": null,"ReferrerDomain": null,"AdditionalUsers": 0,"AdditionalUsersCost": 0.0000,"Status": "Trial","SKUs": [],"Country": "Canada","CreateDate": "2023-06-22T22:36:26.867","Email": "test@email.com","LastUpdatedDate": "2023-06-22T22:36:29.427","Organisation": "Workin Remote","SalesPersonEmail": "anushree.l@dearsystems.com","TenantID": "998a3592-3460-4882-b11d-47e9ef67a519","WebsiteURL": null,"Contacts": [{"Phone": "1234567890","Email": "test@email.com","FirstName": "Test","LastName": "ERE"}], "Users": [{"UserId": "765f9151-cf0d-439f-8811-b248080fdc31","Email": "bshaw@whitecaps.com","UserType": "owner","DisplayName": "Brendan Shaw"}]}}';
        MockHttpResponseHandler.SimpleMockResponse getResp = new MockHttpResponseHandler.SimpleMockResponse('GET', getResponse);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse('callout:Customer_Details', getResp);

        Test.startTest();
            Test.setMock(HttpCalloutMock.class, mock);
            insert req;
        Test.stopTest();
    }
        */

    @isTest
    public static void badTenantId_Test(){
        Incoming_Request__c req = new Incoming_Request__c();
        req.Source__c = 'Cin7 Core';
        req.Message__c = IncomingRequestHelper.NEW_SUBSCRIPTION;
        req.Tenant_ID__c = '12345';

        String getResponse = '{"Errors": ["Parameter tenantId has incorect Guid format. Expected format is 00000000-0000-0000-0000-000000000000."]}';
        MockHttpResponseHandler.SimpleMockResponse getResp = new MockHttpResponseHandler.SimpleMockResponse('GET', getResponse);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse('callout:Customer_Details', getResp);

        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(Id = pricebookId,IsActive = true);
        update standardPricebook;

        Test.startTest();
            Test.setMock(HttpCalloutMock.class, mock);
            insert req;
        Test.stopTest();
    }

    @isTest
    static void testCalloutFailureLogging() {
        // Arrange: Set up mock to simulate a failed callout
        MockHttpResponseHandler.SimpleMockResponse response = new MockHttpResponseHandler.SimpleMockResponse('GET', '{}', 500);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse('callout:Customer_Details', response);
        Test.setMock(HttpCalloutMock.class, mock);
        
        // Create incoming request data
        List<Incoming_Request__c> incomingRequests = new List<Incoming_Request__c>();
        Incoming_Request__c req = new Incoming_Request__c(Tenant_ID__c = '12345');
        incomingRequests.add(req);

        // Instantiate batchable class
        IncomingRequestBatchable batchable = new IncomingRequestBatchable(incomingRequests);

        // Act: Execute batchable code
        Test.startTest();
        Database.executeBatch(batchable);
        Test.stopTest();

        // Assert: Verify that error logs were created
        List<API_Error_Log__c> logs = [SELECT Error_Message__c, Status__c, Incoming_Request_Tenant_Id__c FROM API_Error_Log__c];
        System.assertEquals(1, logs.size(), 'One error log should be created for the callout failure');
        System.assert(logs[0].Error_Message__c.contains('System.QueryException'));
    }


    @isTest
    public static void opportunityWithLineItemsSync_Test(){
        // assemble
        Incoming_Request__c req = new Incoming_Request__c();
        req.Source__c = 'Cin7 Core';
        req.Message__c = IncomingRequestHelper.NEW_SUBSCRIPTION;
        req.Tenant_ID__c = 'b12294de-e20c-4dc6-8772-416a5c5f5246';

        //assign
        String getResponse = '{"Data":{"Subscribed": "2022-09-28T13:02:26.457","Cancelled": null,"SubscriptionName": "Standard Yearly 2021","SubscriptionExpirationDate": "2023-10-27T00:00:00","Source": "Partner Referral","ReferredByPartner": "Test","ReferredByPartnerId": "477a126d-e6b3-483f-b223-8c5655bebc9a","PlanType": "standard","IsNeedAttention": true,"CustomerDomain": "Yashodha","Utm_Campaign": null,"Utm_Source": null,"Utm_Medium": null,"Utm_Term": null,"Utm_Content": null,"PartnerType": null,"IsVarPartner": false,"ReferrerDomain": null,"AdditionalUsers": 10,"AdditionalUsersCost": 100.0000,"SKUs": [{"Name": "Standard Yearly 2021","Quantity": 2,"Total": 1200.0000,"Frequency": "Monthly"}],"Country": "Australia","CreateDate": "2022-09-28T12:57:05.767","Email": "ep@dearsystems.com","LastUpdatedDate": null,"Organisation": "Test Var Client 1","SalesPersonEmail": "ele@gmail.com","TenantID": "b12294de-e20c-4dc6-8772-416a5c5f5246","WebsiteURL": "mail.com","Contacts":[{"Phone": "561526","Email": "p.p@dearsystems.com","FirstName": "DEFAULT","LastName": "business contact"}], "Users": [{"UserId": "765f9151-cf0d-439f-8811-b248080fdc31","Email": "bshaw@whitecaps.com","UserType": "owner","DisplayName": "Brendan Shaw"}]}}';
        MockHttpResponseHandler.SimpleMockResponse getResp = new MockHttpResponseHandler.SimpleMockResponse('GET', getResponse);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse('callout:Customer_Details', getResp);

        Test.startTest();
            Test.setMock(HttpCalloutMock.class, mock);
            insert req;
        Test.stopTest();
        Opportunity opp = [SELECT Name FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];

        // assert
        Assert.areEqual(2,[SELECT Name,TotalPrice,UnitPrice,Quantity FROM OpportunityLineItem WHERE OpportunityId =: opp.Id].size());
        Assert.areEqual(2, [SELECT Name,TotalPrice,UnitPrice,Quantity FROM OpportunityLineItem WHERE OpportunityId =: opp.Id AND ProductCode = 'Standard Yearly 2021'].Quantity);
        Assert.areEqual(600, [SELECT Name,TotalPrice,UnitPrice,Quantity FROM OpportunityLineItem WHERE OpportunityId =: opp.Id AND ProductCode = 'Standard Yearly 2021'].UnitPrice);
    }

    @isTest
    public static void opportunityWithoutLineItemsSync_Test(){
        // assemble
        Incoming_Request__c req = new Incoming_Request__c();
        req.Source__c = 'Cin7 Core';
        req.Message__c = IncomingRequestHelper.NEW_SUBSCRIPTION;
        req.Tenant_ID__c = 'b12294de-e20c-4dc6-8772-416a5c5f5246';

        // assign
        Opportunity opp = [SELECT Name FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];
        delete [SELECT Name FROM OpportunityLineItem WHERE OpportunityId =: opp.Id];

        String getResponse = '{"Data":{"Subscribed": "2022-09-28T13:02:26.457","Cancelled": null,"SubscriptionName": "Standard Yearly 2021","SubscriptionExpirationDate": "2023-10-27T00:00:00","Source": "Partner Referral","ReferredByPartner": "Test","ReferredByPartnerId": "477a126d-e6b3-483f-b223-8c5655bebc9a","PlanType": "standard","IsNeedAttention": true,"CustomerDomain": "Yashodha","Utm_Campaign": null,"Utm_Source": null,"Utm_Medium": null,"Utm_Term": null,"Utm_Content": null,"PartnerType": null,"IsVarPartner": false,"ReferrerDomain": null,"AdditionalUsers": 10,"AdditionalUsersCost": 100.0000,"SKUs": [{"Name": "Standard Yearly 2021","Quantity": 2,"Total": 1200.0000,"Frequency": "Yearly"}],"Country": "Australia","CreateDate": "2022-09-28T12:57:05.767","Email": "ep@dearsystems.com","LastUpdatedDate": null,"Organisation": "Test Var Client 1","SalesPersonEmail": "ele@gmail.com","TenantID": "b12294de-e20c-4dc6-8772-416a5c5f5246","WebsiteURL": "mail.com","Contacts":[{"Phone": "561526","Email": "p.p@dearsystems.com","FirstName": "DEFAULT","LastName": "business contact"}], "Users": [{"UserId": "765f9151-cf0d-439f-8811-b248080fdc31","Email": "bshaw@whitecaps.com","UserType": "owner","DisplayName": "Brendan Shaw"}]}}';
        MockHttpResponseHandler.SimpleMockResponse getResp = new MockHttpResponseHandler.SimpleMockResponse('GET', getResponse);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse('callout:Customer_Details', getResp);

        Test.startTest();
            Test.setMock(HttpCalloutMock.class, mock);
            insert req;
        Test.stopTest();

        // assert
        Assert.areEqual(2,[SELECT Name,TotalPrice,UnitPrice,Quantity FROM OpportunityLineItem WHERE OpportunityId =: opp.Id].size());
        Assert.areEqual(2, [SELECT Name,TotalPrice,UnitPrice,Quantity FROM OpportunityLineItem WHERE OpportunityId =: opp.Id AND ProductCode = 'Standard Yearly 2021'].Quantity);
        Assert.areEqual(50, [SELECT Name,TotalPrice,UnitPrice,Quantity FROM OpportunityLineItem WHERE OpportunityId =: opp.Id AND ProductCode = 'Standard Yearly 2021'].UnitPrice);
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

    // Test method used to test when a "DiscountChange" Incoming Request message is submitted before the account is signed up it does not create a new "Upsell/Downsell" Opp.
    @isTest 
    public static void discountChange_Test(){
        // assemble
        Incoming_Request__c req = new Incoming_Request__c();
        req.Source__c = 'Cin7 Core';
        req.Message__c = 'DiscountChange';
        req.Tenant_ID__c = 'b12294de-e20c-4dc6-8772-416a5c5f5246';

        Assert.areEqual('New',[SELECT StageName FROM Opportunity WHERE Name = 'Test Opp'].StageName);

        String getResponse = '{"Data":{"Subscribed": "2022-09-28T13:02:26.457","Cancelled": null,"SubscriptionName": "Standard Yearly 2021","SubscriptionExpirationDate": "2023-10-27T00:00:00","Source": "Partner Referral","ReferredByPartner": "Test","ReferredByPartnerId": "477a126d-e6b3-483f-b223-8c5655bebc9a","PlanType": "standard","IsNeedAttention": true,"CustomerDomain": "Yashodha","Utm_Campaign": null,"Utm_Source": null,"Utm_Medium": null,"Utm_Term": null,"Utm_Content": null,"PartnerType": null,"IsVarPartner": false,"ReferrerDomain": null,"AdditionalUsers": 10,"AdditionalUsersCost": 100.0000,"SKUs": [{"Name": "Standard Yearly 2021","Quantity": 2,"Total": 1200.0000,"Frequency": "Yearly"}],"Country": "Australia","CreateDate": "2022-09-28T12:57:05.767","Email": "ep@dearsystems.com","LastUpdatedDate": null,"Organisation": "Test Var Client 1","SalesPersonEmail": "ele@gmail.com","TenantID": "b12294de-e20c-4dc6-8772-416a5c5f5246","WebsiteURL": "mail.com","Contacts":[{"Phone": "561526","Email": "p.p@dearsystems.com","FirstName": "DEFAULT","LastName": "business contact"}]}}';
        MockHttpResponseHandler.SimpleMockResponse getResp = new MockHttpResponseHandler.SimpleMockResponse('GET', getResponse);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse('callout:Customer_Details', getResp);

        Test.startTest();
            Test.setMock(HttpCalloutMock.class, mock);
            insert req;
        Test.stopTest();

        Assert.areEqual(2, [SELECT COUNT() FROM Opportunity]);
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

    // Go back and add asserts to all of Adam's tests

    @isTest
    static void jsonParseCoverage()
    {
        // Assemble
        IncomingRequestJSONParse.Data data = new IncomingRequestJSONParse.Data();
        data.Sales6MonthsCount = 0;
        data.IntegrationCount = 0;
        data.SalesCount = 0;
        data.AnniversaryDate = '12/16/23';
        data.Sales3MonthsCount = 0;
        data.Sales12MonthsCount = 0;
        data.Discount = 0;
        data.SalesGMV3Months = 0;
        data.SalesGMV6Months = 0;
        data.SalesGMV12Months = 0;
        data.ReferrerDomain = 'thisisadomain';
        data.IsVarPartner = 'varp';
        data.SKUs = new List<IncomingRequestJSONParse.SKUs>();
        data.Utm_Content = 'content';
        data.Utm_Term = 'term';
        data.Utm_Medium = 'med';
        data.Utm_Source = 'source';
        data.Utm_Campaign = 'camp';
        data.CustomerDomain = 'cd';
        data.IsNeedAttention = false;
        data.SalesPersonEmail = 'email';
        data.PlanType = 'ptype';
        data.ReferredByPartnerId = 'partId';
        data.ReferredByPartner = 'partner';
        data.SubscriptionName = 'subname';
        data.Source = 'source';
    }

    // CIN7-90
    // @isTest
    // static void testSubscriptionCancellation()
    // {
    //     // Assemble
    //     Account a = new Account(
    //         Name = 'Test Account',
    //         Dear_Tenant_Id__c = 'cin790'
    //     );
    //     insert a;

    //     Id pricebookId = Test.getStandardPricebookId();
    //     Pricebook2 standardPricebook = new Pricebook2(Id = pricebookId,IsActive = true);
    //     update standardPricebook;

    //     Id coreNewSalesRtId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Core New Sales').getRecordTypeId();
    //     Opportunity o = new Opportunity(
    //         Name = 'CIN7-90 Test Opp',
    //         AccountId = a.Id,
    //         Dear_Tenant_Id__c = a.Dear_Tenant_Id__c,
    //         CloseDate = Date.today(),
    //         RecordTypeId = coreNewSalesRtId,
    //         Pricebook2Id = standardPricebook.Id,
    //         Is_Active__c = true,
    //         Amount = 1000,
    //         CurrencyIsoCode = 'USD',
    //         StageName = 'Closed Won'
    //     );
    //     insert o;

    //     Product2 prod1 = new Product2(
    //         Name = 'Test Product 1',
    //         ProductCode = 'Test Product 1',
    //         IsActive = true
    //     );
    //     Product2 prod2 = new Product2(
    //         Name = 'Test Product 1',
    //         ProductCode = 'Test Product 1',
    //         IsActive = true
    //     );
    //     Product2 prod3 = new Product2(
    //         Name = 'Test Product 1',
    //         ProductCode = 'Test Product 1',
    //         IsActive = true
    //     );
    //     insert new List<Product2> {prod1, prod2, prod3};

    //     PriceBookEntry pbe1 = new PriceBookEntry(
    //         Pricebook2Id = standardPricebook.Id,
    //         Product2Id = prod1.Id,
    //         UnitPrice = 250,
    //         IsActive = true,
    //         CurrencyIsoCode = 'USD'
    //     );
    //     PriceBookEntry pbe2 = new PriceBookEntry(
    //         Pricebook2Id = standardPricebook.Id,
    //         Product2Id = prod2.Id,
    //         UnitPrice = 250,
    //         IsActive = true,
    //         CurrencyIsoCode = 'USD'
    //     );
    //     PriceBookEntry pbe3 = new PriceBookEntry(
    //         Pricebook2Id = standardPricebook.Id,
    //         Product2Id = prod3.Id,
    //         UnitPrice = 250,
    //         IsActive = true,
    //         CurrencyIsoCode = 'USD'
    //     );
    //     insert new List<PriceBookEntry> {pbe1, pbe2, pbe3};

    //     OpportunityLineItem oli1 = new OpportunityLineItem(
    //         UnitPrice = 250,
    //         Quantity = 2,
    //         OpportunityId = o.Id,
    //         PricebookEntryId = pbe1.Id
    //     );
    //     OpportunityLineItem oli2 = new OpportunityLineItem(
    //         UnitPrice = 250,
    //         Quantity = 1,
    //         OpportunityId = o.Id,
    //         PricebookEntryId = pbe2.Id
    //     );
    //     OpportunityLineItem oli3 = new OpportunityLineItem(
    //         UnitPrice = 250,
    //         Quantity = 1,
    //         OpportunityId = o.Id,
    //         PricebookEntryId = pbe3.Id
    //     );
    //     insert new List<OpportunityLineItem> {oli1, oli2, oli3};

    //     Incoming_Request__c req = new Incoming_Request__c(
    //         Source__c = 'Cin7 Core',
    //         Message__c = IncomingRequestHelper.CANCEL_SUBSCRIPTION,
    //         Tenant_ID__c = 'cin790'
    //     );

    //     Assert.areEqual('Closed Won',[SELECT StageName FROM Opportunity WHERE Id = :o.Id].StageName);

    //     String expDateString = Date.today().addMonths(6).toString();
    //     String getResponse = '{"Data":{"TenantID":"cin790", "SubscriptionExpirationDate":"' + expDateString + '", "Organisation":"' + a.Name + '"}}';
    //     MockHttpResponseHandler.SimpleMockResponse getResp = new MockHttpResponseHandler.SimpleMockResponse('GET', getResponse);
    //     MockHttpResponseHandler mock = new MockHttpResponseHandler();
    //     mock.addResponse('callout:Customer_Details', getResp);

    //     Test.startTest();
    //         Test.setMock(HttpCalloutMock.class, mock);
    //         insert req;
    //     Test.stopTest();

    //     // Assert
    //     List<Opportunity> assertOpps = [SELECT Id, Name, AccountId, Dear_Tenant_Id__c, CloseDate, RecordTypeId, Pricebook2Id, 
    //             Is_Active__c, Amount, StageName, (select Quantity, UnitPrice, TotalPrice, PricebookEntryId from OpportunityLineItems) 
    //         FROM Opportunity WHERE Name LIKE '%CIN7-90%'];

    //     Assert.areEqual(2, assertOpps.size());
    //     Boolean foundOppOriginal = false;
    //     Boolean foundOppClone = false;
    //     Boolean foundOppLinesOriginal = false;
    //     Boolean foundOppLinesClone = false;

    //     for (Opportunity assertOpp : assertOpps)
    //     {
    //         Assert.areEqual('Closed Won', assertOpp.StageName);
    //         Assert.areEqual(a.Id, assertOpp.AccountId);
    //         Assert.areEqual('cin790', assertOpp.Dear_Tenant_Id__c);
    //         Assert.areEqual(Date.today(), assertOpp.CloseDate);
    //         Assert.areEqual(o.RecordTypeId, assertOpp.RecordTypeId);
    //         Assert.isTrue(assertOpp.Is_Active__c);

    //         if (assertOpp.Id == o.Id)
    //         {
    //             Assert.areEqual(o.Amount, assertOpp.Amount);
    //             foundOppOriginal = true;
    //             Assert.areEqual(3, assertOpp.OpportunityLineItems.size());

    //             for (OpportunityLineItem oli : assertOpp.OpportunityLineItems)
    //             {
    //                 Assert.areEqual(250, oli.UnitPrice);
    //                 Assert.isTrue(oli.Quantity != 0);
    //                 Assert.areEqual(oli.UnitPrice * oli.Quantity, oli.TotalPrice);
    //                 Assert.isNotNull(oli.PricebookEntryId);
    //                 foundOppLinesOriginal = true;
    //             }   
    //         }
    //         else
    //         {
    //             Assert.areEqual(0, assertOpp.Amount);
    //             Assert.areEqual(o.Name + ' - Cancellation', assertOpp.Name);
    //             foundOppClone = true;
    //             Assert.areEqual(3, assertOpp.OpportunityLineItems.size());
    //             for (OpportunityLineItem oli : assertOpp.OpportunityLineItems)
    //             {
    //                 Assert.areEqual(0, oli.UnitPrice);
    //                 Assert.isTrue(oli.Quantity != 0);
    //                 Assert.areEqual(0, oli.TotalPrice);
    //                 Assert.isNotNull(oli.PricebookEntryId);
    //                 foundOppLinesClone = true;
    //             }
    //         }
    //     }
    //     Assert.isTrue(foundOppOriginal);
    //     Assert.isTrue(foundOppLinesOriginal);
    //     Assert.isTrue(foundOppClone);
    //     Assert.isTrue(foundOppLinesClone);
    // }
}