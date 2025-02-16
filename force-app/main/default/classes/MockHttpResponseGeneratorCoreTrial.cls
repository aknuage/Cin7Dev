/**
     * Mock HTTP response generator for simulating callouts during tests.
     * @author AKelly @ NuageExperts
     */
    public class MockHttpResponseGeneratorCoreTrial implements HttpCalloutMock {
        /**
         * This method simulates the HTTP response for both POST and PUT requests.
         * 
         * @param req HttpRequest - The request object for the callout.
         * @return HTTPResponse - The simulated response.
         */
        public HTTPResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();

            // Simulate a 200 OK response for both POST and PUT endpoints
            res.setStatusCode(200);
            
            // Simulated response body for POST request (account creation)
            if (req.getEndpoint().containsIgnoreCase('Account_Provisions')) {
                res.setBody('{"StatusCode":"account_created","Data":{"TenantID":"newTenant123","RequestID":"request123"}}');
            }
            
            // Simulated response body for PUT request (partner-client relationship)
            if (req.getEndpoint().containsIgnoreCase('Partner_Client_Relationship')) {
                res.setBody('{"StatusCode":"organization_created","Data":{"TenantID":"partnerTenant123","RequestID":"request456"}}');
            }
    
            return res;
        }
    }