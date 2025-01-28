public class AccountPartnerClientQueueable implements Queueable, Database.AllowsCallouts {
    private static final String ENDPOINT;
    private String clientId;
    private String partnerAcctId;
    private Boolean isOnboarding;

    private AccountTrialWrapper wrapper;

    static {
        Boolean isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
        if (isSandbox) {
            ENDPOINT = 'https://qa.dearsystems.com/salesforce/api/v1/partnerclientrelationship';
        } else {
            ENDPOINT = 'https://dearsystems.com/salesforce/api/v1/partnerclientrelationship';
        }
    }

    // Constructor for use when chained POST from AccountTrialCreationQueueable
    public AccountPartnerClientQueueable(String partnerAcctId, String clientId, Boolean isOnboarding) {
        System.debug('client ID: ' + clientId);
        System.debug('isOnboarding: ' + isOnboarding);
        System.debug('Partner Acct ID: ' + partnerAcctId);
        this.clientId = clientId;
        this.isOnboarding = isOnboarding;
        this.partnerAcctId = partnerAcctId;
    }

    public void execute(QueueableContext context) {
        doPartnerClientCallout(this.partnerAcctId, this.clientId, this.isOnboarding);
    }

    /**
     * Builds the payload for the PUT request to update the partner-client relationship.
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

        Map<String, Object> payload = new Map<String, Object>{
            'ClientID' => clientId,
            'PartnerID' => partnerAcct.DEAR_Tenant_ID__c,
            'Type' => partnerAcct.Core_Plan_Type__c == null ? '' : partnerAcct.Core_Plan_Type__c,
            'IsPartnerOnboarding' => isOnboarding == null
        };
        return JSON.serialize(payload);
    }

    /**
     * Sends the PUT request to the endpoint to update the partner-client relationship.
     *
     * @param partnerAcctId String - The partner account ID.
     * @param clientId String - The client ID.
     * @param isOnboarding Boolean - Whether the partner is in onboarding or not.
     */
    private static void doPartnerClientCallout(String partnerAcctId, String clientId, Boolean isOnboarding) {
        String requestBody = buildPayload(partnerAcctId, clientId, isOnboarding); // Fixed the method call

        HttpRequest req = new HttpRequest();
        req.setEndpoint(ENDPOINT);
        req.setMethod('POST');
        req.setHeader('Accept', '*/*');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('api-auth-applicationkey', 'D88110D6-7F86-4016-95E7-40AAC906AAC6');
        req.setBody(requestBody);
        req.setTimeout(120000);

        Http http = new Http();
        HttpResponse res = http.send(req);

        System.debug('resBody: ' + res.getBody());
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
        } else {
            Account partnerAccount = new Account(Id = partnerAcctId, Core_Last_Updated_Date__c = System.now());
            update partnerAccount;
        }
    }

}
