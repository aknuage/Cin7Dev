/**
 * Batch class for handling "CancelSubscription" type Incoming Requests.
 * Query for Accounts by Request's tenant IDs, then clone its most recent Opportunity, append ' - Cancellation' to the name, and insert.
 * Clone the original Opp's line items, zero out quantities, and insert them against the newly cloned cancel Opp.
 * 
 * @author: NuAge Experts - akelly - December 2024
 */
public with sharing class IncomingReqCancelSubscriptionBatch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {
    // TODO: More API error handling?

    private List<Incoming_Request__c> requestsToProcess;
    
    public IncomingReqCancelSubscriptionBatch(List<Incoming_Request__c> newRequests) {
        this.requestsToProcess = newRequests;
    }

    public List<Incoming_Request__c> start(Database.BatchableContext bc) {
        return this.requestsToProcess;
    }

    public void execute(Database.BatchableContext bc, List<Incoming_Request__c> incomingRequests) {
        Set<String> tenantIds = new Set<String>();
        List<Opportunity> clonedOpportunities = new List<Opportunity>();
        Map<Id, Opportunity> originalToClonedOppMap = new Map<Id, Opportunity>();
        List<API_Error_Log__c> apiErrorLogsToInsert = new List<API_Error_Log__c>();
        List<OpportunityLineItem> clonedLineItems = new List<OpportunityLineItem>();
    
        // Collect tenant IDs from incoming requests
        for (Incoming_Request__c ir : incomingRequests) {
            HttpResponse response = IncomingRequestHelper.GetCoreCustomerDetails(ir.Tenant_Id__c);

            if (response == null) continue;  // Skip if the response is null - or log error?
    
            IncomingRequestJSONParse jsonResp = IncomingRequestJSONParse.parse(response.getBody());

            if (jsonResp.Data != null && !String.isBlank(jsonResp.Data.TenantID)) {
                tenantIds.add(jsonResp.Data.TenantID);
            }
        }
    
        // Query related Accounts by incoming Tenant IDs
        Map<Id, Account> accountsToCancel = new Map<Id, Account>([
            SELECT Id FROM Account WHERE DEAR_Tenant_ID__c IN :tenantIds
        ]);
    
        Map<Id, Opportunity> mostRecentOpps = new Map<Id, Opportunity>();
        Map<Id, List<OpportunityLineItem>> oppLineItemsMap = new Map<Id, List<OpportunityLineItem>>();
    
        for (Opportunity opp : [
            SELECT Id, Name, AccountId, CloseDate, Dear_Tenant_Id__c, Amount, Is_Active__c, RecordTypeId, StageName, Pricebook2Id,
            CurrencyIsoCode, 
            (SELECT Quantity, UnitPrice, Product2Id FROM OpportunityLineItems)
            FROM Opportunity
            WHERE AccountId IN :accountsToCancel.keySet()
            AND StageName = 'Closed Won'
            ORDER BY AccountId, CloseDate DESC
        ]) {
            if (!mostRecentOpps.containsKey(opp.AccountId)) {
                opp.Is_Active__c = false; // update existing Opp
                mostRecentOpps.put(opp.AccountId, opp);
                oppLineItemsMap.put(opp.Id, opp.OpportunityLineItems);
            }
        }
    
        // Clone Opportunities and their Line Items
        for (Opportunity originalOpp : mostRecentOpps.values()) {
            Opportunity clonedOpp = originalOpp.clone(false, true); // Deep clone without carrying IDs
            clonedOpp.StageName = 'Closed Won';
            clonedOpp.Is_Active__c = true;
            clonedOpp.Amount = 0;  // Set amount to zero for the cancellation opportunity
            clonedOpp.Pricebook2Id = originalOpp.Pricebook2Id;  // Ensuring the price book is set
            clonedOpp.Name = originalOpp.Name + ' - Cancellation';
            clonedOpp.CurrencyIsoCode = originalOpp.CurrencyIsoCode;
            clonedOpp.Pricebook2Id = originalOpp.Pricebook2Id;  // Ensuring the price book is set correctly
            clonedOpportunities.add(clonedOpp);
            originalToClonedOppMap.put(originalOpp.Id, clonedOpp);
        }
    
        // Insert cloned Opportunities
        try {
            insert clonedOpportunities;
        } catch (DmlException ex) {
            System.debug('issue inserting cloned opps: ' + ex.getMessage());
            apiErrorLogsToInsert.add(new API_Error_Log__c(
                Error_Message__c = ex.getMessage(),
                Status__c = 'Failed to insert cloned opportunities'
            ));
        }
    
        // Prepare and clone Opportunity Line Items
        for (Opportunity originalOpp : mostRecentOpps.values()) {
            if (originalToClonedOppMap.containsKey(originalOpp.Id)) {
                Opportunity clonedOpp = originalToClonedOppMap.get(originalOpp.Id);
                List<OpportunityLineItem> originalLineItems = oppLineItemsMap.get(originalOpp.Id);
    
                for (OpportunityLineItem oli : originalLineItems) {
                    OpportunityLineItem clonedOli = oli.clone(false, true);
                    // clonedOli.Quantity = 0;  // Set quantity to zero for cancellation
                    clonedOli.UnitPrice = 0;  // Set unit price to zero for cancellation
                    clonedOli.OpportunityId = clonedOpp.Id;  // Associate cloned line item with the cloned opportunity
                    clonedLineItems.add(clonedOli);
                }
            }
        }
    
        // Insert cloned Line Items
        if (!clonedLineItems.isEmpty()) {
            try {
                insert clonedLineItems;
            } catch (DmlException ex) {
                System.debug('issue inserting olis: ' + ex.getMessage());
                apiErrorLogsToInsert.add(new API_Error_Log__c(
                    Error_Message__c = ex.getMessage(),
                    Status__c = 'Failed to insert cloned line items'
                ));
            }
        }

        if (!mostRecentOpps.isEmpty()) update mostRecentOpps.values();
    
        // Insert any error logs
        if (!apiErrorLogsToInsert.isEmpty()) {
            insert apiErrorLogsToInsert;
        }
    }
    

    public void finish(Database.BatchableContext bc) {}
}
