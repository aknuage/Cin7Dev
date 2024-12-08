@isTest
public with sharing class IncomingRequDiscountChangeTest {

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
}