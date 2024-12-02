/**
 * Batch class for handling "RenewalSubscription" type Incoming Requests.
 * Query for Accounts by Request's tenant IDs and update Subscription Expiration Date based
 * on the JSON response.
 * 
 * @author: NuAge Experts - akelly - December 2024
 */
public with sharing class IncomingRequestRenewalSubscription {

    private List < API_Error_Log__c > apiErrorLogsToInsert;
    private List < Incoming_Request__c > requestsToProcess;

    public IncomingRequestRenewalSubscription(List < Incoming_Request__c > newRequests) {
        this.requestsToProcess = newRequests;
        this.apiErrorLogsToInsert = new List < API_Error_Log__c > ();
    }

    public List < Incoming_Request__c > start(Database.BatchableContext bc) {
        return this.requestsToProcess;
    }

    global void execute(Database.BatchableContext bc, List < Incoming_Request__c > incomingRequests) {

        List < Account > accountsToUpdate = new List < Account > ();

        for (Incoming_Request__c ir: incomingRequests) {
            HttpResponse response = IncomingRequestHelper.GetCoreCustomerDetails(ir.Tenant_Id__c);

            if (response == null) break; // If null, error already recorded to API error log

            IncomingRequestJSONParse jsonResp = IncomingRequestJSONParse.parse(response.getBody());
            System.debug('renewal jsonResp: ' + JSON.serializePretty(jsonResp));

            if (jsonResp.Errors == null) {
                try {
                    // Query for accounts matching incoming Tenant ID
                    Account acc = [SELECT DEAR_Tenant_ID__c, Subscription_Expiration_Date__c
                        FROM Account WHERE DEAR_Tenant_ID__c =: ir.Tenant_ID__c
                    ];

                    if (acc != null && jsonResp.Data != null) {
                        if (jsonResp.Data.SubscriptionExpirationDate != null) {
                            // Update Account's subscription expiration date with that of the incoming response
                            acc.Subscription_Expiration_Date__c = Date.valueOf(jsonResp.Data.SubscriptionExpirationDate);
                            accountsToUpdate.add(acc);
                        }
                    } else {
                        API_Error_Log__c newError = new API_Error_Log__c(
                            Error_Message__c = 'Account matching the request tenant ID was not found for renewal',
                            Incoming_Request_Tenant_ID__c = ir ? .Tenant_ID__c
                        );
                        apiErrorLogsToInsert.add(newError);
                    }
                } catch(Exception ex)
                {
                    logError(apiErrorLogsToInsert, ex, response, ir);
                    continue;
                }
            }
        }


        // DML: Update Account Subscription Renewal Dates and/or Insert Error Logs
        if (!accountsToUpdate.isEmpty()) update accountsToUpdate;
        if (!apiErrorLogsToInsert.isEmpty()) insert apiErrorLogsToInsert;
    }


    private void logError(List < API_Error_Log__c > logs, Exception e, HttpResponse response, Incoming_Request__c request) {
        API_Error_Log__c newError = new API_Error_Log__c(
            Error_Message__c = 'Error processing AccountRenewal: ' + e.getMessage() + ', Line #: ' + e.getLineNumber(),
            HTTP_Status_Code__c = response?.getStatusCode(),
            Status__c = response?.getStatus(),
            Incoming_Request_Tenant_ID__c = request?.Tenant_ID__c
        );
        apiErrorLogsToInsert.add(newError);
    }


    private void logErrorResponse(List < API_Error_Log__c > logs, IncomingRequestJSONParse jsonResp, HttpResponse response) {
        apiErrorLogsToInsert.add(new API_Error_Log__c(
            Error_Message__c = String.join(jsonResp?.Errors, ','),
            HTTP_Status_Code__c = response ? .getStatusCode(),
            Status__c = response ? .getStatus()
        ));
    }

    global void finish(Database.BatchableContext bc) {}
}