public with sharing class CalloutHelper 
{

    /**
     * Enter with tenant Id and the value of isOnboardingOptional. Callout to to set subscription settings in the dear system. 
     * Log errors to the API Error Log.
     * 
     * @param tenantId - Dear tenant Id for the opportunity in question
     * @param isOnboardingOptional - value we're writing to this tenant Id
     * @return void
     * @author nkoonce @ NuAge : Cin7-101 : May 2024
     */ 
    public static void SendIsOnboardingOptional(String tenantId, Boolean isOnboardingOptional)
    {
        // Set the endpoint
        String endpoint = 'callout:Subscription_Settings';
        // if (verb == 'GET') endpoint += '?tenantID=' + tenantId;

        // Build and serialize the body
        IncomingRequestJSONParse.Data outData = new IncomingRequestJSONParse.Data();
            outData.TenantID = tenantId;
            outData.IsOnboardingOptional = isOnboardingOptional;
        String body = JSON.serialize(outData, true);

        // Callout to endpoint, handle errors
        API_Error_Log__c errLog = new API_Error_Log__c();
        try 
        {
            Map<String,String> headers = new Map<String,String>();
            headers.put('Content-Type', 'application/json');
            headers.put('Accept', '*/*');

            HttpResponse response = makeCallout(endpoint, 'POST', body, headers);    
            Integer responseCode = response.getStatusCode();

            // Validate response
            if (responseCode == 200)
            {
                // If successful go get the data
                IncomingRequestJSONParse inData = (IncomingRequestJSONParse) JSON.deserialize(response.getBody(), IncomingRequestJSONParse.class);
                
                if (inData.Data.TenantID != outData.TenantID)
                {
                    errLog.Error_Message__c = 'Error updating IsOnboardingOptional: Tenant Id mismatch - Sent: ' 
                        + outData.TenantId + ', Response: ' + inData.Data.TenantID;
                } 
                else if (inData.Data.IsOnboardingOptional != outData.IsOnboardingOptional)
                {
                    errLog.Error_Message__c = 'Error updating IsOnboardingOptional: Response value does not match value sent - Sent: ' 
                        + String.valueOf(outData.IsOnboardingOptional) + ', Response: ' + String.valueOf(inData.Data.IsOnboardingOptional);
                }
            }
            else
            {
                errLog.Http_Status_Code__c = responseCode;
                errLog.Status__c = response.getStatus();
                errLog.Error_Message__c = 'Unexpected response to SubscriptionSettings update (IsOnboardingOptional)';
                errLog.Incoming_Request_Tenant_Id__c = outData.TenantID;
            }
        } 
        catch (Exception e) 
        {
            errLog.Error_Message__c = 'Unexpected error while updating IsOnboardingOptional: CalloutHelper Line #' 
                + String.valueOf(e.getLineNumber()) + ', ' + e.getMessage(); 
        }

        // If the error log has content, insert it
        if (String.isNotBlank(errLog.Error_Message__c)) insert errLog;
    }

    /**
     * For Contact records, callout to NorthPass to add a new user, and then callout 
     * to add them to a group based on their Dear Tenant Id and Cin7 Account Username.
     * 
     * @param subscriptions - Pre-validated list of NorthpassSubscriptionWrappers
     * @param wrapper - pre-validated NorthpassSubscriptionWrapper
     * @author nkoonce @ NuAge : Cin7-107 : April 2024
     */
    public static void CreateNorthPassUserAndAssignToGroup(List<NorthpassSubscriptionWrapper> subscriptions) {
        // Initialize the error log list to store errors in bulk
        List<API_Error_Log__c> errorLogs = new List<API_Error_Log__c>();

        // Check if the entire subscription list is null
        if (subscriptions == null || subscriptions.isEmpty()) {
            API_Error_Log__c errLog = new API_Error_Log__c(
                Error_Message__c = 'Cannot create Northpass users because subscription list is null or empty'
            );
            errorLogs.add(errLog);
            insert errorLogs; // Insert error log if the list is null or empty
            return;
        }
        
        // Set up the endpoint for the NorthPass person creation
        String endpoint = 'callout:Northpass_Person';

        // Prepare headers for the callout
        Map<String, String> headers = new Map<String, String>();
        headers.put('accept', 'application/json');
        headers.put('content-type', 'application/json');

        // Build request payload (a bulk request if the API allows it, else loop over the list)
        for (NorthpassSubscriptionWrapper subscription : subscriptions) {
            if (subscription == null) {
                // Log error for null subscription
                API_Error_Log__c errLog = new API_Error_Log__c(
                    Error_Message__c = 'Cannot create Northpass user because a subscription is null'
                );
                errorLogs.add(errLog);
                continue; // Skip processing for null subscriptions
            }
            try {

                // Serialize each subscription object
                String body = JSON.serialize(subscription, true);

                // Perform the callout to create the user
                HttpResponse response = makeCallout(endpoint, 'POST', body, headers);

                // Check if the response is successful (HTTP 201 Created)
                if (response.getStatusCode() == 201) {
                    // Success! Collect the user's UUID from the response
                    system.debug(response.getBody());

                    // Parse the response to retrieve the newly created user ID
                    NorthpassSubscriptionWrapper responseWrap = NorthpassSubscriptionWrapper.parse(response.getBody());

                    if (String.isNotBlank(responseWrap.data.id)) {
                        // Build the endpoint for group assignment
                        String groupEndpoint = 'callout:Northpass_Group/' + subscription.data.attributes.northpass_group_id + '/relationships/people';

                        // Set the type and clear unnecessary attributes before making the group assignment callout
                        responseWrap.data.type = 'people';
                        responseWrap.data.attributes = null;

                        String groupBody = '{"data":[' + JSON.serialize(responseWrap.data, true) + ']}';

                        // Callout to assign the user to the group
                        HttpResponse groupResponse = makeCallout(groupEndpoint, 'POST', groupBody, headers);

                        // Check for successful group assignment (HTTP 204 No Content)
                        if (groupResponse.getStatusCode() != 204) {
                            // Log error if the assignment fails
                            API_Error_Log__c errLog = new API_Error_Log__c(
                                Http_Status_Code__c = groupResponse.getStatusCode(),
                                Status__c = groupResponse.getStatus(),
                                Incoming_Request_Tenant_Id__c = subscription.data.attributes.dear_tenant_id,
                                Error_Message__c = 'Failed to assign user to group. Response: ' + groupResponse.getBody()
                            );
                            errorLogs.add(errLog);
                        }
                    } else {
                        // Log error if the user creation failed
                        API_Error_Log__c errLog = new API_Error_Log__c(
                            Http_Status_Code__c = response.getStatusCode(),
                            Status__c = response.getStatus(),
                            Incoming_Request_Tenant_Id__c = subscription.data.attributes.dear_tenant_id,
                            Error_Message__c = 'User creation did not produce a UUID'
                        );
                        errorLogs.add(errLog);
                    }
                } else {
                    // Log error if the user creation callout fails
                    API_Error_Log__c errLog = new API_Error_Log__c(
                        Http_Status_Code__c = response.getStatusCode(),
                        Status__c = response.getStatus(),
                        Error_Message__c = 'User creation failed: ' + response.getBody(),
                        Incoming_Request_Tenant_Id__c = subscription.data.attributes.dear_tenant_id
                    );
                    errorLogs.add(errLog);
                }
            } catch (Exception e) {
                // Catch any unexpected exceptions and log them
                API_Error_Log__c errLog = new API_Error_Log__c(
                    Status__c = 'Callout failed',
                    Incoming_Request_Tenant_Id__c = subscription.data.attributes.dear_tenant_id,
                    Error_Message__c = 'Error in CreateNorthPassUserAndAssignToGroup: ' + e.getMessage()
                );
                errorLogs.add(errLog);
            }
        }

        // If there were errors, insert them into the log
        if (!errorLogs.isEmpty()) {
            insert errorLogs;
        }
    }

    /**
     * Generic callout that returns with HttpResponse.
     * 
     * @param endpoint - 
     * @param verb - the callout method we're using
     * @param body - callout body
     * @return HttpResponse resulting from the callout
     * @author nkoonce @ NuAge : CIN7-101 : April 2024
     */
    public static HttpResponse MakeCallout(String endpoint, String verb, String body, Map<String,String> headers)
    {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod(verb);
        if (headers != null && headers.size() > 0)
        {
            for (String header : headers.keySet())
            {
                req.setHeader(header, headers.get(header));
            }
        }
        req.setTimeout(120000);
        if (String.isNotBlank(body))
        {
            req.setBody(body);
        }

        system.debug(req.getMethod());
        system.debug(req.getEndpoint());
        system.debug(req.getBody());
        
        // Callout
        Http http = new Http();
         return http.send(req); 
    }

}