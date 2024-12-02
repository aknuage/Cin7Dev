/**
 * @description       : 
 * @author            : AS | NuAge Experts
 * @group             : 
 * @last modified on  : 03-07-2024
 * @last modified by  : AS | NuAge Experts
**/
@isTest
public with sharing class OpportunityTriggerTest {

    // Test method used to test CREATE discount logic
    @isTest
    public static void approveDiscount() {
        //Assemble
        Account acc = new Account();
        acc.Name = 'Test Account';
        insert acc;

        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.StageName = 'New';
        opp.CloseDate = System.today().addDays(10);
        opp.AccountId = acc.Id;
        opp.DEAR_Tenant_ID__c = 'c067190b-9129-4adc-a118-39c40e1c47a0';
        opp.Amount = 100;
        opp.Discount_Expiration_Date__c = System.today().addDays(10);
        opp.Discount_Username__c = 'Andrew.Cooper@cin7.com';
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Core New Sales').getRecordTypeId();
        insert opp;

        // Verify the Opportunity is created without a discount
        Assert.areEqual(null, [SELECT Discount_Approval_Status__c FROM Opportunity WHERE Id =: opp.Id].Discount_Approval_Status__c);
        
        opp.Discount__c = 15;
        update opp;

        // Verify the Opportunity is created with a new discount applied
        Assert.areEqual('Not Submitted', [SELECT Discount_Approval_Status__c FROM Opportunity WHERE Id =: opp.Id].Discount_Approval_Status__c);

        //successful POST which returns empty data in body and status code 200
        String postResponse = '{"Data": {"DiscountID": "386fd18e-83c0-4428-aab6-66430ae5a622"}}';
        MockHttpResponseHandler.SimpleMockResponse postResp = new MockHttpResponseHandler.SimpleMockResponse('POST', postResponse);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse('callout:Discounts', postResp);

        Test.startTest();
            Test.setMock(HttpCalloutMock.class, mock);
            opp.Discount_Approval_Status__c = 'Approved';
            update opp;
        Test.stopTest();

        Assert.areEqual('386fd18e-83c0-4428-aab6-66430ae5a622', [Select Core_Discount_ID__c FROM Opportunity WHERE Id =: opp.Id].Core_Discount_ID__c);
        Assert.areEqual(15, [SELECT Discount__c FROM Opportunity WHERE Id =: opp.Id].Discount__c);
        Assert.areEqual('Approved', [SELECT Discount_Approval_Status__c FROM Opportunity WHERE Id =: opp.Id].Discount_Approval_Status__c);
    }

    // Test method used to test UPDATE discount logic
    @isTest
    public static void updateApprovedDiscount() {
        //Assemble
        Account acc = new Account();
        acc.Name = 'Test Account';
        insert acc;

        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.StageName = 'New';
        opp.CloseDate = System.today().addDays(-1);
        opp.AccountId = acc.Id;
        opp.DEAR_Tenant_ID__c = 'c067190b-9129-4adc-a118-39c40e1c47a0';
        opp.Core_Discount_ID__c = '386fd18e-83c0-4428-aab6-66430ae5a622';
        opp.Amount = 100;
        opp.Discount__c = 15;
        opp.Discount_Expiration_Date__c = System.today().addDays(10);
        opp.Discount_Username__c = 'Andrew.Cooper@cin7.com';
        opp.Subscription_Discount_Feature_Group__c = 'Users';
        insert opp;

        // Successful PUT which returns empty data in body and status code 200
        MockHttpResponseHandler.SimpleMockResponse postResp = new MockHttpResponseHandler.SimpleMockResponse('PUT', '');
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse('callout:Discounts', postResp);

        Test.startTest();
            Test.setMock(HttpCalloutMock.class, mock);
            opp.Discount_Approval_Status__c = 'Approved';
            update opp;
        Test.stopTest();

        Assert.areEqual('386fd18e-83c0-4428-aab6-66430ae5a622', [Select Core_Discount_ID__c FROM Opportunity WHERE Id =: opp.Id].Core_Discount_ID__c);
        Assert.areEqual(15, [SELECT Discount__c FROM Opportunity WHERE Id =: opp.Id].Discount__c);
        Assert.areEqual('Approved', [SELECT Discount_Approval_Status__c FROM Opportunity WHERE Id =: opp.Id].Discount_Approval_Status__c);
    }

    // Test method used to test invalid discount request because expiration date is in the past
    @isTest
    public static void rejectCreateDiscountInvalidDate() {
        //Assemble
        Account acc = new Account();
        acc.Name = 'Test Account';
        insert acc;

        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.StageName = 'New';
        opp.CloseDate = System.today().addDays(-1);
        opp.Discount_Expiration_Date__c = System.today().addDays(-1);
        opp.AccountId = acc.Id;
        opp.DEAR_Tenant_ID__c = 'c067190b-9129-4adc-a118-39c40e1c47a0';
        insert opp;

        // Successful POST which returns empty data in body and status code 200
        String postResponse = '{"Errors": ["ExpirationDate cannot be less then today (UTC)"]}';
        MockHttpResponseHandler.SimpleMockResponse postResp = new MockHttpResponseHandler.SimpleMockResponse('POST', postResponse);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse('callout:Discounts', postResp);

        Test.startTest();
            Test.setMock(HttpCalloutMock.class, mock);
            opp.Discount_Approval_Status__c = 'Approved';
            update opp;
        Test.stopTest();

        Assert.areEqual(1, [SELECT COUNT() FROM API_Error_Log__c]);
    }

    // Test method used to test invalid discount request because expiration date is in the past
    @isTest
    public static void rejectUpdateDiscountInvalidDate() {
        Account acc = new Account();
        acc.Name = 'Test Account';
        insert acc;

        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.StageName = 'New';
        opp.CloseDate = System.today().addDays(-1);
        opp.AccountId = acc.Id;
        opp.DEAR_Tenant_ID__c = 'c067190b-9129-4adc-a118-39c40e1c47a0';
        opp.Core_Discount_ID__c = '386fd18e-83c0-4428-aab6-66430ae5a622';
        opp.Amount = 100;
        opp.Discount__c = 15;
        opp.Discount_Expiration_Date__c = System.today().addDays(-1);
        opp.Discount_Username__c = 'Andrew.Cooper@cin7.com';
        opp.Subscription_Discount_Feature_Group__c = 'Users';
        insert opp;

        // Successful POST which returns empty data in body and status code 200
        String postResponse = '{"Errors": ["ExpirationDate cannot be less then today (UTC)"]}';
        MockHttpResponseHandler.SimpleMockResponse postResp = new MockHttpResponseHandler.SimpleMockResponse('PUT', postResponse,400);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse('callout:Discounts', postResp);

        Test.startTest();
            Test.setMock(HttpCalloutMock.class, mock);
            opp.Discount_Approval_Status__c = 'Approved';
            update opp;
        Test.stopTest();

        Assert.areEqual(1, [SELECT COUNT() FROM API_Error_Log__c]);
        Assert.areEqual('ExpirationDate cannot be less then today (UTC)', [SELECT Error_Message__c FROM API_Error_Log__c].Error_Message__c); 
    }

    // Test method used to test invalid discount request because required fields are missing
    @isTest
    public static void rejectDiscountMissingReqFields() {
        Account acc = new Account();
        acc.Name = 'Test Account';
        insert acc;

        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.StageName = 'New';
        opp.CloseDate = System.today().addDays(-1);
        opp.AccountId = acc.Id;
        opp.DEAR_Tenant_ID__c = 'c067190b-9129-4adc-a118-39c40e1c47a0';
        insert opp;

        // Successful POST which returns empty data in body and status code 200
        String postResponse = '{"Errors":["Required property Discount not provided.","Required property ExpirationDate not provided.","Required property Username not provided."]}';
        MockHttpResponseHandler.SimpleMockResponse postResp = new MockHttpResponseHandler.SimpleMockResponse('POST', postResponse);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse('callout:Discounts', postResp);

        Test.startTest();
            Test.setMock(HttpCalloutMock.class, mock);
            opp.Discount_Approval_Status__c = 'Approved';
            update opp;
        Test.stopTest();

        Assert.areEqual(1, [SELECT COUNT() FROM API_Error_Log__c]);
        Assert.areEqual('Required property Discount not provided.,Required property ExpirationDate not provided.,Required property Username not provided.', [SELECT Error_Message__c FROM API_Error_Log__c].Error_Message__c);
    }

    @isTest
    public static void addErrorMessageOnCreateTest(){
        //Assemble
        Account acc = new Account();
        acc.Name = 'Test Account';
        insert acc;

        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.StageName = 'New';
        opp.CloseDate = System.today().addDays(10);
        opp.AccountId = acc.Id;
        opp.DEAR_Tenant_ID__c = 'c067190b-9129-4adc-a118-39c40e1c47a0';
        opp.Amount = 100;
        opp.Discount_Expiration_Date__c = System.today().addDays(10);
        opp.Discount_Username__c = 'Andrew.Cooper@cin7.com';
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Core New Sales').getRecordTypeId();
        insert opp;

        // Setup test data
        // Create a unique UserName
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        // This code runs as the system user
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
         UserName=uniqueUserName);

        // Verify the Opportunity is created without a discount
        Assert.areEqual(null, [SELECT Discount_Approval_Status__c FROM Opportunity WHERE Id =: opp.Id].Discount_Approval_Status__c);
        
        opp.Discount__c = 15;
        update opp;

        // Verify the Opportunity is created with a new discount applied
        Assert.areEqual('Not Submitted', [SELECT Discount_Approval_Status__c FROM Opportunity WHERE Id =: opp.Id].Discount_Approval_Status__c);

        //successful POST which returns empty data in body and status code 200
        String postResponse = '{"Data": {"DiscountID": "386fd18e-83c0-4428-aab6-66430ae5a622"}}';
        MockHttpResponseHandler.SimpleMockResponse postResp = new MockHttpResponseHandler.SimpleMockResponse('POST', postResponse);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse('callout:Discounts', postResp);

        Test.startTest();
            Test.setMock(HttpCalloutMock.class, mock);
            try{
                System.runAs(u) {
                    opp.Discount_Approval_Status__c = 'Approved';
                    update opp;
                }
            }
            catch (Exception e) {        
                // assert
                System.debug(e.getMessage());
                Boolean expectedExceptionThrown =  (e.getMessage().contains('Only assigned approvers can approve opportunity discounts!')) ? true : false; 
                System.AssertEquals(true, expectedExceptionThrown, e.getMessage()); 
            }
        Test.stopTest();
    }

    @isTest
    static void testIsOnboardingOptionalHappy()
    {
        // Assemble
        Account a = new Account(Name = 'Test Acct');
        insert a; 

        Opportunity o = new Opportunity(
            Name = 'Test Opp', 
            StageName = 'New', 
            CloseDate = Date.today(), 
            Discount_Expiration_Date__c = Date.today(), 
            AccountId = a.Id, 
            DEAR_Tenant_Id__c = 'c067190b-9129-4adc-a118-39c40e1c47a0'
        );
        insert o;

        String responseBody = '{"Data":{"TenantID":"c067190b-9129-4adc-a118-39c40e1c47a0", "IsOnboardingOptional":true}}';
        MockHttpResponseHandler.SimpleMockResponse postResp = new MockHttpResponseHandler.SimpleMockResponse('POST', responseBody);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse('callout:Subscription_Settings', postResp);

        // Act
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, mock);
        o.IsOnboardingOptional__c = true;
        update o;
        Test.stopTest();
    
        // Assert
        Assert.areEqual(0, [SELECT Id FROM API_Error_Log__c].size());
    }

    @isTest
    static void testIsOnboardingOptionalTenantIdMismatch()
    {
        // Assemble
        Account a = new Account(Name = 'Test Acct');
        insert a; 

        Opportunity o = new Opportunity(
            Name = 'Test Opp', 
            StageName = 'New', 
            CloseDate = Date.today(), 
            Discount_Expiration_Date__c = Date.today(), 
            AccountId = a.Id, 
            DEAR_Tenant_Id__c = 'c067190b-9129-4adc-a118-39c40e1c47a0'
        );
        insert o;

        String responseBody = '{"Data":{"TenantID":"c067190c-9129-4adc-a118-39c40e1c47a0", "IsOnboardingOptional":true}}';
        MockHttpResponseHandler.SimpleMockResponse postResp = new MockHttpResponseHandler.SimpleMockResponse('POST', responseBody);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse('callout:Subscription_Settings', postResp);

        // Act
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, mock);
        o.IsOnboardingOptional__c = true;
        update o;
        Test.stopTest();
    
        // Assert
        List<API_Error_Log__c> assertErrors = [SELECT Id, Error_Message__c FROM API_Error_Log__c];
        Assert.areEqual(1, assertErrors.size());
        Assert.isTrue(assertErrors[0].Error_Message__c.contains('Tenant Id mismatch'));
    }

    @isTest
    static void testIsOnboardingOptionalResponseValueMismatch()
    {
        // Assemble
        Account a = new Account(Name = 'Test Acct');
        insert a; 

        Opportunity o = new Opportunity(
            Name = 'Test Opp', 
            StageName = 'New', 
            CloseDate = Date.today(), 
            Discount_Expiration_Date__c = Date.today(), 
            AccountId = a.Id, 
            DEAR_Tenant_Id__c = 'c067190b-9129-4adc-a118-39c40e1c47a0'
        );
        insert o;

        String responseBody = '{"Data":{"TenantID":"c067190b-9129-4adc-a118-39c40e1c47a0", "IsOnboardingOptional":false}}';
        MockHttpResponseHandler.SimpleMockResponse postResp = new MockHttpResponseHandler.SimpleMockResponse('POST', responseBody);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse('callout:Subscription_Settings', postResp);

        // Act
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, mock);
        o.IsOnboardingOptional__c = true;
        update o;
        Test.stopTest();
    
        // Assert
        List<API_Error_Log__c> assertErrors = [SELECT Id, Error_Message__c FROM API_Error_Log__c];
        Assert.areEqual(1, assertErrors.size());
        Assert.isTrue(assertErrors[0].Error_Message__c.contains('Response value does not match value sent'));
    }    
}