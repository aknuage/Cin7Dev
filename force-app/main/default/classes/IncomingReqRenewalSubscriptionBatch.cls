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

        for (Incoming_Request__c request : incomingRequests) {
            tenantIds.add(request.Tenant_Id__c);
        }

        // Retrieve Accounts in bulk based on tenant IDs
        Map<String, Account> accountMap = new Map<String, Account>();
        for (Account acc : [SELECT Id, DEAR_Tenant_ID__c FROM Account WHERE DEAR_Tenant_ID__c IN :tenantIds]) {
            accountMap.put(acc.DEAR_Tenant_ID__c, acc);
        }

        List<Account> accountsToUpdate = new List<Account>();

        for (Incoming_Request__c ir : incomingRequests) {
            String tenantId = ir.Tenant_Id__c;

            // Match Account to corresponding Incoming Request based on shared Tenant ID
            if (accountMap.containsKey(tenantId)) {
                HttpResponse response = IncomingRequestHelper.GetCoreCustomerDetails(tenantId);

                if (response != null && response.getStatusCode() == 200) {
                    try {
                        IncomingRequestJSONParse jsonResp = IncomingRequestJSONParse.parse(response.getBody());
                        Account acc = accountMap.get(tenantId); // get Account which matches this Incoming Req
                        
                        if (jsonResp.Errors != null) {
                            apiErrorLogsToInsert.add(IncomingRequestHelper.LogResponseError(jsonResp, response));
                        }
                        
                        if (jsonResp.Data != null && jsonResp.Data.SubscriptionExpirationDate != null) {
                            // Update Account's subscription expiration date based on Renewal expiration
                            acc.Subscription_Expiration_Date__c = Date.valueOf(jsonResp.Data.SubscriptionExpirationDate);
                            accountsToUpdate.add(acc);
                        }
                    } catch (Exception ex) {
                        String errorMsg = 'Error processing Account Renewal: ' + ex.getMessage() + ', Line #: ' + ex.getLineNumber();
                        apiErrorLogsToInsert.add(IncomingRequestHelper.LogError(ex, errorMsg, ir, response));
    
                    }
                } else {
                    apiErrorLogsToInsert.add(IncomingRequestHelper.LogResponseError(null, response));
                }
            }
        }


        // DML: Update Account Subscription Renewal Dates and/or Insert Error Logs
        if (!accountsToUpdate.isEmpty()) update accountsToUpdate;
        if (!apiErrorLogsToInsert.isEmpty()) insert apiErrorLogsToInsert;
    }


    public void finish(Database.BatchableContext bc) {}
}