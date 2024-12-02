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
}