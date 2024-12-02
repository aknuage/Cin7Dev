@isTest
private class PostRequestInvocableTest {
    @isTest
    static void sendPostRequestTest() {
        // Create test data
        PostRequestInvocable.HttpRequestInfo requestInfo = new PostRequestInvocable.HttpRequestInfo();
        requestInfo.endpoint = 'http://example-api.com';
        requestInfo.requestBody = '{"key":"value"}';

        List<PostRequestInvocable.HttpRequestInfo> requestInfos = new List<PostRequestInvocable.HttpRequestInfo>{requestInfo};

        // Mock response
        String postResponse = '{"message:" : "Hello World"}';
        MockHttpResponseHandler.SimpleMockResponse postResp = new MockHttpResponseHandler.SimpleMockResponse('POST', postResponse);
        postResp.contentType = 'application/json';

        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse('http://example-api.com', postResp);

        // Set the mock callout
        Test.setMock(HttpCalloutMock.class, mock);

        // Start test execution
        Test.startTest();

        // Call the method you want to test
        List<PostRequestInvocable.ResponseWrapper> responses = PostRequestInvocable.sendPostRequest(requestInfos);

        // Stop test execution
        Test.stopTest();

        // Verify the results
        System.assertEquals(1, responses.size());
        System.assertEquals(postResponse, responses[0].responseBody);
    }
}