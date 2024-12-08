/**
 * Batch class for handling "RenewalSubscription" type Incoming Requests.
 * Query for Accounts by Request's tenant IDs and update Subscription Expiration Date based
 * on the JSON response.
 * 
 * @author: NuAge Experts - akelly - December 2024
 */
public with sharing class IncomingReqRenewalSubscriptionBatch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {

    private List < API_Error_Log__c > apiErrorLogsToInsert;
    private List < Incoming_Request__c > requestsToProcess;

    public IncomingReqRenewalSubscriptionBatch(List < Incoming_Request__c > newRequests) {
        this.requestsToProcess = newRequests;
        this.apiErrorLogsToInsert = new List < API_Error_Log__c > ();
    }

    public List < Incoming_Request__c > start(Database.BatchableContext bc) {
        return this.requestsToProcess;
    }

    public void execute(Database.BatchableContext bc, List < Incoming_Request__c > incomingRequests) {

        Set<String> tenantIds = new Set<String>();
        Map<String, Incoming_Request__c> requestMap = new Map<String, Incoming_Request__c>();

        for (Incoming_Request__c request : incomingRequests) {
            tenantIds.add(request.Tenant_Id__c);
            requestMap.put(request.Tenant_Id__c, request);
        }

        // Retrieve Accounts in bulk based on tenant IDs
        Map<String, Account> accountMap = new Map<String, Account>();
        for (Account acc : [SELECT Id, DEAR_Tenant_ID__c FROM Account WHERE DEAR_Tenant_ID__c IN :tenantIds]) {
            accountMap.put(acc.DEAR_Tenant_ID__c, acc);
        }

        List<Account> accountsToUpdate = new List<Account>();

        for (Incoming_Request__c req : incomingRequests) {
            String tenantId = req.Tenant_Id__c;

            // Match Account to corresponding Incoming Request based on shared Tenant ID
            if (accountMap.containsKey(tenantId)) {
                HttpResponse response = IncomingRequestHelper.GetCoreCustomerDetails(tenantId);

                if (response != null && response.getStatusCode() == 200) {
                    try {
                        IncomingRequestJSONParse jsonResp = IncomingRequestJSONParse.parse(response.getBody());
                        Account acc = accountMap.get(tenantId); // get Account which matches this Incoming Req

                        if (jsonResp.Data != null && jsonResp.Data.SubscriptionExpirationDate != null) 
                        {
                            // Update Account's subscription expiration date based on Renewal expiration
                            acc.Subscription_Expiration_Date__c = Date.valueOf(jsonResp.Data.SubscriptionExpirationDate);
                            accountsToUpdate.add(acc);
                        } 
                        else if (jsonResp.Errors != null) 
                        {
                            logResponseError(apiErrorLogsToInsert, jsonResp, response);
                        }
                    } catch (Exception e) {
                        logError(apiErrorLogsToInsert, e, response, requestMap.get(tenantId));
                    }
                } else {
                    logResponseError(apiErrorLogsToInsert, null, response);
                }
            }
        }


        // DML: Update Account Subscription Renewal Dates and/or Insert Error Logs
        if (!accountsToUpdate.isEmpty()) update accountsToUpdate;
        if (!apiErrorLogsToInsert.isEmpty()) insert apiErrorLogsToInsert;
    }


    private void logError(List <API_Error_Log__c> logs, Exception e, HttpResponse response, Incoming_Request__c request) {
        API_Error_Log__c newError = new API_Error_Log__c(
            Error_Message__c = 'Error processing AccountRenewal: ' + e.getMessage(),
            HTTP_Status_Code__c = response?.getStatusCode(),
            Status__c = response?.getStatus(),
            Incoming_Request_Tenant_ID__c = request?.Tenant_ID__c
        );
        logs.add(newError);
    }


    private void logResponseError(List <API_Error_Log__c> logs, IncomingRequestJSONParse jsonResp, HttpResponse response) {
        apiErrorLogsToInsert.add(new API_Error_Log__c(
            Error_Message__c = String.join(jsonResp?.Errors, ','),
            HTTP_Status_Code__c = response?.getStatusCode(),
            Status__c = response?.getStatus()
        ));
    }

    public void finish(Database.BatchableContext bc) {}
}