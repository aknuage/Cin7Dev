public class PostRequestInvocable {
    @InvocableMethod(label='Sends a POST request' description='Sends a POST request')
    public static List<ResponseWrapper> sendPostRequest(List<HttpRequestInfo> requests) {
        List<ResponseWrapper> responses = new List<ResponseWrapper>();
        
        for (HttpRequestInfo requestInfo : requests) {
            HttpRequest request = new HttpRequest();
            request.setEndpoint(requestInfo.endpoint);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
            String jsonParsed = JSON.serialize(requestInfo.requestBody);
            request.setBody(jsonParsed);
            
            Http http = new Http();
            HttpResponse response = http.send(request);
            
            String responseBody = response.getBody();
            
            ResponseWrapper responseWrapper = new ResponseWrapper();
            responseWrapper.responseBody = responseBody;
            
            responses.add(responseWrapper);
        }
        
        return responses;
    }

    public class HttpRequestInfo {
        @InvocableVariable(required=true)
        public String endpoint;
        
        @InvocableVariable(required=true)
        public String requestBody;
    }
    
    public class ResponseWrapper {
        @InvocableVariable
        public String responseBody;
    }
}