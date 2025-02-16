/**
 * @description       : 
 * @author            : AS | NuAge Experts
 * @group             : 
 * @last modified on  : 2023-05-11
 * @last modified by  : NuAge
**/
@isTest
public with sharing class AccountTriggerTest {
    @isTest
    public static void AccountTriggerTest() {
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.DEAR_Tenant_ID__c = 'b12294de-e20c-4dc6-8772-416a5c5f5246';
        acc.Type__c = 'Partner';
        
        insert acc;

        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        //successful PUTT which returns empty data in body and status code 200
        String putResponse = '';
        MockHttpResponseHandler.SimpleMockResponse putResp = new MockHttpResponseHandler.SimpleMockResponse('PUT', putResponse);
        mock.addResponse('callout:Partner_Activation', putResp);

        Test.startTest();
            Test.setMock(HttpCalloutMock.class, mock);
            acc.Partner_Type__c = 'Referral Partner';
            acc.Partner_Status__c = 'Active';
            update acc; 
        Test.stopTest();

    }

}