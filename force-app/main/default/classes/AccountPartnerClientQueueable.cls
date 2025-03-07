public class AccountPartnerClientQueueable implements Queueable, Database.AllowsCallouts {
    private String clientId;
    private String partnerAcctId;
    private Boolean isOnboarding;
    private AccountTrialWrapper wrapper;

    // Constructor for use when chained POST from AccountTrialCreationQueueable
    public AccountPartnerClientQueueable(String partnerAcctId, String clientId, Boolean isOnboarding) {
        System.debug('Partner Acct ID: ' + partnerAcctId + '. isOnboarding: ' + isOnboarding);
        this.clientId = clientId;
        this.isOnboarding = isOnboarding;
        this.partnerAcctId = partnerAcctId;
    }

    public void execute(QueueableContext context) {
        doPartnerClientCallout(this.partnerAcctId, this.clientId, this.isOnboarding);
    }

    /**
     * Builds the payload for the POST request to update the partner-client relationship.
     *
     * @param partnerAcctId String - The partner account ID.
     * @param clientId String - The client ID.
     * @param isOnboarding Boolean - Whether the partner is in onboarding or not.
     * @return String - The JSON string of the payload.
     */
    private static String buildPayload(String partnerAcctId, String clientId, Boolean isOnboarding) {
        Account partnerAcct = [
            SELECT DEAR_Tenant_ID__c, Core_Plan_Type__c
            FROM Account
            WHERE Id = :partnerAcctId
            LIMIT 1
        ];
        // System.debug('isPartnerOnboarding: ' + )
        Map<String, Object> payload = new Map<String, Object>{
            'ClientID' => clientId,
            'PartnerID' => partnerAcct.DEAR_Tenant_ID__c,
            'Type' => partnerAcct.Core_Plan_Type__c == null ? '' : partnerAcct.Core_Plan_Type__c,
            'IsPartnerOnboarding' => isOnboarding == null ? false : isOnboarding
        };
        return JSON.serialize(payload);
    }

    /**
     * Sends the POST request to the endpoint to update the partner-client relationship.
     *
     * @param partnerAcctId String - The partner account ID.
     * @param clientId String - The client ID.
     * @param isOnboarding Boolean - Whether the partner is in onboarding or not.
     */
    private static void doPartnerClientCallout(String partnerAcctId, String clientId, Boolean isOnboarding) {
        String requestBody = buildPayload(partnerAcctId, clientId, isOnboarding);

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Partner_Client_Relationship');
        req.setMethod('POST');
        req.setHeader('Accept', '*/*');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(requestBody);
        req.setTimeout(120000); // Set at maximum timeout

        Http http = new Http();
        HttpResponse res = http.send(req);
        System.debug('account client partner response code: ' + res.getStatusCode());

        // If Status Code is Okay (200), record last updated time on Partner Account
        if (res.getStatusCode() == 200)
        {
            try {
                System.debug('Updating Partner Account Core Updated Date');
                Account partnerAccount = new Account(
                    Id = partnerAcctId, Core_Last_Updated_Date__c = System.now()
                );
                update partnerAccount;
            } catch (Exception ex) {
                System.debug('Error updating partner client account: ' + ex.getMessage());
            }
        }
        if (res.getBody() != null && res.getBody().length() > 0) {
            try {
                TrialAcctJSONParse jsonResp = TrialAcctJSONParse.parse(res.getBody());
                if (jsonResp.Errors != null) {
                    API_Error_Log__c newError = new API_Error_Log__c();
                    newError.Error_Message__c = String.join(jsonResp.Errors, ',');
                    newError.HTTP_Status_Code__c = res.getStatusCode();
                    newError.Status__c = res.getStatus();
                    newError.Account__c = partnerAcctId;
                    System.debug('Partner Client Account Errors: ' + newError.Error_Message__c);
                    insert newError;
                }
            } catch (Exception e) {
                // If deserialization fails, log the error
                System.debug('Error parsing response body: ' + e.getMessage());
           }
        }
    }

}