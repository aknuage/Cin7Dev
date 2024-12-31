/**
 * @description       : 
 * @author            : AKelly | NuAge Experts
 * @group             : 
 * @last modified on  : 01-10-2024
 * @last modified by  : AS | NuAge Experts
**/
public class AccountTrialCreationQueueable implements Queueable {
    // Define the endpoint URL
    private static final String ENDPOINT = 'https://qa.dearsystems.com/salesforce/api/v1/createaccount';

    // Instance variable to hold the Account being processed
    private Account acc;

    // Constructor to accept the Account being passed to the queueable job
    public AccountTrialCreationQueueable(Account acc) {
        this.acc = acc;
    }

    // The execute method that Salesforce will call to run the job
    public void execute(QueueableContext context) {
        // Check that the account status is valid
        if (isValidAccount(acc)) {
            // Create the JSON payload
            String requestBody = buildRequestBody(acc);

            // Make the HTTP request to the API endpoint
            HttpRequest req = new HttpRequest();
            req.setEndpoint(ENDPOINT);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('api-auth-applicationkey', 'D88110D6-7F86-4016-95E7-40AAC906AAC6');
            req.setBody(requestBody);

            Http http = new Http();
            HttpResponse res = http.send(req);

            // Handle the response
            handleResponse(res, acc);
        } else {
            System.debug('Account does not meet criteria for trial creation');
        }
    }

    // Check if the account is valid for trial creation based on its status
    private static Boolean isValidAccount(Account acc) {
        List<String> invalidStatuses = new List<String>{
            'Live', 'Client', 'Onboarding', 'Cancelled', 'Cancelled Before Live', 'Cancelled After Live'
        };

        // Ensure that the account status is not in the invalid list
        return !invalidStatuses.contains(acc.Platform_Account_Status__c);
    }

    // Build the JSON request body for the API callout
    private static String buildRequestBody(Account acc) {
        // Map the Account fields to the API fields
        Map<String, Object> payload = new Map<String, Object>{
            'Email' => acc.BillingEmail__c,
            'ContactName' => acc.Referral_Contact__r.Name, // TODO: Is this necessary??
            'CompanyName' => acc.Name,  // Assuming Account Name is the company name
            'Phone' => acc.Phone,
            'AddressLine1' => acc.BillingStreet,
            'City' => acc.BillingCity,
            'State' => acc.BillingState,
            'ZipPostcode' => acc.BillingPostalCode,
            'Country' => acc.BillingCountry,
            'Timezone' => 'America/Los_Angeles',  // Use appropriate timezone
            'Industry' => acc.Industry,
            'TrialDays' => 30,  // Set trial days
            'DemoData' => 'no',  // Adjust according to needs
            'IsPartnerOnboarding' => acc.Partner_Onboarding__c
        };

        return JSON.serialize(payload);
    }

    // Handle the response from the API
    private static void handleResponse(HttpResponse res, Account acc) {
        if (res.getStatusCode() == 200) {
            // Parse the response to get TenantID and RequestID
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            
            // Deserialize the 'Data' part of the response into a Map
            Map<String, Object> dataMap = (Map<String, Object>) responseMap.get('Data');
            
            // Extract TenantID and RequestID from the 'Data' Map
            String tenantId = (String) dataMap.get('TenantID');
            String requestId = (String) dataMap.get('RequestID');

            // Store the TenantID and RequestID on the Account
            acc.DEAR_Tenant_ID__c = tenantId;
            // acc.Request_ID__c = requestId;  // Uncomment if you want to store the RequestID as well

            // Optionally, send the activation email (you'll need to implement email logic here)
            sendActivationEmail(requestId);
        } else {
            // Handle error response
            Map<String, Object> errorResponse = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            System.debug('Error: ' + errorResponse);
        }
    }

    // Send an email with the activation link
    private static void sendActivationEmail(String requestId) {
        String activationLink = 'https://qa.dearsystems.com/Account/FinalizeSalesforce?ID=' + requestId;
        // Use your email logic to send an email (e.g., using Messaging.SingleEmailMessage)
        System.debug('Activation link: ' + activationLink);
    }
}
