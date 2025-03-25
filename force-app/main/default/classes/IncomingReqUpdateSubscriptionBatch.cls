global class IncomingReqUpdateSubscriptionBatch implements Database.Batchable < sObject > , Database.AllowsCallouts {

    private Id recordTypeId;
    private List < Incoming_Request__c > requestsToProcess;
    private static IncomingRequestHelper.ContactJobInputWrapper contactJob;

    public IncomingReqUpdateSubscriptionBatch(List < Incoming_Request__c > newRequests) {
        this.requestsToProcess = newRequests;
        this.recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Core_Upgrade_Downgrade').getRecordTypeId();
    }

    public List < Incoming_Request__c > start(Database.BatchableContext bc) {
        return requestsToProcess;
    }

    public void execute(Database.BatchableContext bc, List < Incoming_Request__c > requests) {

        List < Account > accountsToUpdate = new List < Account > ();
        List < Opportunity > oppsToUpdate = new List < Opportunity > ();
        List < API_Error_Log__c > apiErrorLogsToInsert = new List < API_Error_Log__c > ();
        Map < String, Id > pricebookEntryMap = IncomingRequestHelper.GetPricebookEntryMap();
        Map < Id, Opportunity > oppsToInsertByRequestId = new Map < Id, Opportunity > ();
        Map < Id, List < OpportunityLineItem >> oppLinesToInsertByRequestId = new Map < Id, List < OpportunityLineItem >> ();

        for (Incoming_Request__c ir: requests) {
            String tenantId = ir.Tenant_ID__c;
            HttpResponse response = IncomingRequestHelper.GetCoreCustomerDetails(tenantId);

            if (response == null) break; // If null, error already recorded to API error log

            // Parse into wrapper
            IncomingRequestJSONParse jsonResp = IncomingRequestJSONParse.parse(response.getBody());
            System.debug('jsonResp: ' + JSON.serialize(jsonResp));
            
            // Check for Error in Response
            if (jsonResp.Errors == null) 
            {
                try {
                    Account acc = IncomingRequestHelper.GetAccountByTenantId(tenantId);
                    Opportunity oldOpp = IncomingRequestHelper.GetOldOppByTenantId(tenantId);

                    // Only chain queueable job if there are contacts for processing
                    if (jsonResp.Data.Users.size() > 0) {
                        contactJob = new IncomingRequestHelper.ContactJobInputWrapper(jsonResp.Data.Users, jsonResp.Data.TenantID);
                    }

                    Boolean createNewOpp = false; // move to helper method

                    if (acc != null) {
                        accountsToUpdate.add(
                            IncomingRequestHelper.ProcessAccountUpdates(acc, jsonResp)
                        );
                    }
                    // Add Additional Users to SKUs if present in the data
                    jsonResp.Data.SKUs = IncomingRequestHelper.ProcessAdditionalUserSkus(jsonResp);

                    for (IncomingRequestJSONParse.SKUs sku: jsonResp.Data.SKUs) {
                        // Create the opp line in case we need it
                        if (oppLinesToInsertByRequestId.get(ir.Id) == null) {
                            oppLinesToInsertByRequestId.put(ir.Id, new List < OpportunityLineItem > ());
                        }
                        oppLinesToInsertByRequestId.get(ir.Id).add(IncomingRequestHelper.CreateOppLineItem(sku, pricebookEntryMap));

                        if (createNewOpp) continue; // Skip SKU analysis, already creating Opp

                        // Call the utility method
                        createNewOpp = IncomingRequestHelper.ShouldCreateOpp(createNewOpp, oldOpp, sku);
                        System.debug('create new opp? ' + createNewOpp);
                    }

                    // If we're not creating a new opp it's because all SKUs match the lines of the existing opp. Remove the provisional opp lines we created
                    if (createNewOpp == false && oppLinesToInsertByRequestId.get(ir.Id) != null) {
                        oppLinesToInsertByRequestId.remove(ir.Id);
                    } else {
                        oppsToInsertByRequestId.put(ir.Id, IncomingRequestHelper.GetNewOpp(oldOpp, ir, this.recordTypeId));
                        // And because we have a new opp, we'll need to deactivate the old
                        oppsToUpdate.add(new Opportunity(Id = oldOpp.Id, Is_Active__c = false));
                    }
                } catch (Exception ex) {
                    String errorMsg = 'Error processing Account, Opportunity or incoming SKU: ' + ex.getMessage() + ', Line #: ' + ex.getLineNumber();
                    apiErrorLogsToInsert.add(IncomingRequestHelper.LogError(ex, errorMsg, ir, response));
                }
            }
            else {
                apiErrorLogsToInsert.add(IncomingRequestHelper.LogResponseError(jsonResp, response));
            }
        }

        // DML
        // insert new Opps
        IncomingRequestHelper.InsertOppsAndLineItems(oppsToInsertByRequestId, oppLinesToInsertByRequestId);
        if (accountsToUpdate.size() > 0) update accountsToUpdate;
        if (oppsToUpdate.size() > 0) update oppsToUpdate;
        if (apiErrorLogsToInsert.size() > 0) insert apiErrorLogsToInsert;

        }

        // call Queueable jobs
        public void finish(Database.BatchableContext bc) {
            if (contactJob != null) {
                System.enqueueJob(new ContactProcessQueueable(contactJob));
            }
        }
        
    }