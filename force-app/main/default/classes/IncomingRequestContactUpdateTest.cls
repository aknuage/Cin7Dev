@isTest
public with sharing class IncomingRequestContactUpdateTest {
    @TestSetup
    static void makeData(){
        String tenantId = '231013f4-48c0-4cfd-9e53-3bc461d42d64';
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.DEAR_Tenant_ID__c = tenantId;
        insert acc;

        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(Id = pricebookId,IsActive = true);
        update standardPricebook;

        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.AccountId = acc.Id;
        opp.CloseDate = System.today();
        opp.StageName = 'Closed Won';
        opp.DEAR_Tenant_ID__c = tenantId;
        opp.Pricebook2Id = standardPricebook.Id;
        opp.Is_Active__c = true;
        opp.Amount = 1000;
        insert opp;
    }

    // @description: Test method used to test when Contact is found in the Get Customer details endpoint that is in SFDC and values on existing contact changes.
    // @expected result: Update the contact record and mark as active user on the account. Insert new Contact, Jane Doe.
    @isTest
    public static void ContactUpdateHappyPath_Test()
    {
        // Assemble
        String tenantId = '231013f4-48c0-4cfd-9e53-3bc461d42d64';

        Contact con = new Contact();
        con.FirstName = 'John';
        con.LastName = 'D';
        con.Email = 'test@email.com';
        con.Cin7_Core_User_Id__c = 'cbecdcde-d39c-4620-9d84-1e57afe87e15';
        con.AccountId = [SELECT Id FROM Account WHERE Name = 'Test Account'].Id;
        insert con;

        Incoming_Request__c req = new Incoming_Request__c();
        req.Message__c = 'ContactUpdate';
        req.Tenant_ID__c = tenantId;
    
        String getResponse = '{"Data":{"Subscribed":null,"Cancelled":null,"SubscriptionName":"Trial","SubscriptionExpirationDate":"2024-03-01T00:00:00","Source":"Website (Direct)","ReferredByPartner":null,"ReferredByPartnerId":null,"PlanType":null,"IsNeedAttention":false,"CustomerDomain":"usertest.com","Utm_Campaign":null,"Utm_Source":null,"Utm_Medium":null,"Utm_Term":null,"Utm_Content":null,"PartnerType":null,"IsVarPartner":null,"ReferrerDomain":null,"AdditionalUsers":0,"AdditionalUsersCost":0.0000,"Discount":0.0000,"Status":"Trial","AnniversaryDate":null,"IntegrationCount":0,"SalesCount":15,"Sales3MonthsCount":0,"Sales6MonthsCount":0,"Sales12MonthsCount":0,"SalesGMV":30351.3500,"SalesGMV3Months":0.0000,"SalesGMV6Months":0.0000,"SalesGMV12Months":0.0000,"SKUs":[],"Users":[{"UserId":"cbecdcde-d39c-4620-9d84-1e57afe87e15","Email":"john@doe.com","UserType":"user","DisplayName":"John Doe"},{"UserId":"b587c24d-b53b-4f96-b837-48580a1a39c4","Email":"jane@example.com","UserType":"owner","DisplayName":"Jane Doe"}],"Discounts":[],"Country":"United States","CreateDate":"2024-02-16T18:06:04.773","Email":"actester@usertest.com","LastUpdatedDate":"2024-02-27T21:20:14.363","Organisation":"UserTestAcct","SalesPersonEmail":"am.siddiquie@dearsystems.com","TenantID":"231013f4-48c0-4cfd-9e53-3bc461d42d64","WebsiteURL":null,"Contacts":[{"Phone":"8888888888888","Email":"actester@usertest.com","FirstName":"Andrew","LastName":"Tester"}]}}';
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
        new IncomingRequestContactUpdate(new List<Incoming_Request__c>{req});

        Test.stopTest();

        // Post-assert
        Assert.areEqual(2,[SELECT COUNT() FROM Contact]);
        Assert.areEqual(1, [SELECT COUNT() FROM Contact WHERE Name = 'John Doe']);
        Assert.areEqual(1, [SELECT COUNT() FROM Contact WHERE Name = 'Jane Doe']);
        // Assert.areEqual(2, [SELECT COUNT() FROM Opportunity]);
    }

    
    // @description: Test method used to check that API Error Logs are properly generated when Tenant ID is not present in JSON response.
    // @expected result: API Error Log created during attempt to insert Incoming Request.
    @isTest
    public static void ContactUpdateNoTenantIdFailure_Test()
    {
        // Assemble
        String tenantId = '231013f4-48c0-4cfd-9e53-3bc461d42d64';

        Contact con = new Contact();
        con.FirstName = 'John';
        con.LastName = 'D';
        con.Email = 'test@email.com';
        con.Cin7_Core_User_Id__c = 'cbecdcde-d39c-4620-9d84-1e57afe87e15';
        con.AccountId = [SELECT Id FROM Account WHERE Name = 'Test Account'].Id;
        insert con;

        Incoming_Request__c req = new Incoming_Request__c();
        req.Message__c = 'ContactUpdate';
        req.Tenant_ID__c = tenantId;
        // Exclude Tenant ID from response, which should generate API Error Log
        String getResponse = '{"Data":{"Subscribed":null,"Cancelled":null,"SubscriptionName":"Trial","SubscriptionExpirationDate":"2024-03-01T00:00:00","Source":"Website (Direct)","ReferredByPartner":null,"ReferredByPartnerId":null,"PlanType":null,"IsNeedAttention":false,"CustomerDomain":"usertest.com","Utm_Campaign":null,"Utm_Source":null,"Utm_Medium":null,"Utm_Term":null,"Utm_Content":null,"PartnerType":null,"IsVarPartner":null,"ReferrerDomain":null,"AdditionalUsers":0,"AdditionalUsersCost":0.0000,"Discount":0.0000,"Status":"Trial","AnniversaryDate":null,"IntegrationCount":0,"SalesCount":15,"Sales3MonthsCount":0,"Sales6MonthsCount":0,"Sales12MonthsCount":0,"SalesGMV":30351.3500,"SalesGMV3Months":0.0000,"SalesGMV6Months":0.0000,"SalesGMV12Months":0.0000,"SKUs":[],"Users":[{"UserId":"cbecdcde-d39c-4620-9d84-1e57afe87e15","Email":"","UserType":"user","DisplayName":"John Doe"},{"UserId":"b587c24d-b53b-4f96-b837-48580a1a39c4","Email":"jane@example.com","UserType":"owner","DisplayName":"Jane Doe"}],"Discounts":[],"Country":"United States","CreateDate":"2024-02-16T18:06:04.773","Email":"actester@usertest.com","LastUpdatedDate":"2024-02-27T21:20:14.363","Organisation":"UserTestAcct","SalesPersonEmail":"am.siddiquie@dearsystems.com","TenantID":"","WebsiteURL":null,"Contacts":[{"Phone":"8888888888888","Email":"actester@usertest.com","FirstName":"Andrew","LastName":"Tester"}]}}';
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
        new IncomingRequestContactUpdate(new List<Incoming_Request__c>{req});

        Test.stopTest();

        List<API_Error_Log__c> errorLogs = [SELECT Error_Message__c, Incoming_Request_Tenant_ID__c, HTTP_Status_Code__c, Status__c FROM API_Error_Log__c];
        
        System.assertEquals(1, errorLogs.size());
        System.assert(errorLogs[0].Error_Message__c.contains('Error processing ContactUpdate: List has no rows for assignment to SObject'));
        System.assertEquals(tenantId, errorLogs[0].Incoming_Request_Tenant_ID__c);
    }

    // @description: Test method used to check that API Error Logs are properly generated when "Errors" is not null in JSON Response.
    // @expected result: API Error Log created during attempt to insert Incoming Request.
    @isTest
    public static void ContactUpdateWithErrorResponse_Test()
    {
        // Assemble
        String tenantId = '231013f4-48c0-4cfd-9e53-3bc461d42d64';

        Contact con = new Contact();
        con.FirstName = 'John';
        con.LastName = 'D';
        con.Email = 'test@email.com';
        con.Cin7_Core_User_Id__c = 'cbecdcde-d39c-4620-9d84-1e57afe87e15';
        con.AccountId = [SELECT Id FROM Account WHERE Name = 'Test Account'].Id;
        insert con;

        Incoming_Request__c req = new Incoming_Request__c();
        req.Message__c = 'ContactUpdate';
        req.Tenant_ID__c = tenantId;

        // Exclude Tenant ID from response, which should generate API Error Log
        String getResponse = '{"Errors": ["Force Generated Error", "Error Retrieving Response"], "Data":{"Subscribed":null,"Cancelled":null,"SubscriptionName":"Trial","SubscriptionExpirationDate":"2024-03-01T00:00:00","Source":"Website (Direct)","ReferredByPartner":null,"ReferredByPartnerId":null,"PlanType":null,"IsNeedAttention":false,"CustomerDomain":"usertest.com","Utm_Campaign":null,"Utm_Source":null,"Utm_Medium":null,"Utm_Term":null,"Utm_Content":null,"PartnerType":null,"IsVarPartner":null,"ReferrerDomain":null,"AdditionalUsers":0,"AdditionalUsersCost":0.0000,"Discount":0.0000,"Status":"Trial","AnniversaryDate":null,"IntegrationCount":0,"SalesCount":15,"Sales3MonthsCount":0,"Sales6MonthsCount":0,"Sales12MonthsCount":0,"SalesGMV":30351.3500,"SalesGMV3Months":0.0000,"SalesGMV6Months":0.0000,"SalesGMV12Months":0.0000,"SKUs":[],"Users":[{"UserId":"cbecdcde-d39c-4620-9d84-1e57afe87e15","Email":"","UserType":"user","DisplayName":"John Doe"},{"UserId":"b587c24d-b53b-4f96-b837-48580a1a39c4","Email":"jane@example.com","UserType":"owner","DisplayName":"Jane Doe"}],"Discounts":[],"Country":"United States","CreateDate":"2024-02-16T18:06:04.773","Email":"actester@usertest.com","LastUpdatedDate":"2024-02-27T21:20:14.363","Organisation":"UserTestAcct","SalesPersonEmail":"am.siddiquie@dearsystems.com","TenantID":"","WebsiteURL":null,"Contacts":[{"Phone":"8888888888888","Email":"actester@usertest.com","FirstName":"Andrew","LastName":"Tester"}]}}';
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
        new IncomingRequestContactUpdate(new List<Incoming_Request__c>{req});

        Test.stopTest();

        List<API_Error_Log__c> errorLogs = [SELECT Error_Message__c, Incoming_Request_Tenant_ID__c, HTTP_Status_Code__c, Status__c FROM API_Error_Log__c];
        
        System.assertEquals(1, errorLogs.size());
        System.assertEquals(200, errorLogs[0].HTTP_Status_Code__c);
        System.assertEquals(null, errorLogs[0].Incoming_Request_Tenant_ID__c);
        System.assertEquals(errorLogs[0].Error_Message__c, 'Force Generated Error,Error Retrieving Response');
    }

    // @description: Test method used to test when Contact exists in Salesforce but not related to proper account.
    // @expected result: Avoid creating duplicate Contacts by creating a new Account Contact Relationship with the already existing Contact in SFDC.
    @isTest
    public static void AvoidDuplicateContacts_Test(){
        // assemble
        String tenantId = '231013f4-48c0-4cfd-9e53-3bc461d42d64';
        Account a = new Account();
        a.Name = 'Test New Account';
        insert a;

        Contact con = new Contact();
        con.LastName = 'TESTER';
        con.Cin7_Core_User_Id__c = 'cbecdcde-d39c-4620-9d84-1e57afe87e15';
        con.AccountId = a.Id;
        insert con; 

        Incoming_Request__c req = new Incoming_Request__c();
        req.Message__c = 'ContactUpdate';
        req.Tenant_ID__c = tenantId;
    
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
            new IncomingRequestContactUpdate(new List<Incoming_Request__c>{req});
        Test.stopTest();
        
        Id accountID = [SELECT Id FROM Account WHERE DEAR_Tenant_ID__c = :tenantId].Id;

        Assert.areEqual(2, [SELECT COUNT() FROM Contact]);
        Assert.areEqual(3, [SELECT COUNT() FROM AccountContactRelation]);
        Assert.areEqual(true, [SELECT isActive FROM AccountContactRelation WHERE ContactId =: con.Id AND AccountId =: a.Id].isActive);
        Assert.areEqual(true, [SELECT isActive FROM AccountContactRelation WHERE ContactId =: con.Id AND AccountId =: accountID].isActive);
    }
}