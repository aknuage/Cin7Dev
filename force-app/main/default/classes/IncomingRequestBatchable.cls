/**
 * @description       : 
 * @author            : AS | NuAge Experts
 * @group             : 
 * @last modified on  : 03-20-2024
 * @last modified by  : AS | NuAge Experts
**/
public with sharing class IncomingRequestBatchable implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    private List<Incoming_Request__c> newReqs;
    //private List<Lead> upsertLeads;
    private List<API_Error_Log__c> insertAPIErrorLogs;
    private List<Product2> coreProducts;
    private Map<String,Id> productMap;
    private static Map<String,Id> pricebookEntryMap;
    private List<OpportunityLineItem> oppLineItems;
    private Map<Id,OpportunityLineItem> updateOppLineItems;
    private List<String> oppProductNames;

    private List<Account> updateAccounts = new List<Account>();
    private List<Contact> updateContacts = new List<Contact>();
    private List<Opportunity> updateOpportunity;
    private Map<Id,OpportunityLineItem> deleteOppLineItems;
    

    public IncomingRequestBatchable(List<Incoming_Request__c> newBatch){
        this.newReqs = newBatch;
    }
    
    public List<Incoming_Request__c> start(Database.BatchableContext bc) {
        return this.newReqs;
    }
    public void execute(Database.BatchableContext bc, List<Incoming_Request__c> incomingRequests){
        // process each batch of records
        system.debug('In batch');
        // initialize new lists for new batch
        insertAPIErrorLogs = new List<API_Error_Log__c>();
        //upsertLeads = new List<Lead>();
        updateOpportunity = new List<Opportunity>();
        productMap = new Map<String,Id>();
        pricebookEntryMap = new Map<String,Id>();

        oppLineItems = new List<OpportunityLineItem>();
        updateOppLineItems = new Map<Id,OpportunityLineItem>();
        deleteOppLineItems = new Map<Id,OpportunityLineItem>();
        oppProductNames = new List<String>();
        
        
        // get standard pricebook id
        Id pricebook_Id = [SELECT id, Name FROM Pricebook2 WHERE isStandard = true LIMIT 1].Id;

        // get all Core Product names from custom metadata type and initialize product map
        //MB - Had to remove .getInstance as the string size it was returning was only 255 chars
        // List<String> productNames = Cin7_Core_Product__mdt.getInstance('Core_Products').Product_List__c.split(',');
        List<Cin7_Core_Product__mdt> coreProductList = [SELECT Id, Product_List__c FROM Cin7_Core_Product__mdt LIMIT 1];
        List<String> productNames = coreProductList[0].Product_List__c.split(',');
        coreProducts = [SELECT Name, Id FROM Product2 WHERE ProductCode =: productNames];
        for(Product2 prod : coreProducts){
            productMap.put(prod.Name, prod.Id);
        }

        // get all pricebook entrys related to standard pricebook and initialize pricebook entry map
        List<PriceBookEntry> pbeList = [SELECT Product2.Id, Product2.Name,Product2.ProductCode,Id FROM PriceBookEntry WHERE Pricebook2Id IN 
                                        (SELECT Id FROM PriceBook2 WHERE isStandard = true)];
        for(PriceBookEntry pbe : pbeList){
            pricebookEntryMap.put(pbe.Product2.ProductCode, pbe.Id);
        }

        //MB - Added for error handling
        List<IncomingRequestJSONParse.SKUs> newSkuList = new List<IncomingRequestJSONParse.SKUs>();
        List<IncomingRequestJSONParse.SKUs> updateSkuList = new List<IncomingRequestJSONParse.SKUs>();
        
        // invoke web service callout to get 'customer detials' endpoint
        HttpRequest req = new HttpRequest();
        for(Incoming_Request__c newReq : incomingRequests){
            req.setEndpoint('callout:Customer_Details' + '?tenantID=' + newReq.Tenant_ID__c);
            req.setMethod('GET');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Accept', '*/*');
            req.setTimeout(120000);

            HttpResponse resp;
            IncomingRequestJSONParse jsonResp;

            Http http = new Http();
            try 
            {
                resp = http.send(req);
                System.debug(resp.getBody());
                jsonResp = IncomingRequestJSONParse.parse(resp.getBody());
                System.debug(jsonResp);                    
            } 
            catch (Exception e) 
            {
                API_Error_Log__c err = new API_Error_Log__c();
                err.Error_Message__c = e.getStackTraceString() + ' ||| ' + e.getMessage();
                err.Status__c = 'System.Exception';
                err.Incoming_Request_Tenant_Id__c = newReq.Tenant_Id__c;
                if (resp != null)
                {
                    err.HTTP_Status_Code__c = resp.getStatusCode();
                    err.Error_Message__c += '\r\n' + resp.getBody();                    
                }
                insertAPIErrorLogs.add(err);  
                continue;              
            }

            if(jsonResp.Errors == null){
                System.debug('Try inserting/updating customer details...');
                try{
                    Account acc = [SELECT DEAR_Tenant_ID__c,Name,Core_Account_Create_Date__c,Core_Last_Updated_Date__c,Website,Partner_Type__c,BillingCountry,
                    Core_Subscribed_Date__c,Core_Cancelled_Date__c,Subscription_Expiration_Date__c,BillingStreet,BillingCity,BillingState,BillingPostalCode
                    FROM Account WHERE DEAR_Tenant_ID__c =: newReq.Tenant_ID__c];

                    Opportunity opp = [SELECT StageName,CurrencyIsoCode,Is_Active__c FROM Opportunity WHERE Is_Active__c = true AND DEAR_Tenant_ID__c =: newReq.Tenant_ID__c  ORDER BY CreatedDate DESC LIMIT 1];

                    // only chain queueable job if there are contacts for processing
                    if(jsonResp.Data.Users.size()>0){
                        System.enqueueJob(new ContactProcessQueueable(jsonResp.Data.Users, jsonResp.Data.TenantID));
                    }
                    
                    // get related opportunity line items
                    List<OpportunityLineItem> lineItems = [SELECT ProductCode,UnitPrice,Quantity,TotalPrice,Product2Id,OpportunityId,Id 
                    FROM OpportunityLineItem 
                    WHERE OpportunityId =: opp.Id];

                    // create map structure of ProductCode and OpportunityLineItem
                    Map<String,OpportunityLineItem> lineItemMap = new  Map<String,OpportunityLineItem>();
                    for(OpportunityLineItem line : lineItems){
                        lineItemMap.put(line.ProductCode,line);
                    }

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
                    updateAccounts.add(acc);
                    opp.StageName = 'Closed Won';
                    opp.Pricebook2Id = pricebook_Id;
                    
                    Double onboardingFee = 0;

                    // Create a SKU for "AdditionalUsers"
                    if(jsonResp.Data.AdditionalUsers > 0)
                    {
                        oppProductNames.add('Users');
                        
                        // Build the SKU
                        IncomingRequestJSONParse.SKUs addUsers = new IncomingRequestJSONParse.SKUs();
                        addUsers.Name = 'Users';
                        addUsers.Quantity = jsonResp.Data.AdditionalUsers;
                        addUsers.Total = jsonResp.Data.AdditionalUsersCost;
                        addUsers.Frequency = IncomingRequestHelper.GetFrequencyForCoreUser(jsonResp); 

                        //Check if Oppo Product alreadt exists
                        if(lineItemMap.get('Users') != null){
                            //Check if price is different on new incoming request
                            if(lineItemMap.get('Users').TotalPrice != addUsers.Total){
                                System.debug('Price Changed');
                                lineItemMap.get('Users').UnitPrice = (addUsers.Total / addUsers.Quantity);
                                updateOppLineItems.put(lineItemMap.get('Users').Id,lineItemMap.get('Users'));
                            }
                            //Check if quantity is different on new incoming request
                            if(lineItemMap.get('Users').Quantity != addUsers.Quantity){
                                System.debug('Quantity Changed');
                                lineItemMap.get('Users').Quantity = addUsers.Quantity;
                                updateOppLineItems.put(lineItemMap.get('Users').Id,lineItemMap.get('Users'));
                            }
                        }
                        //Create Oppo Product if it doesn't already exist!
                        else{
                            oppLineItems.add(createOppLineItem(addUsers,opp.Id));
                        }
                    }

                    //Insert new and update existing Opportunity Line Items price/quantity coming from Cin7 Core
                    for(IncomingRequestJSONParse.SKUs prod : jsonResp.Data.SKUs){
                        
                        oppProductNames.add(prod.Name);
                        // first check if opportunity already has line items (i.e. products)
                        if(lineItemMap.size() > 0){
                            System.debug(lineItemMap.get(prod.Name));
                            if(lineItemMap.get(prod.Name) != null){
                                System.debug('Products already exists');
                                // loop through items, if quantity/price match then skip, if different then update sync
                                if(lineItemMap.get(prod.Name).Quantity != prod.Quantity){
                                    updateSkuList.add(prod);
                                    lineItemMap.get(prod.Name).Quantity = prod.Quantity;
                                    System.debug(lineItemMap.get(prod.Name).Id);
                                    updateOppLineItems.put(lineItemMap.get(prod.Name).Id,lineItemMap.get(prod.Name));
                                }
                                if(lineItemMap.get(prod.Name).UnitPrice != prod.Total){
                                    System.debug('Difference in Price... Need to do more checking');
                                    // If Frequency = 'Yearly' check if UnitPrice is already entered in MRR
                                    if(lineItemMap.get(prod.Name).UnitPrice != ((prod.Total / prod.Quantity) / 12) && prod.Frequency == 'Yearly'){
                                        updateSkuList.add(prod);
                                        System.debug('Translating UnitPrice to MRR');
                                        lineItemMap.get(prod.Name).UnitPrice = ((prod.Total / prod.Quantity) / 12); //MB need to account for qty
                                        System.debug(lineItemMap.get(prod.Name).Id);
                                        updateOppLineItems.put(lineItemMap.get(prod.Name).Id,lineItemMap.get(prod.Name));
                                    }
                                    else if(lineItemMap.get(prod.Name).UnitPrice != (prod.Total / prod.Quantity) && prod.Frequency == 'Monthly') {
                                        updateSkuList.add(prod);
                                        System.debug('Translating UnitPrice to MRR');
                                        lineItemMap.get(prod.Name).UnitPrice = (prod.Total / prod.Quantity); //MB need to account for qty
                                        System.debug(lineItemMap.get(prod.Name).Id);
                                        updateOppLineItems.put(lineItemMap.get(prod.Name).Id,lineItemMap.get(prod.Name));
                                    }
                                    // If UnitPrice = 0 this is a onetime product which is calculated by Amount - Onboarding Fee field 
                                    if(lineItemMap.get(prod.Name).UnitPrice == 0){
                                        System.debug('Add onetime fee...');
                                        onboardingFee += prod.Total;
                                    }
                                }
                            }
                            // MB - 20230503 - If products exist on opp, but unable to find matching product, we need to add
                            else{
                                newSkuList.add(prod);
                                oppLineItems.add(createOppLineItem(prod,opp.Id));
                                if(prod.Frequency == 'onetime') onboardingFee += prod.Total;
                            }
                        }
                        // Logic for opportunity with 0 existing line items
                        // add new line items to Opportunity (i.e. products) 
                        else{
                            newSkuList.add(prod);
                            System.debug('New or One-Time Products');
                            oppLineItems.add(createOppLineItem(prod,opp.Id));
                            if(prod.Frequency == 'onetime') onboardingFee += prod.Total;
                        }
                    }
                    // If one-time ammount in SKUs enter price directly on Opportunity Onboarding Fee field
                    opp.Amount_Onboarding_Fee__c = onboardingFee;
                    updateOpportunity.add(opp);

                    //delete opportunity line items 
                    for(OpportunityLineItem oppLine : lineItemMap.values()){
                        if(!oppProductNames.contains(oppLine.ProductCode)){
                            System.debug('Not in list:' + oppLine.ProductCode);
                            deleteOppLineItems.put(oppLine.Id,oppLine);
                        }
                    }  
                    System.debug(updateOpportunity);                      
                }
                catch(QueryException e){
                    try{
                        // AK - TODO: Make this readable and create coverage
                        Lead updateLead = [SELECT Company,FirstName,LastName,Phone,Email,LastModifiedDate,Core_Account_Create_Date__c,Core_Last_Updated_Date__c,
                        Core_Subscibed_Date__c,Core_Cancelled_Date__c,Subscription_Expiration_Date__c,Country,Partner_Influence__c,Website,Partner_Type__c 
                        FROM Lead WHERE DEAR_Tenant_ID__c =: newReq.Tenant_ID__c AND IsConverted = false];
                        System.debug(Date.valueOf(jsonResp.Data.SubscriptionExpirationDate));
                        updateLead.Company = jsonResp.Data.Organisation; updateLead.Email = jsonResp.Data.Email; updateLead.Core_Account_Create_Date__c = jsonResp.Data.CreateDate;
                        updateLead.Core_Last_Updated_Date__c =jsonResp.Data.LastUpdatedDate; updateLead.Country = jsonResp.Data.Country;updateLead.Core_Subscibed_Date__c = jsonResp.Data.Subscribed;
                        updateLead.Core_Cancelled_Date__c = jsonResp.Data.Cancelled; updateLead.Subscription_Expiration_Date__c = Date.valueOf(jsonResp.Data.SubscriptionExpirationDate);updateLead.Website = jsonResp.Data.WebsiteURL;
                        updateLead.Partner_Type__c = jsonResp.Data.PartnerType;updateLead.FirstName = jsonResp.Data.Contacts[0].FirstName;updateLead.LastName = jsonResp.Data.Contacts[0].LastName;updateLead.Email = jsonResp.Data.Contacts[0].Email;
                        updateLead.Phone = jsonResp.Data.Contacts[0].Phone;
                        //upsertLeads.add(updateLead);

                        Database.LeadConvert lc = new Database.LeadConvert();lc.setLeadId(updateLead.id);

                        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
                        lc.setConvertedStatus(convertStatus.MasterLabel);

                        Database.LeadConvertResult lcr = Database.convertLead(lc);
                        System.assert(lcr.isSuccess());

                        Incoming_Request__c copyReq = new Incoming_Request__c();copyReq.Tenant_ID__c = newReq.Tenant_ID__c;copyReq.Message__c = IncomingRequestHelper.NEW_SUBSCRIPTION;
                        insert copyReq;
                    }
                    
                    catch(QueryException error){
                        API_Error_Log__c err = new API_Error_Log__c();
                        err.Error_Message__c = 'System.QueryException: ' + error.getMessage();
                        err.Status__c = 'Lead Converted or Not Found';
                        insertAPIErrorLogs.add(err);
                    }
                    
                }
                //MB added 20230501
                catch(Exception e) {
                    API_Error_Log__c err = new API_Error_Log__c();
                    err.Error_Message__c = e.getStackTraceString() + ' ||| ' +e.getMessage();
                    err.Status__c = 'System.Exception';
                    insertAPIErrorLogs.add(err);
                }
            }
            else{
                System.debug('Something went wrong when fetching customer details...');
                API_Error_Log__c newError = new API_Error_Log__c();
                newError.Error_Message__c = String.join(jsonResp.Errors, ',');
                newError.HTTP_Status_Code__c = resp.getStatusCode();
                newError.Status__c = resp.getStatus();
                insertAPIErrorLogs.add(newError);
            }
        }

        Database.SaveResult[] oliResults = Database.insert(oppLineItems,false);
        Integer oliIdx = 0;
        for(Database.SaveResult sr : oliResults) {
            if(!sr.isSuccess()) {
                IncomingRequestJSONParse.SKUs sku = newSkuList.size() > oliIdx ? newSkuList[oliIdx] : null;
                API_Error_Log__c newError = new API_Error_Log__c();
                newError.Error_Message__c = sr.getErrors() + '. Product attributes: ' + JSON.serialize(sku);
                
                insertAPIErrorLogs.add(newError);
            }
            oliIdx++;
        }

        Database.SaveResult[] updateOliResults = Database.update(updateOppLineItems.values(),false);
        Integer uOliIdx = 0;
        for(Database.SaveResult sr : updateOliResults) {
            if(!sr.isSuccess()) {
                IncomingRequestJSONParse.SKUs sku = updateSkuList.size() > uOliIdx ? updateSkuList[uOliIdx] : null;
                API_Error_Log__c newError = new API_Error_Log__c();
                newError.Error_Message__c = sr.getErrors() + '. Product attributes: ' + JSON.serialize(sku);
                
                insertAPIErrorLogs.add(newError);
            }
            uOliIdx++;
        }

        delete deleteOppLineItems.values();

        update updateOpportunity;

        insert insertAPIErrorLogs;
    }

    private static OpportunityLineItem createOppLineItem(IncomingRequestJSONParse.SKUs prod, Id oppId ) {
        OpportunityLineItem oli = new OpportunityLineItem();
        if(prod.Frequency == 'onetime'){
            oli.OpportunityId = oppId;
            oli.Quantity = prod.Quantity;
            oli.UnitPrice = 0;
            oli.PricebookEntryId = pricebookEntryMap.get(prod.Name);
            oli.Core_Amount__c = prod.Total;

        }
        // alway enter the unit price based on monthly amounts
        else if(prod.Frequency == 'Yearly'){
            oli.OpportunityId = oppId;
            oli.Quantity = prod.Quantity;
            oli.UnitPrice = ((prod.Total / prod.Quantity) / 12); // MB need to account for qty as well
            oli.PricebookEntryId = pricebookEntryMap.get(prod.Name);
            oli.Core_Amount__c = prod.Total;
            oli.Billing_Frequency__c = prod.Frequency;
        }
        else{
            oli.OpportunityId = oppId;
            oli.Quantity = prod.Quantity;
            oli.UnitPrice = prod.Total / prod.Quantity; // MB need to account for qty as well
            oli.PricebookEntryId = pricebookEntryMap.get(prod.Name);
            oli.Core_Amount__c = prod.Total;
            oli.Billing_Frequency__c = prod.Frequency;
        }
        return oli;

    }

    public void finish(Database.BatchableContext bc){
        // execute any post-processing operations
        update updateAccounts;
        update updateContacts;

    }
}