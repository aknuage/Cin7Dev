/**
 * 
 * @author: NuAge Experts - akelly - Nov 2024
 */
global class IncomingRequestDiscountChange implements Database.Batchable<sObject>, Database.AllowsCallouts {

    private Id recordTypeId;
    private List<OpportunityLineItem> lineItems;
    private List<API_Error_Log__c> apiErrorLogsToInsert;
    private List<Incoming_Request__c> requestsToProcess;

    public IncomingRequestDiscountChange(List<Incoming_Request__c> newRequests) 
    {
        this.requestsToProcess = newRequests;
        this.apiErrorLogsToInsert = new List<API_Error_Log__c>();
        this.recordTypeId=Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Core_Upgrade_Downgrade').getRecordTypeId();
    }

    public List<Incoming_Request__c> start(Database.BatchableContext bc) {
        return this.requestsToProcess;
    }

    global void execute(Database.BatchableContext bc, List<Incoming_Request__c> requests) {
        Map<Id, Opportunity> oppsToUpdate = new Map<Id, Opportunity>();
        List<OpportunityLineItem> newLineItems = new List<OpportunityLineItem>(); // Initialize list to collect new line items
    
        for (Incoming_Request__c request : requests) {
            HttpResponse response = IncomingRequestHelper.GetCoreCustomerDetails(request.Tenant_Id__c);
            if (response == null) {
                continue; // Log and skip if no response
            }
    
            IncomingRequestJSONParse jsonResp = IncomingRequestJSONParse.parse(response.getBody());
            
            if (jsonResp.Errors == null) {
                try {
                    Opportunity relevantOpp = findRelevantOpportunity(request.Tenant_Id__c);
                    if (relevantOpp != null) {
                        updateOpportunityBasedOnDiscounts(relevantOpp, jsonResp.Data.SKUs, newLineItems);
                        oppsToUpdate.put(relevantOpp.Id, relevantOpp);
                    }
                } catch (Exception e) {
                    logError(apiErrorLogsToInsert, e, response, request);
                }
            } else {
                logErrorResponse(apiErrorLogsToInsert, jsonResp, response);
            }
        }
    
        // DML: Update Opportunities, Insert OpportunityLineItems, insert API Error Logs
        if (!oppsToUpdate.isEmpty()) update oppsToUpdate.values();
        if (!lineItems.isEmpty()) update lineItems;
        if (!newLineItems.isEmpty()) insert newLineItems;
        if (!apiErrorLogsToInsert.isEmpty()) insert apiErrorLogsToInsert;
    }

    private void updateOpportunityBasedOnDiscounts(Opportunity opp, List<IncomingRequestJSONParse.SKUs> skus, List<OpportunityLineItem> newLineItems) {
        Map<String, OpportunityLineItem> existingItemsMap = new Map<String, OpportunityLineItem>();
        
        for (OpportunityLineItem item : [
            SELECT Id, Product2.Name, Quantity, UnitPrice 
            FROM OpportunityLineItem 
            WHERE OpportunityId = :opp.Id
        ]) {
            existingItemsMap.put(item.Product2.Name, item);
        }
        
        Set<String> skuNames = new Set<String>();
        Map<String, Id> skuProductIdMap = new Map<String, Id>();

        // Loop 1: Get SKU names and query Products
        for (IncomingRequestJSONParse.SKUs sku : skus)
        {
            skuNames.add(sku.Name);
        }

        List<Product2> products = [ SELECT Id FROM Product2 WHERE Name IN :skuNames];

        // Populate ProductSkuMap
        for (Product2 product : products)
        {
            skuProductIdMap.put(product.Name, product.Id);
        }

        for (IncomingRequestJSONParse.SKUs sku : skus) {
            OpportunityLineItem item = existingItemsMap.get(sku.Name);
            if (item != null) {
                // Update existing line items if quantities or prices have changed
                if (item.Quantity != sku.Quantity || item.UnitPrice != (sku.Total / sku.Quantity)) {
                    item.Quantity = sku.Quantity;
                    item.UnitPrice = sku.Total / sku.Quantity;
                    lineItems.add(item);
                }
            } else {
                // Create new line item if it does not exist
                Id productId = skuProductIdMap.get(sku.Name);
                
                if (!String.isBlank(productId))
                {
                    List<OpportunityLineItem> newLineItem = new OpportunityLineItem(
                        OpportunityId = opp.Id,
                        Product2Id = productId,
                        Quantity = sku.Quantity,
                        UnitPrice = sku.Total / sku.Quantity
                    );
                    insertLineItems.add(newLineItem);
                }
            }
        }
    }
    

    private Opportunity findRelevantOpportunity(String tenantId) {
        // Retrieve the active opportunity linked to the tenant ID, if available
        Opportunity relatedOpp = [
            SELECT Id, Name, StageName, Amount, Is_Active__c 
            FROM Opportunity 
            WHERE DEAR_Tenant_ID__c = :tenantId AND Is_Active__c = true
            LIMIT 1
        ];
        return relatedOpp;
    }

    private void logError(List<API_Error_Log__c> logs, Exception e, HttpResponse response, Incoming_Request__c request) {
        API_Error_Log__c newError = new API_Error_Log__c(
            Error_Message__c = 'Error processing Account, Opportunity or incoming SKU: ' + e.getMessage() + ', Line #: ' + e.getLineNumber(),
            HTTP_Status_Code__c = response?.getStatusCode(),
            Status__c = response?.getStatus(),
            Incoming_Request_Tenant_ID__c = request?.Tenant_ID__c
        );
        apiErrorLogsToInsert.add(newError);
    }
    

    private void logErrorResponse(List<API_Error_Log__c> logs, IncomingRequestJSONParse jsonResp, HttpResponse response) {
        apiErrorLogsToInsert.add(new API_Error_Log__c(
            Error_Message__c = String.join(jsonResp?.Errors, ','),
            HTTP_Status_Code__c = response?.getStatusCode(),
            Status__c = response?.getStatus()
        ));
    }

    global void finish(Database.BatchableContext bc) {}
    
}
