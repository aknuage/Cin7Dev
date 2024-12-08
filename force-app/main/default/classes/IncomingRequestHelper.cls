public with sharing class IncomingRequestHelper 
{
    public static final String NEW_SUBSCRIPTION = 'NewSubscription';
    public static final String UPDATE_SUBSCRIPTION = 'UpdateSubscription';
    public static final String DISCOUNT_CHANGE = 'DiscountChange';
    public static final String CONTACT_UPDATE = 'ContactUpdate';
    public static final String RENEWAL_SUBSCRIPTION = 'RenewalSubscription';
    public static final String CANCEL_SUBSCRIPTION = 'CancelSubscription';

    public enum RequestType 
    {
        NewSubscription, 
        UpdateSubscription, 
        DiscountChange, 
        ContactUpdate, 
        RenewalSubscription, 
        CancelSubscription,
        Other
    }

    /**
     * Callout to Core for customer details
     * 
     * @param tenantId - string containing tenant Id
     * @return void
     * @author nkoonce @ NuAge : CIN7-87 : AUG 2024
     */ 
    public static HttpResponse GetCoreCustomerDetails(String tenantId)
    {
        // Build the callout
        String endpoint = 'callout:Customer_Details' + '?tenantID=' + tenantId;
        String verb = 'GET'; 
        Map<String,String> headers = new Map<String,String>();
        headers.put('Content-Type', 'application/json');
        headers.put('Accept', '*/*');

        try 
        {
            HttpResponse response = CalloutHelper.MakeCallout(endpoint, verb, null, headers);
            return response;

        } 
        catch (Exception e) 
        {
            API_Error_Log__c errLog = new API_Error_Log__c(
                Status__c = 'Callout failed',
                Incoming_Request_Tenant_Id__c = tenantId, 
                Error_Message__c = 'Core callout error, Class: CalloutHelper line #' + e.getLineNumber() + ', ' + e.getMessage()
            );
            insert errLog;
            return null;
        }
    }

    /**
     * Create an opportunity line item for an incoming SKU from Core. The assignment of its parent opportunity will be 
     * the responsibility of the caller.
     * 
     * @param sku - SKU data from Core
     * @param pbeMap - map of product code to its pricebook entry
     * @return opportunity line item built in this method
     * @author nkoonce @ NuAge : CIN7-87 : Aug 2024
     */
    public static OpportunityLineItem CreateOppLineItem(IncomingRequestJSONParse.SKUs sku, Map<String,Id> pbeMap) 
    {
        OpportunityLineItem oli = new OpportunityLineItem(
            // OpportunityId = oppId,   // This happens downstream in the caller, after the Opp is inserted
            Quantity = sku.Quantity, 
            UnitPrice = calculateUnitPriceForCoreSku(sku),
            PricebookEntryId = pbeMap.get(sku.Name), 
            Core_Amount__c = sku.Total,
            Billing_Frequency__c = sku.Frequency == 'onetime' ? null : sku.Frequency
        );

        return oli;
    }

    /**
     * Unit Price normally = SKU Total / Quantity, then if frequency is Yearly we divide by 12. During the implementation of CIN7-87
     * it was discovered that SKUs mapping to the "Users" product require the opposite behavior. In other words, when a SKU maps to "Users",
     * if the frequency is Monthly we divie by 12. When it is yearly we don't.
     * 
     * @param sku - the Core SKU that needs its unit price calculated
     * @return decimal containing the calculated unit price rounded to 2 decimal places
     * @author nkoonce @ NuAge : CIN7-87 : Aug 2024
     */
    public static Decimal CalculateUnitPriceForCoreSku(IncomingRequestJSONParse.SKUs sku)
    {
        Decimal unitPrice = sku.Total / sku.Quantity;

        if (sku.Frequency == 'onetime') unitPrice = 0;  // I don't know why we do this but it was in Adam's code so we're keeping it - NK 8-18-24
        else if (sku.Frequency == 'Yearly') unitPrice = unitPrice / 12;

        return unitPrice.setScale(2);
    }    

    /**
     * Enter with parsed json from Core. If unit price > $50 return "Yearly" else return "Monthly". Default value is "Monthly".
     * 
     * @param jsonParse parsed response from Core
     * @return string with the calculated value for frequency
     * @author nkoonce @ NuAge : CIN7-87 : Aug 2024
     */
    public static String GetFrequencyForCoreUser(IncomingRequestJSONParse jsonParse)
    {
        String returnValue = 'Monthly';

        if (jsonParse != null && jsonParse.Data != null && jsonParse.Data.AdditionalUsers != null && jsonParse.Data.AdditionalUsers > 0)
        {
            Double checkUnitPrice = (jsonParse.Data.AdditionalUsersCost / jsonParse.Data.AdditionalUsers);

            returnValue = checkUnitPrice > 50.0 ? 'Yearly' : 'Monthly';
        }

        return returnValue;
    }

    public static Account GetAccountByTenantId(String tenantId)
    {
        return [SELECT DEAR_Tenant_ID__c, Name, Core_Account_Create_Date__c, Core_Last_Updated_Date__c, Website,
            Partner_Type__c, BillingCountry, Core_Subscribed_Date__c, Core_Cancelled_Date__c, Subscription_Expiration_Date__c,
            BillingStreet, BillingCity, BillingState, BillingPostalCode
            FROM Account WHERE DEAR_Tenant_ID__c =: tenantId
        ];
    }

    public static Opportunity GetOldOppByTenantId(String tenantId)
    {
        return [SELECT StageName, CurrencyIsoCode, Is_Active__c, Name, AccountId, CloseDate, DEAR_Tenant_ID__c, 
        Amount, Amount_Onboarding_Fee__c, OwnerId, (select Id, PriceBookEntry.ProductCode, Quantity, UnitPrice from OpportunityLineItems) 
        FROM Opportunity WHERE Is_Active__c = true 
            AND DEAR_Tenant_ID__c =: tenantId 
            AND Amount != null 
            AND StageName = 'Closed Won'
            ORDER BY CreatedDate DESC LIMIT 1];
    }

    public static void ProcessAdditionalUserSkus(IncomingRequestJSONParse jsonResp)
    {
        if (jsonResp.Data.AdditionalUsers > 0)
        {
            IncomingRequestJSONParse.SKUs userSku = new IncomingRequestJSONParse.SKUs();
            userSku.Frequency = IncomingRequestHelper.GetFrequencyForCoreUser(jsonResp);
            userSku.Name = 'Users';
            userSku.Quantity = jsonResp.Data.AdditionalUsers;
            userSku.Total = jsonResp.Data.AdditionalUsersCost;
            jsonResp.Data.SKUs.add(userSku);
        }
    }

    public static Map<String, Id> GetPricebookEntryMap()
    {
        Map<String,Id> pricebookEntryMap = new Map<String,Id>();

        // Get all pricebook entries related to standard pricebook and load into a map keyed by product code
        List<PriceBookEntry> pbeList = [SELECT Product2.Id, Product2.Name, Product2.ProductCode, Id FROM PriceBookEntry WHERE Pricebook2Id IN (SELECT Id FROM PriceBook2 WHERE isStandard = true)];
        
        for(PriceBookEntry pbe : pbeList)
        {
            pricebookEntryMap.put(pbe.Product2.ProductCode, pbe.Id);
        }
        return pricebookEntryMap;
    }


    public static Account ProcessAccountUpdates(Account acc, IncomingRequestJSONParse jsonResp)
    {
        acc.Core_Account_Create_Date__c = jsonResp.Data.CreateDate;
        acc.Core_Last_Updated_Date__c = jsonResp.Data.LastUpdatedDate;
        acc.BillingCountry = jsonResp.Data.Country;
        acc.Core_Subscribed_Date__c = jsonResp.Data.Subscribed;
        acc.Core_Cancelled_Date__c = jsonResp.Data.Cancelled;
        acc.Subscription_Expiration_Date__c = Date.valueOf(jsonResp.Data.SubscriptionExpirationDate);
        acc.Website = jsonResp.Data.WebsiteURL;
        acc.Partner_Type__c = jsonResp.Data.PartnerType;
        acc.DEAR_CRM_Status__c = jsonResp.Data.Status;
        return acc;
    }

    /**
     * Logs error details from failed API responses or processing issues into the system.
     * This aids in diagnosing issues after batch execution.
     *
     * @param errorMessage Detailed error message to be logged.
     * @param request The associated Incoming_Request__c record that led to the error.
     */
    public static List<API_Error_Log__c> LogChangeError(Exception ex, List<API_Error_Log__c> apiErrorLogsToInsert, Incoming_Request__c ir, HTTPResponse response) {
        system.debug('Error processing account, opportunity or incoming SKU');

        API_Error_Log__c newError = new API_Error_Log__c(
            Error_Message__c = 'Error processing Account, Opportunity or incoming SKU: ' + ex.getMessage() + ', Line #: ' + ex.getLineNumber(),
            HTTP_Status_Code__c = response?.getStatusCode(),
            Status__c = response?.getStatus(),
            Incoming_Request_Tenant_ID__c = ir?.Tenant_ID__c
        );
        apiErrorLogsToInsert.add(newError);
        return apiErrorLogsToInsert;
    }

    public static void InsertOppsAndLineItems(Map<Id,Opportunity> oppsToInsertByRequestId, Map<Id,List<OpportunityLineItem>> oppLinesToInsertByRequestId)
    {
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
    }

    /**
     * Logs response errors when the API returns explicit error messages.
     * Adds these errors to a list for bulk insertion at the end of the batch job.
     * 
     * @param errors List of error messages returned by the API.
     * @param response The HTTP response from the API callout, used for additional context.
     */
    public static List<API_Error_Log__c> LogResponseError(List<API_Error_Log__c> apiErrorLogsToInsert, IncomingRequestJSONParse jsonResp, HttpResponse response) {
        apiErrorLogsToInsert.add(new API_Error_Log__c(
            Error_Message__c = String.join(jsonResp?.Errors, ','),
            HTTP_Status_Code__c = response?.getStatusCode(),
            Status__c = response?.getStatus()
        ));
        return apiErrorLogsToInsert;
    }

    public static IncomingRequestJSONParse.SKUs GetAdditionalUserSkus(IncomingRequestJSONParse jsonResp)
    {
        IncomingRequestJSONParse.SKUs userSku = new IncomingRequestJSONParse.SKUs();
        userSku.Frequency = GetFrequencyForCoreUser(jsonResp);
        userSku.Name = 'Users';
        userSku.Quantity = jsonResp.Data.AdditionalUsers;
        userSku.Total = jsonResp.Data.AdditionalUsersCost;
        return userSku;
    }

    public static Opportunity GetUpdatedOpp(Opportunity oldOpp, Incoming_Request__c ir, Id recordTypeId)
    {
        return new Opportunity(
            Name = oldOpp.Name,
            CloseDate = System.today(),
            AccountId = oldOpp.AccountId,
            StageName = 'Closed Won',
            Is_Active__c = true,
            RecordTypeId = recordTypeId,
            DEAR_Tenant_ID__c = oldOpp.DEAR_Tenant_ID__c,
            Parent_Opportunity__c = oldOpp.Id,
            Description = ir.Message__c,
            OwnerId = oldOpp.OwnerId,
            CurrencyIsoCode = oldOpp.CurrencyIsoCode
        ); 
    }

    public static Boolean ShouldCreateOpp(IncomingRequestJsonParse.SKUs sku, Opportunity oldOpp)
    {
            Boolean skuFound = false;
            Boolean createNewOpp = false;
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

            return createNewOpp;
    }

}