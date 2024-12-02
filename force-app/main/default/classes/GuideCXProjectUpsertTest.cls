/* Test methods for GuideCXProjectUpsert class
 * Micado 2022
 * 
 * Change Log
 * 08/07/22 Initial version
 * 12/07/22 Added Notes test
 */
@isTest
private class GuideCXProjectUpsertTest {
	@testSetup
    static void setup() {
        
        Account newAccount = new Account();
        newAccount.Name = 'GuideCX TEST Account AA';
        newAccount.Website = 'https://example.com';
        newAccount.Sales_Region__c = 'UK';
        insert newAccount;

		Contact newContact = new Contact();
		newContact.FirstName = 'GuideCX';
		newContact.LastName = 'TEST AA';
        
        Opportunity newOpp = new Opportunity();
        newOpp.Name = 'GuideCX TEST Opportunity AA;';
        newOpp.Amount = 20;
        newOpp.CloseDate = system.today().addDays(2);
        newOpp.AccountId = newAccount.Id;
        newOpp.Amount_Onboarding_Fee__c = 5;
        newOpp.LeadSource = 'Direct Traffic';
		newOpp.StageName = 'New';
        newOpp.number_of_3PLs__c = 3;
		newOpp.X3PL_provider__c = '3ovo';
        newOpp.Est_Onboarding_Timeframe__c = '4-6 Weeks';
		newOpp.SalesLoft1__Primary_Contact__c = newContact.Id;
		newOpp.SalesLoft1__Most_Recent_Cadence_Name__c = 'Stood Up on Meeting / Get Back in Touch';
		newOpp.SalesLoft1__Most_Recent_Last_Completed_Step__c = 2;
        insert newOpp;

		newOpp.StageName = 'Closed Won';
		update newOpp;
        
        // The last update does not seem to trigger the project creation when in test mode, so creating it manually
        beynd__BeyndProject__c newProject = new beynd__BeyndProject__c();
        newProject.Name = 'GuideCX TEST Project AA';
        newProject.beynd__BeyndProjectURL__c = 'https://app.guidecx.com/app/projects/123';
        newProject.beynd__ProjectStatus__c = 'Pending';
        newProject.beynd__Source_Object__c = newOpp.Id;
        insert newProject;

    }
    
	@isTest
    static void calloutTest() {
        String projectId = '123';
        String projectEndpoint = 'https://api.guidecx.com/api/v1/projects/' + projectId;
        String updateCustomFieldsEndpoint = 'https://api.guidecx.com/api/v1/projects/' + projectId;
        String addCustomFieldsEndpoint = 'https://api.guidecx.com/api/v1/projects/' + projectId + '/custom-fields';
        String addNotesEndpoint = 'https://api.guidecx.com/api/v1/projects/' + projectId + '/notes';
        String projectResponse = '{"id":"123","customFields":[{"value":"Unknown","id":"1","name":"Sales Region"},{"value":"0","id":"2","name":"Number of 3PLs"},{"value":"0","id":"3","name":"Number of EDIs"},{"value":"30.00","id":"4","name":"Amount - Onboarding Fee"}]}';
        String updateCustomFieldsResponse = '{"id":"e3054fce-a949-4069-9f7e-948242e0cd6d","activeMilestones":[],"apiProjectId":"123","cashValue":0,"createdAt":"2022-07-01T11:46:36.501Z","endOn":"2022-06-30","externalId":null,"name":"GuideCX Test 2022-07-01 B","startOn":"2022-06-30","updatedAt":"2022-07-01T11:46:37.039Z","projectManager":{"id":"240b2f53-c4a7-44a6-850c-1879b95b83ba","firstName":"Micado","lastName":"User","email":"cin7+salesforce_prod@micado.ai"},"customer":{"name":"Example","domain":"example.com"},"status":"On Time","tags":[],"doneAt":null,"projectedEndDate":null,"completedAt":null,"referringObjectId":"0062u00000FJ9NhAAL","integrationReferenceId":"a032u00000BV7pNAAT","attachments":[],"templates":[{"id":"d598861f-8e08-45a8-afa8-0e917563bdd5","name":"Project Plan","sku":null,"description":null,"createdAt":"2022-07-01T11:46:36.516Z","updatedAt":"2022-07-01T11:46:37.853Z"}],"projectInfoFields":[{"value":"null","id":"7f110c06-1b79-4688-98f6-266029d4cf90","name":"Project Complexity","internalOnly":true},{"value":"null","id":"2f2e00a4-7056-4f2e-8d18-28ea56204daf","name":"Est Implementation Timeframe","internalOnly":true},{"value":"0","id":"d1798dbd-cb78-46bf-b08d-4a2511f103dc","name":"Number of 3PLs","internalOnly":true},{"value":"0","id":"c9d0208e-92ac-4b10-8bb4-a9f8788bfbcb","name":"Number of EDIs","internalOnly":true},{"value":"Unknown","id":"e8e5d521-0df6-4b87-8dcb-14d033256558","name":"Sales Region","internalOnly":true},{"value":"30.00","id":"318e955e-3380-4593-b217-e4e90a1ffdaa","name":"Amount - Onboarding Fee","internalOnly":true},{"value":"null","id":"f781682b-cd28-4480-ae0e-8946220c402e","name":"Referrer Account (CI Partner)","internalOnly":true}],"customFields":[{"value":"null","id":"7f110c06-1b79-4688-98f6-266029d4cf90","name":"Project Complexity","internalOnly":true},{"value":"null","id":"2f2e00a4-7056-4f2e-8d18-28ea56204daf","name":"Est Implementation Timeframe","internalOnly":true},{"value":"0","id":"d1798dbd-cb78-46bf-b08d-4a2511f103dc","name":"Number of 3PLs","internalOnly":true},{"value":"0","id":"c9d0208e-92ac-4b10-8bb4-a9f8788bfbcb","name":"Number of EDIs","internalOnly":true},{"value":"Unknown","id":"e8e5d521-0df6-4b87-8dcb-14d033256558","name":"Sales Region","internalOnly":true},{"value":"30.00","id":"318e955e-3380-4593-b217-e4e90a1ffdaa","name":"Amount - Onboarding Fee","internalOnly":true},{"value":"null","id":"f781682b-cd28-4480-ae0e-8946220c402e","name":"Referrer Account (CI Partner)","internalOnly":true}],"team":[{"id":"240b2f53-c4a7-44a6-850c-1879b95b83ba","firstName":"Micado","lastName":"User","email":"cin7+salesforce_prod@micado.ai","phone":"","userContext":"provider"}],"taskSummary":{"total":0,"done":0,"inProgress":0,"notStarted":0,"overdue":0,"signOff":0,"stuck":0},"internalTaskSummary":{"total":0,"done":0,"inProgress":0,"notStarted":0,"overdue":0,"signOff":0,"stuck":0},"customerTaskSummary":{"total":0,"done":0,"inProgress":0,"notStarted":0,"overdue":0,"signOff":0,"stuck":0},"thirdPartyTaskSummary":{"total":0,"done":0,"inProgress":0,"notStarted":0,"overdue":0,"signOff":0,"stuck":0},"hours":{"summary":{"estimated":0.0,"actual":0.0},"internal":{"estimated":0.0,"actual":0.0},"customer":{"estimated":0.0,"actual":0.0},"thirdParty":{"estimated":0.0,"actual":0.0}},"creationStatus":"created"}';
        String addCustomFieldsResponse = '{"value":"null","id":"7f110c06-1b79-4688-98f6-266029d4cf90","name":"Project Complexity","internalOnly":true}';
        String addNotesResponse = '{}';
        String projectSendType = 'GET';
        String updateCustomFieldsSendType = 'PATCH';
        String addCustomFieldsSendType = 'POST';    
        String addNotesSendType = 'POST'; 
        
        MockHttpResponseHandler.SimpleMockResponse getProjectResp = new MockHttpResponseHandler.SimpleMockResponse(projectSendType, projectResponse);
        MockHttpResponseHandler.SimpleMockResponse getUpdateCustomFieldsResp = new MockHttpResponseHandler.SimpleMockResponse(updateCustomFieldsSendType, updateCustomFieldsResponse);
        MockHttpResponseHandler.SimpleMockResponse getAddCustomFieldsResp = new MockHttpResponseHandler.SimpleMockResponse(addCustomFieldsSendType, addCustomFieldsResponse);
        MockHttpResponseHandler.SimpleMockResponse getAddNotesResp = new MockHttpResponseHandler.SimpleMockResponse(addNotesSendType, addNotesResponse);
        
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse(projectEndpoint, getProjectResp);
        mock.addResponse(updateCustomFieldsEndpoint, getUpdateCustomFieldsResp);
        mock.addResponse(addCustomFieldsEndpoint, getAddCustomFieldsResp);
        mock.addResponse(addNotesEndpoint, getAddNotesResp);
    
        //can set other status codes to test failures if desired, e.g.
        //String errorEndpoint = testEndpoint + '/error';
        //MockHttpResponseHandler.SimpleMockResponse errResp = new MockHttpResponseHandler.SimpleMockResponse('GET', null);
        //errResp.statusCode = 500;

        Test.setMock(HttpCalloutMock.class, mock);
        
        Test.startTest();
        beynd__BeyndProject__c projectRecord = [SELECT Id, Name, beynd__Source_Object__c from beynd__BeyndProject__c Order By CreatedDate desc LIMIT 1];
        Opportunity oppRecord = [SELECT Id FROM Opportunity Order By CreatedDate desc LIMIT 1];
        
        // Testing end to end, but can't return since future jobs don't support return
        GuideCXProjectUpsert.GuideCXProjectUpsertVar customClass = new GuideCXProjectUpsert.GuideCXProjectUpsertVar();
        customClass.salesforceId = projectRecord.Id;
        customClass.actionType = 'upsert';
        GuideCXProjectUpsert.updateGuideCX(new List<GuideCXProjectUpsert.GuideCXProjectUpsertVar>{customClass});
        
        // Run the underlying non-future method
        Integer result = GuideCXProjectUpsert.updateGuideCXNonFuture(projectRecord.Id, 'upsert');
        System.assertEquals(0, result);
        
        Test.stopTest();
    
    }
        
	@isTest
    static void testGuideCXCode() {        
		// Testing the GuideCX code, don't want to change the code itself since I am not sure what the impact in the managed package is
		Test.startTest();
        beynd__BeyndProject__c projectRecord = [SELECT Id, Name, beynd__Source_Object__c from beynd__BeyndProject__c Order By CreatedDate desc LIMIT 1];
        Opportunity oppRecord = [SELECT Id FROM Opportunity Order By CreatedDate desc LIMIT 1];
        
        GuideCXProjectUpsert newUpsert = new GuideCXProjectUpsert();
        beynd.GuideCXProject projectTest = newUpsert.ProjectDetails(oppRecord.Id);
        System.assertEquals('GuideCX TEST Account AA', projectTest.CustomerName);
        Map<Id, Id> testMap = new Map<Id, Id>();
        testMap.put(oppRecord.Id, projectRecord.beynd__Source_Object__c);
        newUpsert.linkProjects(testMap);

        Test.stopTest();
    
	}
    
    @isTest
    static void testGuideCXNotes() {        
		// Testing the GuideCX Notes method
		Test.startTest();
        beynd__BeyndProject__c projectRecord = [SELECT Id, Name, beynd__Source_Object__c from beynd__BeyndProject__c Order By CreatedDate desc LIMIT 1];
        
        Integer result = GuideCXProjectUpsert.updateGuideCXNotesNonFuture(projectRecord.Id);
        System.assertEquals(0, result);

        Test.stopTest();
    
	}
    
}