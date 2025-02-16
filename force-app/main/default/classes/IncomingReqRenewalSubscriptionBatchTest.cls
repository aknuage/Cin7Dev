@isTest
public with sharing class IncomingReqRenewalSubscriptionBatchTest {

    // test that Account's Subscription Expiration updates from original value to that of the date in the JSON response
    @isTest
    public static void testAccountRenewalHappyPath() {
        String tenantId = 'F23932F1-54EB-4BFE-B929-B25FB029056D';

        // Account and related opportunity
        Account acc = new Account(
            Name = 'Nuage Test',
            DEAR_Tenant_ID__c = tenantId,
            Dear_CRM_Status__c = 'Client',
            BillingCity = 'Sacramento',
            BillingCountry = 'United States',
            BillingCountryCode = 'US',
            AccountSource = 'Direct Traffic',
            BillingStreet = '123 Any Street',
            BillingPostalCode = '95811',
            Cin7_Username__c = 'Cin7-User-1727480561844'
        );
        insert acc;
    
        Incoming_Request__c req = new Incoming_Request__c();
        req.Source__c = 'Cin7 Core';
        req.Message__c = 'RenewalSubscription';
        req.Tenant_ID__c = tenantId;

        // Mock callout setup
        String getResponse = '{"Errors":null,"Data":{"WebsiteURL":null,"Utm_Term":null,"Utm_Source":null,"Utm_Medium":null,"Utm_Content":null,"Utm_Campaign":null,"Users":[{"UserType":"owner","UserId":"cbecdcde-d39c-4620-9d84-1e57afe87e15","Email":"andrew.cooper@cin7.com","DisplayName":"Andrew Cooper"}],"TenantID":"f23932f1-54eb-4bfe-b929-b25fb029056d","SubscriptionName":"Pro 2024.01","SubscriptionExpirationDate":"2026-04-22T00:00:00","Subscribed":"2024-04-10T19:13:34.807Z","Status":"Client","Source":"Website (Direct)","AdditionalUsers": 10,"AdditionalUsersCost": 100.0000,"SKUs": [{"Name": "Standard Yearly 2021","Quantity": 2,"Total": 1200.0000,"Frequency": "Yearly"}],"SalesPersonEmail":"indeewari.k@dearsystems.com","SalesGMV6Months":437.0000,"SalesGMV3Months":437.0000,"SalesGMV12Months":437.0000,"SalesGMV":437.0000,"SalesCount":1,"Sales6MonthsCount":1,"Sales3MonthsCount":1,"Sales12MonthsCount":1,"ReferrerDomain":null,"ReferredByPartnerId":null,"ReferredByPartner":null,"PlanType":null,"PartnerType":null,"Organisation":"Andrew Trial","LastUpdatedDate":"2024-12-07T21:20:21.370Z","IsVarPartner":"false","IsOnboardingOptional":null,"IsNeedAttention":false,"IntegrationCount":0,"Email":"andrew.cooper@cin7.com","Discounts":[],"Discount":50.0000,"CustomerDomain":"cin7.com","CreateDate":"2023-07-14T15:55:51.453Z","Country":"United States","Contacts":[{"Phone":"90909099099","LastName":"Cooper","FirstName":"Andrew","Email":"andrew.cooper@cin7.com"}],"Cancelled":null,"AnniversaryDate":"2025-04-09T00:00:00"}}';
        MockHttpResponseHandler.SimpleMockResponse getResp = new MockHttpResponseHandler.SimpleMockResponse('GET', getResponse);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse('callout:Customer_Details', getResp);

        // Execute test
        Test.startTest();

        Test.setMock(HttpCalloutMock.class, mock);
        Database.executeBatch(new IncomingReqRenewalSubscriptionBatch(new List<Incoming_Request__c>{req}));

        Test.stopTest();
        
        // Assert
        Account updatedAcc = [SELECT Subscription_Expiration_Date__c FROM Account WHERE Id = :acc.Id LIMIT 1];
        // System.debug('updated acc: ' + JSON.serializePretty(updatedAcc));
        System.assertEquals('2026-04-22', String.valueOf(updatedAcc.Subscription_Expiration_Date__c));
    }

    // if the JSON response does not contain a SubscriptionExpirationDate, then it should generate an error log
    @isTest
    public static void testNullRenewalDateError() {
        String tenantId = 'F23932F1-54EB-4BFE-B929-B25FB029056D';

        // Account and related opportunity
        Account acc = new Account(
            Name = 'Nuage Null Date Test',
            DEAR_Tenant_ID__c = tenantId,
            Dear_CRM_Status__c = 'Client',
            Subscription_Expiration_Date__c = Date.today().addDays(7),
            BillingCity = 'San Francisco',
            BillingCountry = 'United States',
            BillingCountryCode = 'US',
            AccountSource = 'Direct Traffic',
            BillingStreet = '123 Main Street',
            BillingPostalCode = '95911',
            Cin7_Username__c = 'Cin7-User-1727480561844'
        );
        insert acc;
    
        Incoming_Request__c req = new Incoming_Request__c();
        req.Source__c = 'Cin7 Core';
        req.Message__c = 'RenewalSubscription';
        req.Tenant_ID__c = tenantId;

        // Mock callout setup
        String getResponse = '{"Errors":null,"Data":{"WebsiteURL":null,"Utm_Term":null,"Utm_Source":null,"Utm_Medium":null,"Utm_Content":null,"Utm_Campaign":null,"Users":[{"UserType":"owner","UserId":"cbecdcde-d39c-4620-9d84-1e57afe87e15","Email":"andrew.cooper@cin7.com","DisplayName":"Andrew Cooper"}],"TenantID":"f23932f1-54eb-4bfe-b929-b25fb029056d","SubscriptionName":"Pro 2024.01","SubscriptionExpirationDate":"null","Subscribed":"2024-04-10T19:13:34.807Z","Status":"Client","Source":"Website (Direct)","AdditionalUsers": 10,"AdditionalUsersCost": 100.0000,"SKUs": [{"Name": "Standard Yearly 2021","Quantity": 2,"Total": 1200.0000,"Frequency": "Yearly"}],"SalesPersonEmail":"indeewari.k@dearsystems.com","SalesGMV6Months":437.0000,"SalesGMV3Months":437.0000,"SalesGMV12Months":437.0000,"SalesGMV":437.0000,"SalesCount":1,"Sales6MonthsCount":1,"Sales3MonthsCount":1,"Sales12MonthsCount":1,"ReferrerDomain":null,"ReferredByPartnerId":null,"ReferredByPartner":null,"PlanType":null,"PartnerType":null,"Organisation":"Andrew Trial","LastUpdatedDate":"2024-12-07T21:20:21.370Z","IsVarPartner":"false","IsOnboardingOptional":null,"IsNeedAttention":false,"IntegrationCount":0,"Email":"andrew.cooper@cin7.com","Discounts":[],"Discount":50.0000,"CustomerDomain":"cin7.com","CreateDate":"2023-07-14T15:55:51.453Z","Country":"United States","Contacts":[{"Phone":"90909099099","LastName":"Cooper","FirstName":"Andrew","Email":"andrew.cooper@cin7.com"}],"Cancelled":null,"AnniversaryDate":"2025-04-09T00:00:00"}}';
        MockHttpResponseHandler.SimpleMockResponse getResp = new MockHttpResponseHandler.SimpleMockResponse('GET', getResponse);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse('callout:Customer_Details', getResp);

        // Execute test
        Test.startTest();

        Test.setMock(HttpCalloutMock.class, mock);
        Database.executeBatch(new IncomingReqRenewalSubscriptionBatch(new List<Incoming_Request__c>{req}));

        Test.stopTest();
        
        // Assert
        List<API_Error_Log__c> log = [SELECT Id, Error_Message__c FROM API_Error_Log__c];
        System.assertEquals(1, [SELECT count() FROM API_Error_Log__c]);
        System.assert(log[0].Error_Message__c.contains('Error processing Account Renewal'));
    }

    // if the JSON response contains errors, an API Error Log should be created
    @isTest
    public static void testNonNullErrorInJSON() {
        String tenantId = 'F23932F1-54EB-4BFE-B929-B25FB029056D';

        // Account and related opportunity
        Account acc = new Account(
            Name = 'Nuage Null Date Test',
            DEAR_Tenant_ID__c = tenantId,
            Dear_CRM_Status__c = 'Client',
            Subscription_Expiration_Date__c = Date.today().addDays(7),
            BillingCity = 'San Francisco',
            BillingCountry = 'United States',
            BillingCountryCode = 'US',
            AccountSource = 'Direct Traffic',
            BillingStreet = '123 Main Street',
            BillingPostalCode = '95911',
            Cin7_Username__c = 'Cin7-User-1727480561844'
        );
        insert acc;
    
        Incoming_Request__c req = new Incoming_Request__c();
        req.Source__c = 'Cin7 Core';
        req.Message__c = 'RenewalSubscription';
        req.Tenant_ID__c = tenantId;

        // Mock callout setup
        String getResponse = '{"Errors":["We have", "an error"],"Data":{"WebsiteURL":null,"Utm_Term":null,"Utm_Source":null,"Utm_Medium":null,"Utm_Content":null,"Utm_Campaign":null,"Users":[{"UserType":"owner","UserId":"cbecdcde-d39c-4620-9d84-1e57afe87e15","Email":"andrew.cooper@cin7.com","DisplayName":"Andrew Cooper"}],"TenantID":"f23932f1-54eb-4bfe-b929-b25fb029056d","SubscriptionName":"Pro 2024.01","SubscriptionExpirationDate":"2026-04-22T00:00:00","Subscribed":"2024-04-10T19:13:34.807Z","Status":"Client","Source":"Website (Direct)","AdditionalUsers": 10,"AdditionalUsersCost": 100.0000,"SKUs": [{"Name": "Standard Yearly 2021","Quantity": 2,"Total": 1200.0000,"Frequency": "Yearly"}],"SalesPersonEmail":"indeewari.k@dearsystems.com","SalesGMV6Months":437.0000,"SalesGMV3Months":437.0000,"SalesGMV12Months":437.0000,"SalesGMV":437.0000,"SalesCount":1,"Sales6MonthsCount":1,"Sales3MonthsCount":1,"Sales12MonthsCount":1,"ReferrerDomain":null,"ReferredByPartnerId":null,"ReferredByPartner":null,"PlanType":null,"PartnerType":null,"Organisation":"Andrew Trial","LastUpdatedDate":"2024-12-07T21:20:21.370Z","IsVarPartner":"false","IsOnboardingOptional":null,"IsNeedAttention":false,"IntegrationCount":0,"Email":"andrew.cooper@cin7.com","Discounts":[],"Discount":50.0000,"CustomerDomain":"cin7.com","CreateDate":"2023-07-14T15:55:51.453Z","Country":"United States","Contacts":[{"Phone":"90909099099","LastName":"Cooper","FirstName":"Andrew","Email":"andrew.cooper@cin7.com"}],"Cancelled":null,"AnniversaryDate":"2025-04-09T00:00:00"}}';
        MockHttpResponseHandler.SimpleMockResponse getResp = new MockHttpResponseHandler.SimpleMockResponse('GET', getResponse);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse('callout:Customer_Details', getResp);

        // Execute test
        Test.startTest();

        Test.setMock(HttpCalloutMock.class, mock);
        Database.executeBatch(new IncomingReqRenewalSubscriptionBatch(new List<Incoming_Request__c>{req}));

        Test.stopTest();
        
        // Assert
        List<API_Error_Log__c> log = [SELECT Id, Error_Message__c FROM API_Error_Log__c];
        System.assertEquals(1, [SELECT count() FROM API_Error_Log__c]);
        System.assertEquals('We have,an error', log[0].Error_Message__c);
    }
}