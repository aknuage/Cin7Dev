public with sharing class IncomingRequestBatchableNewOpp implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts 
{
    private List<Incoming_Request__c> requestsToProcess;
    private Id recordTypeId;

    public IncomingRequestBatchableNewOpp(List<Incoming_Request__c> newRequests) 
    {
        // Assign local vars
        this.requestsToProcess = newRequests;
        this.recordTypeId=Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Core_Upgrade_Downgrade').getRecordTypeId();
    }

    public List<Incoming_Request__c> start(Database.BatchableContext bc) {
        return this.requestsToProcess;
    }

    public void execute(Database.BatchableContext bc, List<Incoming_Request__c> incomingRequests)
    {
        List<API_Error_Log__c> apiErrorLogsToInsert = new List<API_Error_Log__c>();

         // Get all pricebook entries related to standard pricebook and load into a map keyed by product code
         List<PriceBookEntry> pbeList = [SELECT Product2.Id, Product2.Name, Product2.ProductCode, Id FROM PriceBookEntry WHERE Pricebook2Id IN (SELECT Id FROM PriceBook2 WHERE isStandard = true)];

    Map<String,Id> pricebookEntryMap = new Map<String,Id>();
    for(PriceBookEntry pbe : pbeList)
        {
             pricebookEntryMap.put(pbe.Product2.ProductCode, pbe.Id);
         }

        // Callout to Core for customer details and process the response 
        Map<Id,Opportunity> oppsToInsertByRequestId = new Map<Id,Opportunity>();
        Map<Id,List<OpportunityLineItem>> oppLinesToInsertByRequestId = new Map<Id,List<OpportunityLineItem>>();
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        List<Account> accountsToUpdate = new List<Account>();
        for (Incoming_Request__c ir : incomingRequests)
        {
            HttpResponse response = IncomingRequestHelper.GetCoreCustomerDetails(ir.Tenant_Id__c);

            if (response == null) break;    // If null, error already recorded to API error log

            // Parse into wrapper
            IncomingRequestJSONParse jsonResp = IncomingRequestJSONParse.parse(response.getBody());
            System.debug(jsonResp);

            // Iterate response wrapper
            if (jsonResp.Errors == null)
            {
                System.debug('Process Core data');
                try
                {
                    Account acc = [SELECT DEAR_Tenant_ID__c, Name, Core_Account_Create_Date__c, Core_Last_Updated_Date__c, Website, 
                            Partner_Type__c, BillingCountry, Core_Subscribed_Date__c, Core_Cancelled_Date__c, Subscription_Expiration_Date__c,
                            BillingStreet, BillingCity, BillingState, BillingPostalCode
                            FROM Account WHERE DEAR_Tenant_ID__c =: ir.Tenant_ID__c];

                    Opportunity oldOpp = [SELECT StageName, CurrencyIsoCode, Is_Active__c, Name, AccountId, CloseDate, DEAR_Tenant_ID__c, 
                            Amount, Amount_Onboarding_Fee__c, OwnerId, (select Id, PriceBookEntry.ProductCode, Quantity, UnitPrice from OpportunityLineItems) 
                            FROM Opportunity WHERE Is_Active__c = true 
                                AND DEAR_Tenant_ID__c =: ir.Tenant_ID__c 
                                AND Amount != null 
                                AND StageName = 'Closed Won'
                                ORDER BY CreatedDate DESC LIMIT 1];

                    // Only chain queueable job if there are contacts for processing // TODO: this will ultimately be folded in to the ContactProcess pathway per CIN7-112
                    if(jsonResp.Data.Users.size()>0){
                        System.enqueueJob(new ContactProcessQueueable(jsonResp.Data.Users, jsonResp.Data.TenantID));
                    }
                                            
                    // Update Account fields from CORE API callout // TODO: this and Account query above will ultimately be folded into the UpdateAccount pathway per CIN7-112
                    if(acc != null)
                    {
                        acc.Name = jsonResp.Data.Organisation;
                        acc.Core_Account_Create_Date__c = jsonResp.Data.CreateDate;
                        acc.Core_Last_Updated_Date__c = jsonResp.Data.LastUpdatedDate;
                        acc.BillingCountry = jsonResp.Data.Country;
                        acc.Core_Subscribed_Date__c = jsonResp.Data.Subscribed;
                        acc.Core_Cancelled_Date__c = jsonResp.Data.Cancelled;
                        acc.Subscription_Expiration_Date__c = Date.valueOf(jsonResp.Data.SubscriptionExpirationDate);
                        acc.Website = jsonResp.Data.WebsiteURL;
                        acc.Partner_Type__c = jsonResp.Data.PartnerType;
                        acc.DEAR_CRM_Status__c = jsonResp.Data.Status;
                        accountsToUpdate.add(acc);
                    }

                    // RCM-87: Analyze makeup of SKUs returned. A new child opp will only be inserted if there aren't any existing 
                    // matching Opp Lines, or if all SKUs have a matching opp line, the quantities or amounts don't match
                    system.debug('processing skus');
                    Boolean createNewOpp = false;

                    // Are additional users present? If so let's add our own SKU to the list for comparison against existing opp lines
                    if (jsonResp.Data.AdditionalUsers > 0)
                    {
                        IncomingRequestJSONParse.SKUs userSku = new IncomingRequestJSONParse.SKUs();
                        userSku.Frequency = IncomingRequestHelper.GetFrequencyForCoreUser(jsonResp);
                        userSku.Name = 'Users';
                        userSku.Quantity = jsonResp.Data.AdditionalUsers;
                        userSku.Total = jsonResp.Data.AdditionalUsersCost;

                        jsonResp.Data.SKUs.add(userSku);
                    }

                    for (IncomingRequestJSONParse.SKUs sku : jsonResp.Data.SKUs)
                    {
                        system.debug('Processing sku: ' + sku);

                        // Create the opp line in case we need it
                        if (oppLinesToInsertByRequestId.get(ir.Id) == null) oppLinesToInsertByRequestId.put(ir.Id, new List<OpportunityLineItem>());
                        oppLinesToInsertByRequestId.get(ir.Id).add(IncomingRequestHelper.CreateOppLineItem(sku, pricebookEntryMap));
                        
                        // If we're already creating a new opp for this request, we don't need to compare the SKU against prior opp line
                        if (createNewOpp)
                        {
                            system.debug('Skip SKU analysis, already creating Opp');
                            continue;
                        }

                        Boolean skuFound = false;

                        for (OpportunityLineItem oldOli : oldOpp.OpportunityLineItems)
                        {
                            system.debug('try matching old oli');    

                            // Does this SKU exist in the prior opp?
                            if (oldOli.PriceBookEntry.ProductCode == sku.Name) 
                            {
                                system.debug('found matching sku');
                                skuFound = true;

                                // Do quantities match? If not, we need a new opp
                                if (oldOli.Quantity != sku.Quantity)
                                {
                                    system.debug('Quantities don\'t match');
                                    createNewOpp = true;
                                    continue;
                                } 

                                // Do the amounts match? If not, we need a new opp
                                if (oldOli.UnitPrice != IncomingRequestHelper.calculateUnitPriceForCoreSku(sku)) 
                                {
                                    system.debug('Amounts don\'t match');
                                    createNewOpp = true;
                                    continue;
                                }
                            }
                        } 
                        // If we didn't find matching sku, create new opportunity
                        if (!skuFound) createNewOpp = true;
                    }

                    // If we're not creating a new opp it's because all SKUs match the lines of the existing opp. Remove the provisional opp lines we created
                    if (createNewOpp == false && oppLinesToInsertByRequestId.get(ir.Id) != null)
                    {
                        oppLinesToInsertByRequestId.remove(ir.Id);
                    }
                    // Otherwise create a new opp
                    else
                    {
                        system.debug('creating new opp');                        
                        oppsToInsertByRequestId.put(ir.Id, new Opportunity(
                            Name = oldOpp.Name,
                            CloseDate = System.today(),
                            AccountId = oldOpp.AccountId,
                            StageName = 'Closed Won',
                            Is_Active__c = true,
                            RecordTypeId = this.recordTypeId,
                            DEAR_Tenant_ID__c = oldOpp.DEAR_Tenant_ID__c,
                            Parent_Opportunity__c = oldOpp.Id,
                            Description = ir.Message__c,
                            OwnerId = oldOpp.OwnerId)                                    
                        );

                        // And because we have a new opp, we'll need to deactivate the old
                        system.debug('updating old opp');
                        oppsToUpdate.add(new Opportunity(Id = oldOpp.Id, Is_Active__c = false));
                    }
                }
                catch(Exception e)
                {
                    system.debug('Error processing account, opportunity or incoming SKU');

                    API_Error_Log__c newError = new API_Error_Log__c(
                        Error_Message__c = 'Error processing Account, Opportunity or incoming SKU: ' + e.getMessage() + ', Line #: ' + e.getLineNumber(),
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

        // DML

        // Insert new opps
        if(oppsToInsertByRequestId.size() > 0) 
        {
            insert oppsToInsertByRequestId.values();

            // Now insert opp lines
            List<OpportunityLineItem> oppLinesToInsert = new List<OpportunityLineItem>();
            for (Id irId : oppsToInsertByRequestId.keySet()) {
                List<OpportunityLineItem> oliList = oppLinesToInsertByRequestId.get(irId);
                
                if (oliList != null) {
                    for (OpportunityLineItem oli : oliList) {
                        Opportunity o = oppsToInsertByRequestId.get(irId);
                        if (o != null) oli.OpportunityId = o.Id;
                        oppLinesToInsert.add(oli);
                    }
                }
            }

            if (oppLinesToInsert.size() > 0) insert oppLinesToInsert;
        }

        if(accountsToUpdate.size() > 0) update accountsToUpdate;
        if (oppsToUpdate.size() > 0) update oppsToUpdate;
        if (apiErrorLogsToInsert.size() > 0) insert apiErrorLogsToInsert;
    }

    public void finish(Database.BatchableContext bc) { }

}