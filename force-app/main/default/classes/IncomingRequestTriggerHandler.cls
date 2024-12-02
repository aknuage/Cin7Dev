/**
 * @description       : 
 * @author            : AS | NuAge Experts
 * @group             : 
 * @last modified on  : 10-31-2023
 * @last modified by  : AS | NuAge Experts
**/
public with sharing class IncomingRequestTriggerHandler 
{
    public static void RouteIncomingRequests(List<Incoming_Request__c> incomingRequests) 
    {
        // Create collections for each type of request, keyed by request type
        Map<IncomingRequestHelper.RequestType, List<Incoming_Request__c>> requestRoutingMap = new Map<IncomingRequestHelper.RequestType, List<Incoming_Request__c>>();

        // Categorize each request by request type
        for(Incoming_Request__c req : incomingRequests)
        {
            // Decode request type
            IncomingRequestHelper.RequestType reqType;
            try { reqType = IncomingRequestHelper.RequestType.valueOf(req.Message__c); }
            catch (Exception e) { reqType = IncomingRequestHelper.RequestType.Other; } 

            // Load request into routing map
            if (reqType != null)
            {
                if (requestRoutingMap.get(reqType) == null) requestRoutingMap.put(reqType, new List<Incoming_Request__c>());
                requestRoutingMap.get(reqType).add(req);
            }
            else system.debug('Unknown error decoding Incoming Request with Tenant Id: ' + req.Tenant_Id__c + ', and Message: ' + req.Message__c);
        }
        system.debug(requestRoutingMap);

        // Send routing Map to Incoming Request Queueable to callout for Core data
        for (IncomingRequestHelper.RequestType rt : requestRoutingMap.keyset())
        {
            List<Incoming_Request__c> irList = requestRoutingMap.get(rt);

            if (irlist.size() >0)
            {
                System.enqueueJob(new IncomingRequestQueueable(rt, irList));
            }
        }
    }
}