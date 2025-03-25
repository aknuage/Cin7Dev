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
        System.debug('oli: ' + oli);
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

    /**
     * Query for and return Account whose DEAR_Tenant_Id__c matches the Incoming Request's.
     * @param - tenantId: Tenant_Id__c value of the inserted incoming request
     * @return - Account matching the incoming request's tenant id
     * @author - akelly @ NuAge : CIN7-112 : December 2024
    */
    public static Account GetAccountByTenantId(String tenantId)
    {
        return [SELECT DEAR_Tenant_ID__c, Name, Core_Account_Create_Date__c, Core_Last_Updated_Date__c, Website,
            Partner_Type__c, BillingCountry, Core_Subscribed_Date__c, Core_Cancelled_Date__c, Subscription_Expiration_Date__c,
            BillingStreet, BillingCity, BillingState, BillingPostalCode
            FROM Account WHERE DEAR_Tenant_ID__c =: tenantId
        ];
    }
    /**
     * Retrieves the most recent active Opportunity associated with a specific tenant ID.
     * This is used to determine if a new Opportunity needs to be created or an existing one updated.
     * @param tenantId - The Tenant_Id__c from the incoming request.
     * @return - The latest active Opportunity for the given tenant ID or null if none found.
     * @author - akelly @ NuAge : CIN7-112 : December 2024
    */
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

    /**
     * Processes any additional users included in a JSON response, creating SKU entries for them.
     * This is utilized during the processing of incoming requests to ensure all user-related SKUs are considered.
     * @param jsonResp - Parsed JSON response containing additional user data.
     * @return - Updated list of SKUs including additional user SKUs.
     * @author - akelly @ NuAge : CIN7-112 : December 2024
    */
    public static List<IncomingRequestJSONParse.SKUs> ProcessAdditionalUserSkus(IncomingRequestJSONParse jsonResp)
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
        return jsonResp.Data.SKUs;
    }
    /**
     * Creates a SKU object for additional users based on the parsed JSON response.
     * This method is called to generate a SKU item for additional users to be added to an Opportunity.
     * @param jsonResp - The JSON response parsed from the incoming request.
     * @return - A SKU object representing additional users.
     * @author - akelly @ NuAge : CIN7-112 : December 2024
    */
    // public static IncomingRequestJSONParse.SKUs GetAdditionalUserSkus(IncomingRequestJSONParse jsonResp)
    // {
    //     IncomingRequestJSONParse.SKUs userSku = new IncomingRequestJSONParse.SKUs();
    //     userSku.Frequency = GetFrequencyForCoreUser(jsonResp);
    //     userSku.Name = 'Users';
    //     userSku.Quantity = jsonResp.Data.AdditionalUsers;
    //     userSku.Total = jsonResp.Data.AdditionalUsersCost;
    //     return userSku;
    // }

    /**
     * Retrieves a map of PriceBookEntry Ids keyed by ProductCode, filtering by standard pricebook.
     * This map is essential for determining the correct pricebook entries during opportunity line item creation.
     * @return - Map of ProductCode to PriceBookEntry Id for all entries in the standard pricebook.
     * @author - akelly @ NuAge : CIN7-112 : December 2024
    */
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

    /**
     * Updates account fields based on data parsed from the incoming request's response JSON.
     * This method ensures the account record is in sync with the most recent data received.
     * @param acc - The Account to update.
     * @param jsonResp - The JSON response parsed from the incoming request containing account update data.
     * @return - The updated Account object.
     * @author - akelly @ NuAge : CIN7-112 : December 2024
    */
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
     * Log errors which were a result of a caught exception, typically in DML, SOQL, etc, rather
     * than from errors in the callout's JSON response.
     * 
     * @param ex - caught Exception
     * @param errorMessage Detailed error message to be logged.
     * @param request The associated Incoming_Request__c record that led to the error.
     * @return List<API_Error_Log__c> - return calling class' error logs, with addition of the newly created record.
     * @author akelly @ Nuage : CIN7-112 : December 2024
     */
    public static API_Error_Log__c LogError(Exception ex, String message, Incoming_Request__c ir, HTTPResponse response) {
        system.debug(message);
        API_Error_Log__c newError = new API_Error_Log__c(
            Error_Message__c = message,
            HTTP_Status_Code__c = response?.getStatusCode(),
            Status__c = response?.getStatus(),
            Incoming_Request_Tenant_ID__c = ir?.Tenant_ID__c
        );
        return newError;
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
     * @author akelly @ NuAge : Cin7-112 : December 2024
     */
    public static API_Error_Log__c LogResponseError(IncomingRequestJSONParse jsonResp, HttpResponse response) {
        API_Error_Log__c newError = new API_Error_Log__c(
            Error_Message__c = String.join(jsonResp?.Errors, ','),
            HTTP_Status_Code__c = response?.getStatusCode(),
            Status__c = response?.getStatus()
        );
        return newError;
    }

    /**
     * Creates a new Opportunity based on an existing one, with updates from the parsed 
     * callout response from an inserted incoming request.
     * This method is utilized to generate a new Opportunity when conditions from the incoming request
     * require a change that warrants a separate Opportunity record.
     * @param oldOpp - The existing Opportunity to base the new one on.
     * @param ir - The incoming request containing the update or change information.
     * @param recordTypeId - The record type ID to be set for the new Opportunity.
     * @return - A new Opportunity instance ready to be inserted.
     * @author - akelly @ NuAge : CIN7-112 : December 2024
    */
    public static Opportunity GetNewOpp(Opportunity oldOpp, Incoming_Request__c ir, Id recordTypeId)
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

    /**
     * Determines whether a new Opportunity should be created based on the SKU details from an incoming request.
     * This method checks if there are discrepancies in product quantities or unit prices that would necessitate
     * creating a new Opportunity rather than updating an existing one.
     * @param sku - SKU details from the incoming request.
     * @param oldOpp - The existing Opportunity to compare against.
     * @return - True if a new Opportunity should be created; otherwise, false.
     * @author - akelly @ NuAge : CIN7-112 : December 2024
    */
    public static Boolean ShouldCreateOpp(
        Boolean createNewOpp, 
        Opportunity oldOpp, 
        IncomingRequestJSONParse.SKUs sku
    ) {
        if (createNewOpp) return true; // Skip analysis if already creating a new Opportunity

        Boolean skuFound = false;

        for (OpportunityLineItem oldOli : oldOpp.OpportunityLineItems) {
            System.debug('try matching old oli');

            // Check if SKU exists in the prior opportunity
            if (oldOli.PriceBookEntry.ProductCode == sku.Name) {
                System.debug('found matching sku');
                skuFound = true;

                // Check if quantities match
                if (oldOli.Quantity != sku.Quantity) {
                    System.debug('Quantities don\'t match');
                    return true; // New Opp needed
                }

                // Check if amounts match
                if (oldOli.UnitPrice != IncomingRequestHelper.calculateUnitPriceForCoreSku(sku)) {
                    System.debug('Amounts don\'t match');
                    return true; // New Opp needed
                }
            }
        }

        // If no matching SKU was found, a new Opportunity is needed
        if (!skuFound) {
            return true; // New Opp needed
        }

        return false; // No new Opportunity needed
    }

    public class ContactJobInputWrapper {
        public List<IncomingRequestJSONParse.Users> users;
        public String tenantId;
        
        public ContactJobInputWrapper(List<IncomingRequestJSONParse.Users> users, String tenantId) {
            this.users = users;
            this.tenantId = tenantId;
        }
    }

}