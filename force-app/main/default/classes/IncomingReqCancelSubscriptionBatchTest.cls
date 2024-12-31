@isTest
public with sharing class IncomingReqCancelSubscriptionBatchTest {

    /**
     * End to end test of creating an Account, Pricebook, Opportunity with line items.
     * Then creates a Cancel_Subscription req and inserts, verifying results at the end.
     */
    @isTest
    static void testSubscriptionCancellation()
    {
        // Assemble
        Account a = new Account(
            Name = 'Test Account',
            Dear_Tenant_Id__c = 'cin790'
        );
        insert a;

        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(Id = pricebookId,IsActive = true);
        update standardPricebook;

        Id coreUpsellDownsellRtId = [select Id, Name from RecordType where sObjectType='Opportunity' and RecordType.Name = 'Core Upgrade/Downgrade' LIMIT 1].Id;
        
        Opportunity o = new Opportunity(
            Name = 'CIN7-90 Test Opp',
            AccountId = a.Id,
            Dear_Tenant_Id__c = a.Dear_Tenant_Id__c,
            CloseDate = Date.today(),
            // RecordTypeId = coreUpsellDownsellRtId,
            Pricebook2Id = standardPricebook.Id,
            Is_Active__c = true,
            Amount = 1000,
            CurrencyIsoCode = 'USD',
            StageName = 'Closed Won'
        );
        insert o;

        Product2 prod1 = new Product2(
            Name = 'Test Product 1',
            ProductCode = 'Test Product 1',
            IsActive = true
        );
        Product2 prod2 = new Product2(
            Name = 'Test Product 1',
            ProductCode = 'Test Product 1',
            IsActive = true
        );
        Product2 prod3 = new Product2(
            Name = 'Test Product 1',
            ProductCode = 'Test Product 1',
            IsActive = true
        );
        insert new List<Product2> {prod1, prod2, prod3};

        PriceBookEntry pbe1 = new PriceBookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = prod1.Id,
            UnitPrice = 250,
            IsActive = true,
            CurrencyIsoCode = 'USD'
        );
        PriceBookEntry pbe2 = new PriceBookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = prod2.Id,
            UnitPrice = 250,
            IsActive = true,
            CurrencyIsoCode = 'USD'
        );
        PriceBookEntry pbe3 = new PriceBookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = prod3.Id,
            UnitPrice = 250,
            IsActive = true,
            CurrencyIsoCode = 'USD'
        );
        insert new List<PriceBookEntry> {pbe1, pbe2, pbe3};

        OpportunityLineItem oli1 = new OpportunityLineItem(
            UnitPrice = 250,
            Quantity = 2,
            OpportunityId = o.Id,
            PricebookEntryId = pbe1.Id
        );
        OpportunityLineItem oli2 = new OpportunityLineItem(
            UnitPrice = 250,
            Quantity = 1,
            OpportunityId = o.Id,
            PricebookEntryId = pbe2.Id
        );
        OpportunityLineItem oli3 = new OpportunityLineItem(
            UnitPrice = 250,
            Quantity = 1,
            OpportunityId = o.Id,
            PricebookEntryId = pbe3.Id
        );
        insert new List<OpportunityLineItem> {oli1, oli2, oli3};

        Incoming_Request__c req = new Incoming_Request__c(
            Source__c = 'Cin7 Core',
            Message__c = IncomingRequestHelper.CANCEL_SUBSCRIPTION,
            Tenant_ID__c = 'cin790'
        );

        Assert.areEqual('Closed Won',[SELECT StageName FROM Opportunity WHERE Id = :o.Id].StageName);

        String expDateString = Date.today().addMonths(6).toString();
        // String cancelledDatetimeString = Datetime.valueOf(expDateString).toString();
        String getResponse = '{"Data":{"TenantID":"cin790", "Cancelled":"2025-10-28T13:02:26.457", "Status" : "", "SubscriptionExpirationDate":"' + expDateString + '", "Organisation":"' + a.Name + '"}}';
        MockHttpResponseHandler.SimpleMockResponse getResp = new MockHttpResponseHandler.SimpleMockResponse('GET', getResponse);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse('callout:Customer_Details', getResp);

        Test.startTest();
            Test.setMock(HttpCalloutMock.class, mock);
            insert req;
        Test.stopTest();

        // Assert
        List<Opportunity> assertOpps = [SELECT Id, Name, AccountId, Dear_Tenant_Id__c, CloseDate, RecordTypeId, Pricebook2Id, OwnerId, 
                Is_Active__c, Amount, Parent_Opportunity__c, StageName, (select Quantity, UnitPrice, TotalPrice, PricebookEntryId from OpportunityLineItems) 
            FROM Opportunity WHERE Name LIKE '%CIN7-90%'];

        Opportunity clonedOpp;
        Opportunity originalOpp;
        Account assertAcc = [SELECT Id, DEAR_Tenant_ID__c, DEAR_CRM_Status__c, Core_Last_Updated_Date__c, Subscription_Expiration_Date__c, Core_Cancelled_Date__c FROM Account WHERE Id = :a.Id LIMIT 1];

        // Assert that Account properly updated
        Assert.areEqual(null, assertAcc.DEAR_CRM_Status__c);
        Assert.areEqual(Date.today().addMonths(6), assertAcc.Subscription_Expiration_Date__c);
        Assert.areEqual('2025-10-28 07:02:26', String.valueOf(assertAcc.Core_Cancelled_Date__c));


        Assert.areEqual(2, assertOpps.size());
        Boolean foundOppOriginal = false;
        Boolean foundOppClone = false;
        Boolean foundOppLinesOriginal = false;
        Boolean foundOppLinesClone = false;

        for (Opportunity assertOpp : assertOpps)
        {
            Assert.areEqual('Closed Won', assertOpp.StageName);
            Assert.areEqual(a.Id, assertOpp.AccountId);
            Assert.areEqual('cin790', assertOpp.Dear_Tenant_Id__c);
            Assert.areEqual(Date.today(), assertOpp.CloseDate);
            // The old, cloned opp should be deactivated
            if (assertOpp.Name.contains('Cancel')) {
                Assert.isTrue(assertOpp.Is_Active__c);
                clonedOpp = assertOpp;
            } else {
                Assert.isFalse(assertOpp.Is_Active__c);
                originalOpp = assertOpp;
            }

            if (assertOpp.Id == o.Id)
            {
                Assert.areEqual(o.Amount, assertOpp.Amount);
                foundOppOriginal = true;
                Assert.areEqual(3, assertOpp.OpportunityLineItems.size());

                for (OpportunityLineItem oli : assertOpp.OpportunityLineItems)
                {
                    Assert.areEqual(250, oli.UnitPrice);
                    Assert.isTrue(oli.Quantity != 0);
                    Assert.areEqual(oli.UnitPrice * oli.Quantity, oli.TotalPrice);
                    Assert.isNotNull(oli.PricebookEntryId);
                    foundOppLinesOriginal = true;
                }
            }
            else
            {
                Assert.areEqual(0, assertOpp.Amount);
                // Parent Opp will be set for all clones
                System.assertNotEquals(null, assertOpp.Parent_Opportunity__c);
                Assert.areEqual(o.Name + ' - Cancellation', assertOpp.Name);
                foundOppClone = true;
                Assert.areEqual(3, assertOpp.OpportunityLineItems.size());
                //System.debug('assertOpps olis: ' + JSON.serializePretty(assertOpp.OpportunityLineItems));
                for (OpportunityLineItem oli : assertOpp.OpportunityLineItems)
                {
                    Assert.areEqual(0, oli.UnitPrice);
                    Assert.isTrue(oli.Quantity != 0);
                    Assert.areNotEqual(0, oli.Quantity);
                    Assert.areEqual(0, oli.TotalPrice);
                    Assert.isNotNull(oli.PricebookEntryId);
                    foundOppLinesClone = true;
                }
            }
        }
        Assert.areEqual(originalOpp.OwnerId, clonedOpp.OwnerId);
        Assert.areEqual(clonedOpp.RecordTypeId, coreUpsellDownsellRtId);

        Assert.isTrue(foundOppClone);
        Assert.isTrue(foundOppOriginal);
        Assert.isTrue(foundOppLinesClone);
        Assert.isTrue(foundOppLinesOriginal);
    }
}