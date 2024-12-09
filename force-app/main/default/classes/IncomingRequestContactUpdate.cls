public class IncomingRequestContactUpdate {
    private List<Incoming_Request__c> requestsToProcess;

    public IncomingRequestContactUpdate(List<Incoming_Request__c> newRequests) {
        this.requestsToProcess = newRequests;
        processContactUpdateReqs(newRequests);
    }

    void processContactUpdateReqs(List<Incoming_Request__c> incomingRequests) {
        List<API_Error_Log__c> apiErrorLogsToInsert = new List<API_Error_Log__c>();
        System.debug('entering contact update method');
        for (Incoming_Request__c ir : incomingRequests)
        {
            HttpResponse response = IncomingRequestHelper.GetCoreCustomerDetails(ir.Tenant_Id__c);

            if (response == null) break;    // If null, error already recorded to API error log

            // Parse into wrapper
            IncomingRequestJSONParse jsonResp = IncomingRequestJSONParse.parse(response.getBody());
            System.debug('ContactUpdate response: ' + JSON.serialize(jsonResp));

            // Iterate response wrapper
            if (jsonResp.Errors == null)
            {
                try
                {
                    // Run Contacts through Queueable process if JSON resp contains users
                    if(jsonResp.Data.Users.size() > 0){
                        System.enqueueJob(new ContactProcessQueueable(jsonResp.Data.Users, jsonResp.Data.TenantID));
                    }
                }
                catch(Exception e)
                {
                    system.debug('Error processing ContactUpdate: ' + e.getMessage());
                    API_Error_Log__c newError = new API_Error_Log__c(
                        Error_Message__c = 'Error processing ContactUpdate: ' + e.getMessage() + ', Line #: ' + e.getLineNumber(),
                        HTTP_Status_Code__c = response?.getStatusCode(),
                        Status__c = response?.getStatus(),
                        Incoming_Request_Tenant_ID__c = ir?.Tenant_ID__c
                    );
                    apiErrorLogsToInsert.add(newError);
                }
            }
            else
            {
                System.debug('Something went wrong when fetching customer details...');
                apiErrorLogsToInsert.add(new API_Error_Log__c(
                    Error_Message__c = String.join(jsonResp?.Errors, ','),
                    HTTP_Status_Code__c = response?.getStatusCode(),
                    Status__c = response?.getStatus()
                ));
            }
        }

        if (apiErrorLogsToInsert.size() > 0) insert apiErrorLogsToInsert;
    
    }

}