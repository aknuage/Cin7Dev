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
            tenantIds.add( request.Tenant_Id__c.toUpperCase() );
        }

        // Retrieve Accounts in bulk based on tenant IDs
        Map<String, Account> accountMap = new Map<String, Account>();
        for (Account acc : [SELECT Id, Name, DEAR_Tenant_ID__c FROM Account WHERE DEAR_Tenant_ID__c IN :tenantIds]) {
            String accTenantId = acc.DEAR_Tenant_ID__c.toUpperCase();
            accountMap.put(accTenantId, acc);
        }

        List<Account> accountsToUpdate = new List<Account>();

        for (Incoming_Request__c ir : incomingRequests) {
            String tenantId = ir.Tenant_Id__c.toUpperCase();
            
            // Match Account to corresponding Incoming Request based on shared Tenant ID
            if (accountMap.containsKey(tenantId)) {
                HttpResponse response = IncomingRequestHelper.GetCoreCustomerDetails(tenantId);
                System.debug('http response: ' + response);
                if (response != null && response.getStatusCode() == 200) {
                    try {
                        IncomingRequestJSONParse jsonResp = IncomingRequestJSONParse.parse(response.getBody());
                        System.debug('incoming renewal req: ' + JSON.serializePretty(String.valueOf(jsonResp)));
                        Account acc = accountMap.get(tenantId); // get Account which matches this Incoming Req
                        
                        if (jsonResp.Errors != null) {
                            apiErrorLogsToInsert.add(IncomingRequestHelper.LogResponseError(jsonResp, response));
                        }
                        
                        if (jsonResp.Data != null && jsonResp.Data.SubscriptionExpirationDate != null) {
                            // Update Account's subscription expiration date based on Renewal expiration
                            System.debug('sub expiration: ' + jsonResp.Data.SubscriptionExpirationDate);
                            acc.Subscription_Expiration_Date__c = Date.valueOf(jsonResp.Data.SubscriptionExpirationDate);
                            acc.Core_Last_Updated_Date__c = System.now();
                            accountsToUpdate.add(acc);
                        }
                    } catch (Exception ex) {
                        String errorMsg = 'Error processing Account Renewal: ' + ex.getMessage() + ', Line #: ' + ex.getLineNumber();
                        apiErrorLogsToInsert.add(IncomingRequestHelper.LogError(ex, errorMsg, ir, response));
    
                    }
                } else {
                    String err = 'Error in account renewal HTTP Response: ' + tenantId;
                    apiErrorLogsToInsert.add(
                        new API_Error_Log__c(
                            Error_Message__c = err,
                            HTTP_Status_Code__c = response?.getStatusCode(),
                            Status__c = response?.getStatus()
                        )
                    );
                }
            }
        }


        // DML: Update Account Subscription Renewal Dates and/or Insert Error Logs
        if (!accountsToUpdate.isEmpty()) 
        try {
            update accountsToUpdate;
        } catch(Exception ex) {
            System.debug('Error renewing account: ' + ex.getMessage());
            apiErrorLogsToInsert.add(IncomingRequestHelper.LogError(ex, 'Error renewing account', null, null));
        }
        if (!apiErrorLogsToInsert.isEmpty()) insert apiErrorLogsToInsert;
    }


    public void finish(Database.BatchableContext bc) {}
}