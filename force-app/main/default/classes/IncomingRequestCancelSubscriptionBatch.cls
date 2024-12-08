public with sharing class IncomingRequestCancelSubscriptionBatch implements Database.Batchable<sObject>, Database.AllowsCallouts
{
    private List<Incoming_Request__c> cancellationRequests;

    public IncomingRequestCancelSubscriptionBatch(List<Incoming_Request__c> incomingRequests) 
    {
        this.cancellationRequests = incomingRequests; 
    }    

    public List<Incoming_Request__c> start(Database.BatchableContext bc) 
    {
        return this.cancellationRequests;
    }

    public void execute(Database.BatchableContext bc, List<Incoming_Request__c> scope)
    { 
        system.debug('Running cancel subscription batch');

        List<API_Error_Log__c> apiErrorLogsToInsert = new List<API_Error_Log__c>();
        Map<String, Opportunity> tenantIdToOpportunityMap = new Map<String, Opportunity>();
        List<Opportunity> oppsToInsert = new List<Opportunity>();
        List<OpportunityLineItem> oppLinesToInsert = new List<OpportunityLineItem>();
        List<Opportunity> oppsToUpdate = new List<Opportunity>();

        try 
        {
            // Collect Tenant IDs from incomingRequests
            Set<String> tenantIds = new Set<String>();
            for (Incoming_Request__c ir : scope) {
                tenantIds.add(ir.Tenant_Id__c);
            }

            // Get most recent CW opp for each tenant Id and put in a map
            List<String> oppFieldNames = getOppFieldNames();
            List<String> oppLineFieldNames = getOppLineFieldNames();

            String oppQueryString = 'SELECT ' + String.join(oppFieldNames, ',') + ', (select ' + String.join(oppLineFieldNames, ',') + ' from OpportunityLineItems)';
            oppQueryString += ' FROM Opportunity WHERE Is_Active__c = true AND Dear_Tenant_Id__c IN :tenantIds AND Amount != null AND StageName = \'Closed Won\'';
            oppQueryString += ' ORDER BY CreatedDate DESC';        

            system.debug(oppQueryString);

            // Bulk query for all Opportunities and related Opportunity Products for cloning
            List<Opportunity> opportunities = Database.query(oppQueryString);
            
            // Map most recent qualifying opp for each tenant Id
            for (Opportunity o : opportunities)
            {
                if(tenantIdToOpportunityMap.get(o.DEAR_Tenant_Id__c) != null) continue;
                tenantIdToOpportunityMap.put(o.DEAR_Tenant_Id__c, o);
            }

            // Clone most recent opportunity for each tenant Id
            for (String tenantId : tenantIdToOpportunityMap.keySet())
            {
                Opportunity oldOpp = tenantIdToOpportunityMap.get(tenantId);
                if (oldOpp == null)
                {
                    String errMessage = 'There is no active closed won opportunity available to cancel for this tenant Id.';
                    apiErrorLogsToInsert.add(new API_Error_Log__c(Error_Message__c = errMessage, Incoming_Request_Tenant_Id__c = tenantId));
                    continue;
                } 

                // Clone opps, flag for insert
                Opportunity oppClone = oldOpp.clone();
                oppClone.Name = oppClone.Name.trim() + ' - Cancellation';
                oppsToInsert.add(oppClone);

                // Update old opp
                oldOpp.Is_Active__c = false;
                oppsToUpdate.add(oldOpp);
            }

            // DML
            if (oppsToInsert.size() > 0)
            {
                insert oppsToInsert;

                for (Opportunity o : oppsToInsert)
                {
                    List<OpportunityLineItem> oppLinesToClone = tenantIdToOpportunityMap.get(o.DEAR_Tenant_Id__c)?.OpportunityLineItems;
                    for (OpportunityLineItem oli : oppLinesToClone)
                    {
                        OpportunityLineItem oliClone = oli.clone();
                        Assert.isTrue(oliClone.Quantity != null && oliClone.Quantity != 0);
                        oliClone.UnitPrice = 0;
                        oliClone.OpportunityId = o.Id;
                        oppLinesToInsert.add(oliClone);
                    }
                }

                insert oppLinesToInsert;
            }

            if (oppsToUpdate.size() > 0) update oppsToUpdate;
        } 
        catch (Exception e) 
        {
            String errMessage = e.getMessage() + ', Class: IncomingRequestCancelSubscriptionBatch, Line #: ' + e.getLineNumber();
            apiErrorLogsToInsert.add(new API_Error_Log__c(Error_Message__c = errMessage));
        }

        if (apiErrorLogsToInsert.size() > 0) { insert apiErrorLogsToInsert; }            
    }

    private static List<String> getOppFieldNames()
    {
        List<String> fieldNames = new List<String>();

        Map<String,Schema.SObjectField> opportunityFieldsMap = Schema.SObjectType.Opportunity.fields.getMap();
        for (Schema.sobjectfield field : opportunityFieldsMap.values())
        {
            if (field.getDescribe().isCalculated() == false) fieldNames.add(field.getDescribe().getName());
        }

        return fieldNames;
    }

    private static List<String> getOppLineFieldNames()
    {
        List<String> fieldNames = new List<String>();

        Map<String,Schema.SObjectField> opportunityLineFieldsMap = Schema.SObjectType.OpportunityLineItem.fields.getMap();
        for (Schema.sobjectfield field : opportunityLineFieldsMap.values())
        {
            if (field.getDescribe().isCalculated() == false && field.getDescribe().getName() != 'TotalPrice') fieldNames.add(field.getDescribe().getName());
        }

        return fieldNames;
    }

    public void finish(Database.BatchableContext bc){ }
}