/**
 * @description       : 
 * @author            : AS | NuAge Experts
 * @group             : 
 * @last modified on  : 12-19-2023
 * @last modified by  : AS | NuAge Experts
**/

@isTest
public with sharing class LeadTriggerTest {
    @isTest
    public static void AccountProvisionsCalloutSuccess() {
        //assemble 
        Lead newLead = new Lead();
        String postResponse; 

        //assign
        newLead.FirstName = 'Test';
        newLead.LastName = 'Name';
        newLead.Company = 'Test Company';
        newLead.Email = 'test@email.com';
        newLead.Phone = '+971991369926';
        newLead.street = '';
        newLead.City = '';
        newLead.State = '';
        newLead.Country = 'United Arab Emirates';
        newLead.Timezone__c = 'Central Asia Standard Time (GMT+06:00)';
        newLead.Industry = 'AGP';
        newLead.Website = '';
        //newLead.Cin7_Demo_Expiry__c = System.today().addDays(-5);
        newLead.Core_Trial_Days__c = 14;
        newLead.Interested_in_demo__c = true;
        newLead.Free_Trial_Creation__c = true;

        //successful POST which returns data in body
        postResponse = '{"StatusCode":"organisation_created","Data":{"TenantID":"998a3592-3460-4882-b11d-47e9ef67a519","RequestID":"88220c39-c9da-48b8-b71e-5b8e8bd8c31f"}}';
        MockHttpResponseHandler.SimpleMockResponse postResp = new MockHttpResponseHandler.SimpleMockResponse('POST', postResponse);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse('callout:Account_Provisions', postResp);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, mock);
            insert newLead;
        Test.stopTest();

        //assert
        Lead insertedLead = [SELECT Name, Company, DEAR_Tenant_ID__c FROM Lead WHERE Id =: newLead.Id];
        // System.assertEquals('998a3592-3460-4882-b11d-47e9ef67a519', insertedLead.DEAR_Tenant_ID__c);
        // System.assertEquals('Test Name', insertedLead.Name);
        // System.assertEquals('Test Company', insertedLead.Company);
    }

    @isTest
    public static void PartnerAccountProvisionsCalloutSuccess() {
        //assemble 
        Lead newLead = new Lead();
        String postResponse;

        //assign
        newLead.FirstName = 'Test';
        newLead.LastName = 'Name';
        newLead.Company = 'Test Company';
        newLead.Email = 'test@email.com';
        newLead.Phone = '+971991369926';
        newLead.street = '';
        newLead.City = '';
        newLead.State = '';
        newLead.Country = 'United Arab Emirates';
        newLead.Timezone__c = 'Central Asia Standard Time (GMT+06:00)';
        newLead.Industry = 'AGP';
        newLead.Website = 'https://test.com';
        //newLead.Cin7_Demo_Expiry__c = System.today().addDays(5);
        newLead.Core_Trial_Days__c = 14;
        newLead.Interested_in_demo__c = true;
        newLead.Type__c = 'Partner';
        newLead.Core_Plan_Type__c = 'implementation';
        newLead.Core_Payment_Frequency__c = 'Quarterly';

        //successful POST which returns empty data in body and status code 200
        postResponse = '{"StatusCode": "partner_created","Data": {"TenantID": "bd54f725-2be7-4610-822c-87d9b2f8089f","RequestID": "44baabbb-740b-40c1-a119-250e045c56a4"}}';
        MockHttpResponseHandler.SimpleMockResponse putResp = new MockHttpResponseHandler.SimpleMockResponse('POST', postResponse);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse('callout:Partner_Account_Provisions', putResp);

        Test.startTest();
            Test.setMock(HttpCalloutMock.class, mock);
            insert newLead;
        Test.stopTest();

        //assert
        Lead insertedLead = [SELECT Name, Company, DEAR_Tenant_ID__c FROM Lead WHERE Id =: newLead.Id];
        // System.assertEquals('bd54f725-2be7-4610-822c-87d9b2f8089f', insertedLead.DEAR_Tenant_ID__c);
        // System.assertEquals('Test Name', insertedLead.Name);
    }

    @isTest
    public static void UpdatePartnerClientRelationship(){
        //assemble 
        Lead newLead = new Lead();
        Account acc = new Account();
        String postResponse;

        //assign
        newLead.FirstName = 'Test';
        newLead.LastName = 'Name';
        newLead.Company = 'Test Company';
        newLead.Email = 'test@email.com';
        newLead.Phone = '+971991369926';
        newLead.street = '';
        newLead.City = '';
        newLead.State = '';
        newLead.Country = 'United Arab Emirates';
        newLead.Timezone__c = 'Central Asia Standard Time (GMT+06:00)';
        newLead.Industry = 'AGP';
        newLead.Website = 'https://test.com';
        newLead.Core_Trial_Days__c = 14;
        newLead.Interested_in_demo__c = true;
        newLead.Type__c = 'Partner';
        newLead.Core_Plan_Type__c = 'implementation';
        newLead.Core_Payment_Frequency__c = 'Quarterly';
        newLead.DEAR_Tenant_ID__c = 'bd54f725-2be7-4610-822c-87d9b2f8089f';
        insert newLead;

        acc.Name = 'Test Account';
        acc.DEAR_Tenant_ID__c = '5aaf5df5-f822-49d6-814f-6f538cdbef02';
        insert acc;

        MockHttpResponseHandler mock = new MockHttpResponseHandler();

        postResponse = '';
        MockHttpResponseHandler.SimpleMockResponse postResp = new MockHttpResponseHandler.SimpleMockResponse('POST', postResponse);
        mock.addResponse('callout:Partner_Client_Relationship', postResp);

        String putResponse = '';
        MockHttpResponseHandler.SimpleMockResponse putResp = new MockHttpResponseHandler.SimpleMockResponse('PUT', putResponse);
        mock.addResponse('callout:Partner_Account_Provisions', putResp);

        Test.startTest();
            Test.setMock(HttpCalloutMock.class, mock);
            newLead.ImpartnerPRM__PartnerAccount__c = acc.Id;
            update newLead;
        Test.stopTest();
    }

    @isTest
    public static void UpdatePartnerAccountProvision(){
        //assemble 
        Lead newLead = new Lead();
 
        //assign
        newLead.FirstName = 'Test';
        newLead.LastName = 'Name';
        newLead.Company = 'Test Company';
        newLead.Email = 'test@email.com';
        newLead.Phone = '+971991369926';
        newLead.street = '';
        newLead.City = '';
        newLead.State = '';
        newLead.Country = 'United Arab Emirates';
        newLead.Timezone__c = 'Central Asia Standard Time (GMT+06:00)';
        newLead.Industry = 'AGP';
        newLead.Website = 'https://test.com';
        //newLead.Cin7_Demo_Expiry__c = System.today().addDays(5);
        newLead.Core_Trial_Days__c = 14;
        newLead.Interested_in_demo__c = true;
        newLead.Type__c = 'Partner';
        newLead.Core_Plan_Type__c = 'implementation';
        newLead.Core_Payment_Frequency__c = 'Quarterly';
        insert newLead;

        MockHttpResponseHandler mock = new MockHttpResponseHandler();

        String postResponse = '{"StatusCode": "partner_created","Data": {"TenantID": "bd54f725-2be7-4610-822c-87d9b2f8089f","RequestID": "44baabbb-740b-40c1-a119-250e045c56a4"}}';
        MockHttpResponseHandler.SimpleMockResponse postResp = new MockHttpResponseHandler.SimpleMockResponse('POST', postResponse);
        mock.addResponse('callout:Partner_Account_Provisions', postResp);

        String putResponse = '';
        MockHttpResponseHandler.SimpleMockResponse putResp = new MockHttpResponseHandler.SimpleMockResponse('PUT', putResponse);
        mock.addResponse('callout:Partner_Account_Provisions', putResp);

        Test.startTest();
            Test.setMock(HttpCalloutMock.class, mock);
            newLead.Company = 'Update Company Name';
            update newLead;
        Test.stopTest();
    }
}