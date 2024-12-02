@isTest
public with sharing class NorthpassHelperTest 
{
    @isTest
    static void testNorthpassSubscriptionFromAccountCore()
    {
        // Assemble
        Id rtId = Schema.Sobjecttype.Account.getRecordTypeInfosByName().get('Customer Account').getRecordTypeId();

        Account a = new Account(RecordTypeId = rtId, Name = 'Cin7-107', Dear_Tenant_Id__c = 'Cin7-107');
        insert a;

        Contact c = new Contact(Contact_Type__c = 'Customer', FirstName = 'Testy', LastName = 'McTesterson', Email = 'mcTesty@gmail.com', AccountId = a.Id);
        insert c;

        MockHttpResponseHandler.SimpleMockResponse personResponse = new MockHttpResponseHandler.SimpleMockResponse('POST', successResponseSubscription, 201);
        MockHttpResponseHandler.SimpleMockResponse groupResponse = new MockHttpResponseHandler.SimpleMockResponse('POST', '{}', 204);
        
        MockHttpResponseHandler mock = new MockHttpResponseHandler();

        Map<String,String> groupIdByName = NorthpassHelper.GetGroupIdsByName();

        mock.addResponse('callout:Northpass_Person', personResponse);        
        mock.addResponse('callout:Northpass_Group' + '/' + groupIdByName.get('Core Customer') + '/relationships/people', groupResponse);        
        Test.setMock(HttpCalloutMock.class, mock);

        // Act
        Test.startTest();
        a.Reporting_Status__c = 'Onboarding';
        update a;
        Test.stopTest();
    
        // Assert no errors
        Assert.areEqual(0, [SELECT Error_Message__c from api_error_log__c].size());
    }

    @isTest
    static void testNorthpassSubscriptionFromContactCore()
    {
        // Assemble
        Id rtId = Schema.Sobjecttype.Account.getRecordTypeInfosByName().get('Customer Account').getRecordTypeId();

        Account a = new Account(RecordTypeId = rtId, Name = 'Cin7-107', Dear_Tenant_Id__c = 'Cin7-107');
        insert a;

        a.Reporting_Status__c = 'Onboarding';
        update a;

        Contact c = new Contact(Contact_Type__c = 'Customer', FirstName = 'Testy', LastName = 'McTesterson', Email = 'mcTesty@gmail.com', AccountId = a.Id);

        MockHttpResponseHandler.SimpleMockResponse personResponse = new MockHttpResponseHandler.SimpleMockResponse('POST', successResponseSubscription, 201);
        MockHttpResponseHandler.SimpleMockResponse groupResponse = new MockHttpResponseHandler.SimpleMockResponse('POST', '{}', 204);
        
        MockHttpResponseHandler mock = new MockHttpResponseHandler();

        Map<String,String> groupIdByName = NorthpassHelper.GetGroupIdsByName();

        mock.addResponse('callout:Northpass_Person', personResponse);        
        mock.addResponse('callout:Northpass_Group' + '/' + groupIdByName.get('Core Customer') + '/relationships/people', groupResponse);        
        Test.setMock(HttpCalloutMock.class, mock);

        // Act
        Test.startTest();
        insert c;
        Test.stopTest();
    
        // Assert no errors
        Assert.areEqual(0, [SELECT Error_Message__c from api_error_log__c].size());
    }    

    @isTest
    static void testNorthpassSubscriptionFromContactOmni()
    {
        // Assemble
        Id rtId = Schema.Sobjecttype.Account.getRecordTypeInfosByName().get('Customer Account').getRecordTypeId();

        Account a = new Account(RecordTypeId = rtId, Name = 'Cin7-107', Cin7_Username__c = 'Cin7-107');
        insert a;

        a.Reporting_Status__c = 'Onboarding';
        update a;

        Contact c = new Contact(Contact_Type__c = 'Customer', FirstName = 'Testy', LastName = 'McTesterson', Email = 'mcTesty@gmail.com', AccountId = a.Id);

        MockHttpResponseHandler.SimpleMockResponse personResponse = new MockHttpResponseHandler.SimpleMockResponse('POST', successResponseSubscription, 201);
        MockHttpResponseHandler.SimpleMockResponse groupResponse = new MockHttpResponseHandler.SimpleMockResponse('POST', '{}', 204);
        
        MockHttpResponseHandler mock = new MockHttpResponseHandler();

        Map<String,String> groupIdByName = NorthpassHelper.GetGroupIdsByName();

        mock.addResponse('callout:Northpass_Person', personResponse);        
        mock.addResponse('callout:Northpass_Group' + '/' + groupIdByName.get('Omni Customer') + '/relationships/people', groupResponse);        
        Test.setMock(HttpCalloutMock.class, mock);

        // Act
        Test.startTest();
        insert c;
        Test.stopTest();
    
        // Assert no errors
        Assert.areEqual(0, [SELECT Error_Message__c from api_error_log__c].size());
    }      

    @isTest
    static void testNorthpassPersonCalloutFail()
    {
        // Assemble
        Id rtId = Schema.Sobjecttype.Account.getRecordTypeInfosByName().get('Customer Account').getRecordTypeId();

        Account a = new Account(RecordTypeId = rtId, Name = 'Cin7-107', Cin7_Username__c = 'Cin7-107');
        insert a;

        a.Reporting_Status__c = 'Onboarding';
        update a;

        Contact c = new Contact(Contact_Type__c = 'Customer', FirstName = 'Testy', LastName = 'McTesterson', Email = 'mcTesty@gmail.com', AccountId = a.Id);

        MockHttpResponseHandler.SimpleMockResponse personResponse = new MockHttpResponseHandler.SimpleMockResponse('POST', successResponseSubscription, 400);
        MockHttpResponseHandler.SimpleMockResponse groupResponse = new MockHttpResponseHandler.SimpleMockResponse('POST', '{}', 204);
        
        MockHttpResponseHandler mock = new MockHttpResponseHandler();

        Map<String,String> groupIdByName = NorthpassHelper.GetGroupIdsByName();

        mock.addResponse('callout:Northpass_Person', personResponse);        
        mock.addResponse('callout:Northpass_Group' + '/' + groupIdByName.get('Omni Customer') + '/relationships/people', groupResponse);        
        Test.setMock(HttpCalloutMock.class, mock);

        // Act
        Test.startTest();
        insert c;
        Test.stopTest();
    
        // Assert one error
        Assert.areEqual(1, [SELECT Error_Message__c from api_error_log__c].size());
    }      
    
    @isTest
    static void testNorthpassGroupCalloutFail()
    {
        // Assemble
        Id rtId = Schema.Sobjecttype.Account.getRecordTypeInfosByName().get('Customer Account').getRecordTypeId();

        Account a = new Account(RecordTypeId = rtId, Name = 'Cin7-107', Cin7_Username__c = 'Cin7-107');
        insert a;

        a.Reporting_Status__c = 'Onboarding';
        update a;

        Contact c = new Contact(Contact_Type__c = 'Customer', FirstName = 'Testy', LastName = 'McTesterson', Email = 'mcTesty@gmail.com', AccountId = a.Id);

        MockHttpResponseHandler.SimpleMockResponse personResponse = new MockHttpResponseHandler.SimpleMockResponse('POST', successResponseSubscription, 201);
        MockHttpResponseHandler.SimpleMockResponse groupResponse = new MockHttpResponseHandler.SimpleMockResponse('POST', '{}', 400);
        
        MockHttpResponseHandler mock = new MockHttpResponseHandler();

        Map<String,String> groupIdByName = NorthpassHelper.GetGroupIdsByName();

        mock.addResponse('callout:Northpass_Person', personResponse);        
        mock.addResponse('callout:Northpass_Group' + '/' + groupIdByName.get('Omni Customer') + '/relationships/people', groupResponse);        
        Test.setMock(HttpCalloutMock.class, mock);

        // Act
        Test.startTest();
        insert c;
        Test.stopTest();
    
        // Assert one error
        Assert.areEqual(1, [SELECT Error_Message__c from api_error_log__c].size());
    }       

    @isTest
    static void testNorthpassNullSubscription()
    {
        // Assemble
        
        // Act
        Test.startTest();
        CalloutHelper.CreateNorthPassUserAndAssignToGroup(null);
        Test.stopTest();

        // Assert
        Assert.areEqual(1, [SELECT Error_Message__c from api_error_log__c].size());
    }

    @isTest
    static void testEmptySubscriptionList() {
        // Act
        Test.startTest();
        CalloutHelper.CreateNorthPassUserAndAssignToGroup(new List<NorthpassSubscriptionWrapper>());
        Test.stopTest();
    
        // Assert that an error log was created due to the empty subscription list
        List<API_Error_Log__c> logs = [SELECT Error_Message__c FROM API_Error_Log__c];
        System.assertEquals(1, logs.size(), 'An error log should be created for an empty subscription list');
        System.assertEquals('Cannot create Northpass users because subscription list is null or empty', logs[0].Error_Message__c);
    }
    
    @isTest
    static void testSendIsOnboardingOptionalSuccessfulCallout() {
        // Mock successful response
        MockHttpCallout mock = new MockHttpCallout(200, '{"Data": {"TenantID": "tenant123", "IsOnboardingOptional": true}}');
        Test.setMock(HttpCalloutMock.class, mock);

        // Act
        Test.startTest();
        CalloutHelper.SendIsOnboardingOptional('tenant123', true);
        Test.stopTest();

        // Assert: No error log should be created for a successful callout
        List<API_Error_Log__c> errorLogs = [SELECT Id FROM API_Error_Log__c];
        System.assertEquals(0, errorLogs.size(), 'No error logs should be created.');
    }

    @isTest
    static void testSendIsOnboardingOptionalTenantIdMismatch() {
        // Mock response with mismatched tenant ID
        MockHttpCallout mock = new MockHttpCallout(200, '{"Data": {"TenantID": "tenant456", "IsOnboardingOptional": true}}');
        Test.setMock(HttpCalloutMock.class, mock);

        // Act
        Test.startTest();
        CalloutHelper.SendIsOnboardingOptional('tenant123', true);
        Test.stopTest();

        // Assert: An error log should be created due to tenant ID mismatch
        List<API_Error_Log__c> errorLogs = [SELECT Error_Message__c FROM API_Error_Log__c];
        System.assertEquals(1, errorLogs.size(), 'An error log should be created for tenant ID mismatch.');
        System.assert(errorLogs[0].Error_Message__c.contains('Tenant Id mismatch'), 'The error message should indicate a tenant ID mismatch.');
    }

    @isTest
    static void testSendIsOnboardingOptionalNon200Response() {
        // Mock response with a non-200 status code
        MockHttpCallout mock = new MockHttpCallout(400, '{"error": "Bad Request"}');
        Test.setMock(HttpCalloutMock.class, mock);

        // Act
        Test.startTest();
        CalloutHelper.SendIsOnboardingOptional('tenant123', true);
        Test.stopTest();

        // Assert: An error log should be created due to non-200 status code
        List<API_Error_Log__c> errorLogs = [SELECT Error_Message__c, Http_Status_Code__c FROM API_Error_Log__c];
        System.assertEquals(1, errorLogs.size(), 'An error log should be created for a non-200 response.');
        System.assertEquals(400, errorLogs[0].Http_Status_Code__c, 'The HTTP status code should be logged.');
        System.assert(errorLogs[0].Error_Message__c.contains('Unexpected response to SubscriptionSettings update'), 'The error message should indicate an unexpected response.');
    }

    @isTest
    static void testSendIsOnboardingOptionalExceptionThrown() {
        // Mock an exception scenario by using an incorrect endpoint or a fake mock.
        MockHttpCallout mock = new MockHttpCallout(500, '{"error": "Internal Server Error"}');
        Test.setMock(HttpCalloutMock.class, mock);

        // Act
        Test.startTest();
        CalloutHelper.SendIsOnboardingOptional('tenant123', true);
        Test.stopTest();

        // Assert: An error log should be created due to the exception
        List<API_Error_Log__c> errorLogs = [SELECT Error_Message__c FROM API_Error_Log__c];
        System.assertEquals(1, errorLogs.size(), 'An error log should be created when an exception is thrown.');
    }


    private static String successResponseSubscription = 
        '{' +
            '"data": {' +
                '"type": "people",' +
                '"id": "ad7268ca-8337-4e9a-9cec-53654068bbbc",' +
                '"attributes": {' +
                '"created_at": "2024-07-23T14:22:16Z",' +
                '"custom_avatar_url": "https://secure.gravatar.com/avatar/c64acb178dddc1239af41a7bc63f2029?d=identicon&s=200",' +
                '"disabled": false,' +
                '"email": "nktest23-1@gmail.com",' +
                '"first_name": "Nathan",' +
                '"full_name": "Nathan Test23-1",' +
                '"last_name": "Test23-1",' +
                '"name": "Nathan Test23-1",' +
                '"registration_status": "not_activated",' +
                '"unsubscribed": false,' +
                '"updated_at": "2024-07-23T14:22:16Z",' +
                '"invite_token": "66khqpge9_xc325ac0hbdyg2d"' +
                '},' +
                '"links": {' +
                '"self": {' +
                    '"href": "https://api.northpass.com/v2/people/ad7268ca-8337-4e9a-9cec-53654068bbbc",' +
                    '"methods": [' +
                    '"get",' +
                    '"delete"' +
                    ']' +
                '},' +
                '"teaching": {' +
                    '"href": "https://app.northpass.com/people/ad7268ca-8337-4e9a-9cec-53654068bbbc",' +
                    '"methods": [' +
                    '"get",' +
                    '"patch"' +
                    ']' +
                '},' +
                '"resend-invite": {' +
                    '"href": "https://api.northpass.com/v1/people/ad7268ca-8337-4e9a-9cec-53654068bbbc/resend-invite",' +
                    '"methods": [' +
                    '"post"' +
                    ']' +
                '},' +
                '"deactivate": {' +
                    '"href": "https://api.northpass.com/v2/people/ad7268ca-8337-4e9a-9cec-53654068bbbc/deactivations",' +
                    '"methods": [' +
                    '"post"' +
                    ']' +
                '}' +
                '},' +
                '"relationships": {' +
                '"partnerships": {' +
                    '"data": [' +
                    '{' +
                        '"type": "partnerships",' +
                        '"id": "6edad5d9-7244-4409-9fcc-73d6edef0143"' +
                    '}' +
                    ']' +
                '},' +
                '"school": {' +
                    '"data": {' +
                    '"type": "schools",' +
                    '"id": "57e487d9-f38f-4c5c-931d-559bf9ca52c8"' +
                    '}' +
                '},' +
                '"groups": {' +
                    '"data": []' +
                '}' +
                '}' +
            '}' +
        '}';

}