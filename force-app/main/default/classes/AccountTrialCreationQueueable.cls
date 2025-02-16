/**
 * Queueable job to process account trial creation and partner-client relationship updates.
 * This job handles POST and PUT requests to create accounts and manage partner relationships.
 *
 * @author         : Anthony Kelly - AKelly @ Nuage - Cin7-120
 * @date           : January 2025
 */
public class AccountTrialCreationQueueable implements Queueable, Database.AllowsCallouts {
    private static String clientTenantId;
    private AccountTrialWrapper wrapper;
    
    /**
     * Constructor to accept the AccountWrapper from Invocable Method.
     * Initializes timezoneMap with Olson timezone formats.
     *
     * @param wrapper AccountTrialWrapper instance containing account and contact data.
     * @author Anthony Kelly
     * @date January 2025
     */
    public AccountTrialCreationQueueable(AccountTrialWrapper wrapper) {
        this.wrapper = wrapper;
    }

    public static string GetTimeZone(String tz) {
        Map < String, String > tzMap = new Map < String, String > ();
        List < Olson_Timezone_Mapping__mdt > timezoneList = [SELECT Olson_Timezone_Format__c, label FROM Olson_Timezone_Mapping__mdt];
        for (Olson_Timezone_Mapping__mdt timezone: timezoneList) {
            tzMap.put(timezone.label, timezone.Olson_Timezone_Format__c);
        }
        return tzMap.get(tz);
    }

    /**
     * Executes the queueable job by invoking the POST request.
     *
     * @param context QueueableContext, used by the system.
     * @author Anthony Kelly
     * @date January 2025
     */
    public void execute(QueueableContext context) {
        // System.debug('ctx wrapper: ' + JSON.serializePretty(this.wrapper));
        doTrialAccountCallout(this.wrapper);
    }

    /**
     * Validates if the account status is valid for trial creation.
     *
     * @param platformAccountStatus String value for the account's platform status.
     * @return Boolean - True if the account is valid for trial creation, false otherwise.
     * @author Anthony Kelly
     * @date January 2025
     */
    private static Boolean isValidAccount(String platformAccountStatus) {
        List < String > invalidStatuses = new List < String > {
            'Live', 'Client', 'Onboarding', 'Cancelled', 
            'Cancelled Before Live', 'Cancelled After Live'
        };
        return !invalidStatuses.contains(platformAccountStatus);
    }

    /**
     * Builds the request body for the POST request to create a trial account.
     *
     * @param wrapper AccountTrialWrapper instance containing account data.
     * @return String - JSON string of the payload for the POST request.
     * @author Anthony Kelly
     * @date January 2025
     */
    @TestVisible
    private static String buildProvisionTrialBody(AccountTrialWrapper wrapper) {
        Map < String, String > countryCodeMap = getCountryCodeMap();
        String country = wrapper.BillingCountry ?.toLowerCase();
        String countryCode = countryCodeMap.get(country);

        String demoDataStr;
        // Handle null demo data
        if (wrapper.demoData != null) {
            demoDataStr = wrapper.demoData ? 'yes' : 'no';
        } else {
            demoDataStr = 'no';
        }

        String timezone = GetTimeZone(wrapper.timeZone);

        // Construct the payload as per the API specifications
        Map < String, Object > payload = new Map < String, Object > {
            'Email' => wrapper.contactEmail,
            'ContactName' => wrapper.contactName,
            'CompanyName' => wrapper.accountName,
            'Phone' => wrapper.contactPhone,
            'AddressLine1' => wrapper.billingStreet,
            'City' => wrapper.billingCity,
            'State' => wrapper.billingState,
            'ZipPostcode' => wrapper.billingPostalCode,
            'Country' => countryCode,
            'Timezone' => timezone,
            'WebsiteURL' => wrapper.websiteURL,
            'Industry' => wrapper.coreIndustry,
            'TrialDays' => wrapper.trialDays,
            'DemoData' => demoDataStr,
            'IsPartnerOnboarding' => wrapper.partnerAccount == null ? false : wrapper.partnerOnboarding,
            'CouponReferralCode' => wrapper.couponReferralCode
        };

        return JSON.serialize(payload);
    }

    /**
     * Sends the POST request to the endpoint to create the trial account.
     *
     * @param wrapper AccountTrialWrapper instance containing account data.
     * @return HTTPResponse - The response from the API.
     * @author Anthony Kelly
     * @date January 2025
     */
    private static void doTrialAccountCallout(AccountTrialWrapper wrapper) {
        if (isValidAccount(wrapper.platformAccountStatus)) {
            String requestBody = buildProvisionTrialBody(wrapper);

            publishTrialCreationEvent(false, wrapper.accountId, 'Queued');

            // Set up the HTTP request to the POST endpoint
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:Account_Provisions');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(requestBody);
            req.setTimeout(120000);

            Http http = new Http();
            HttpResponse res = http.send(req);

            // Handle the response from the API
            handleNewTrialResponse(res, wrapper);
        } else {
            String errorMsg = 'Exception: Account status does not meet criteria for trial creation: ' + wrapper.platformAccountStatus;
            System.debug('Account does not meet criteria for trial creation');
            publishTrialCreationEvent(false, wrapper.accountId, errorMsg);
        }
    }

    /**
     * Handles the response from the POST request to update the account with Tenant ID.
     *
     * @param res HTTPResponse - The response from the API.
     * @param wrapper AccountTrialWrapper instance containing account data.
     * @author Anthony Kelly
     * @date January 2025
     */
    private static void handleNewTrialResponse(HttpResponse res, AccountTrialWrapper wrapper) {
        try {
            if (res.getStatusCode() == 200) {
                // Parsing the JSON response
                TrialAcctJSONParse jsonResp = TrialAcctJSONParse.parse(res.getBody());
                System.debug('res body: ' + res.getBody());
                // Checking if there are errors in the response
                if (jsonResp.Errors != null) {
                    // Insert API error log
                    API_Error_Log__c newError = new API_Error_Log__c();
                    newError.Error_Message__c = String.join(jsonResp.Errors, ',');
                    newError.HTTP_Status_Code__c = res.getStatusCode();
                    newError.Status__c = res.getStatus();
                    newError.Account__c = wrapper.accountId;
                    insert newError;
                    System.debug('Provision Trial Account Errors: ' + newError.Error_Message__c);
                } else {
                    // If no errors, update the trial account
                    try {
                        Account trialAccount = new Account(
                            Id = wrapper.accountId,
                            DEAR_tenant_Id__c = jsonResp.Data.TenantID,
                            Core_Last_Updated_Date__c = System.now()
                        );
                        update trialAccount;

                        // Publish Platform Event
                        publishTrialCreationEvent(true, wrapper.accountId, 'Reload');

                        System.debug('Account Trial Creation Queueable Depth ==> ' + AsyncInfo.getCurrentQueueableStackDepth());
                        // Enqueue the AccountPartnerClientQueueable job if partnerAccount is non-null
                        if (wrapper.partnerAccount != null && String.isNotBlank(wrapper.partnerAccount)) {
                            System.enqueueJob(
                                new AccountPartnerClientQueueable(
                                    wrapper.partnerAccount, jsonResp.Data.TenantID, wrapper.partnerOnboarding
                                )
                            );
                        }
                    } catch (Exception ex) {
                        // Catch any exception while updating the trial account and log the error
                        System.debug('Exception during account update: ' + ex.getMessage());
                        String errorMsg = 'Exception updating Trial Account: ' + ex.getMessage();
                        publishTrialCreationEvent(false, wrapper.accountId, errorMsg);
                    }
                }
            }
        } catch (Exception ex) {
            // Catch any exception in the main logic and log the error
            System.debug('Exception in handleNewTrialResponse: ' + ex.getMessage());
        }
    }

    /**
     * Retrieves the country code map from custom metadata.
     *
     * @return Map<String, String> - A map of country labels to country codes.
     * @author Anthony Kelly
     * @date January 2025
     */
    private static Map < String, String > getCountryCodeMap() {
        Map < String, String > result = new Map < String, String > ();

        for (Country_Code__mdt code: [SELECT Id, MasterLabel, Cin7_Core_Country_Code__c FROM Country_Code__mdt]) {
            result.put(code.MasterLabel.toLowerCase(), code.Cin7_Core_Country_Code__c);
        }
        return result;
    }

    private static void publishTrialCreationEvent(Boolean isTrialCreated, String accountId, String message)
    {
        Trial_Account_Created__e tacEvent = new Trial_Account_Created__e(
            Trial_Created__c = isTrialCreated, 
            AccountId__c = accountId,
            Message__c = message
        );

        EventBus.publish(new List<Trial_Account_Created__e>{ tacEvent });
    }

    // CIN7-120: May need to implement if Queueable job limits keep ballooning
    // private static void chainPartnerJob(AccountTrialWrapper wrapper, TrialAcctJSONParse jsonResp) {
    //     Boolean isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
    //     integer depth = AsyncInfo.getCurrentQueueableStackDepth();

    //     if (!isSandbox) {
    //         System.enqueueJob(
    //             new AccountPartnerClientQueueable(
    //                 wrapper.partnerAccount, jsonResp.Data.TenantID, wrapper.partnerOnboarding
    //             )
    //         );
    //         // return String.valueOf(jobId);
    //     }

    //     // Allow up to 10 stacked jobs in Sandboxes, overriding Gov Limits
    //     if (isSandbox && depth >= 5) {
    //         System.enqueueJob(
    //             new AccountPartnerClientQueueable(
    //                 wrapper.partnerAccount, jsonResp.Data.TenantID, wrapper.partnerOnboarding
    //             ), 10
    //         );
    //         // return String.valueOf(jobId);
    //     }

    //     // return null;
    // }
    
}