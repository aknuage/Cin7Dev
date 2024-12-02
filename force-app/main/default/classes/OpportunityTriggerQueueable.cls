/**
 * @description       : 
 * @author            : AS | NuAge Experts
 * @group             : 
 * @last modified on  : 12-11-2023
 * @last modified by  : AS | NuAge Experts
**/

public without sharing class OpportunityTriggerQueueable implements Queueable,Database.AllowsCallouts {
    private Opportunity oppDiscount; 
    private Cin7Discount jsonBody;
    private String calloutMethod;
    public OpportunityTriggerQueueable(Opportunity Opp) {
        this.oppDiscount = new Opportunity (Id = Opp.Id);

        this.jsonBody = new Cin7Discount();
        
        this.jsonBody.TenantID = Opp.DEAR_Tenant_ID__c;
        this.jsonBody.Discount = Opp.Discount__c;
        this.jsonBody.ExpirationDate = Opp.Discount_Expiration_Date__c;
        this.jsonBody.Username = Opp.Discount_Username__c;
        this.jsonBody.SubscriptionFeatureGroup = Opp.Subscription_Discount_Feature_Group__c;

        this.calloutMethod = 'POST';
    }

    public OpportunityTriggerQueueable(Opportunity Opp, String methodReq) {
        this.oppDiscount = new Opportunity (Id = Opp.Id);

        this.jsonBody = new Cin7Discount();
        
        this.jsonBody.TenantID = Opp.DEAR_Tenant_ID__c;
        this.jsonBody.Discount = Opp.Discount__c;
        this.jsonBody.ExpirationDate = Opp.Discount_Expiration_Date__c;
        this.jsonBody.Username = Opp.Discount_Username__c;
        this.jsonBody.DiscountID = Opp.Core_Discount_ID__c;
        this.jsonBody.SubscriptionFeatureGroup = Opp.Subscription_Discount_Feature_Group__c;

        this.calloutMethod = methodReq;
    }

    public void execute(QueueableContext context){
        HttpRequest req = new HttpRequest();


        req.setEndpoint('callout:Discounts');
        req.setMethod(this.calloutMethod);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', '*/*');
        req.setTimeout(120000);

        System.debug(JSON.serialize(this.jsonBody));
        req.setBody(JSON.serialize(this.jsonBody));

        Http http = new Http();
        HTTPResponse resp = http.send(req);

        if(this.calloutMethod == 'PUT'){
            if(resp.getStatusCode() == 200){
                this.oppDiscount.Core_Sync_Date__c = System.now();
                update this.oppDiscount;
            }
            else{
                DiscountParse jsonResp = DiscountParse.parse(resp.getBody());
                
                API_Error_Log__c newError = new API_Error_Log__c();
                newError.Error_Message__c = String.join(jsonResp.Errors, ',');
                newError.HTTP_Status_Code__c = resp.getStatusCode();
                newError.Status__c = resp.getStatus();
                insert newError;
            }
        }
        
        else{
            DiscountParse jsonResp = DiscountParse.parse(resp.getBody());
            System.debug(jsonResp);

            if(jsonResp.Errors == null){
                this.oppDiscount.Core_Discount_ID__c = jsonResp.Data.DiscountID;
                this.oppDiscount.Core_Sync_Date__c = System.now();
                update this.oppDiscount;
            }
            else{
                API_Error_Log__c newError = new API_Error_Log__c();
                newError.Error_Message__c = String.join(jsonResp.Errors, ',');
                newError.HTTP_Status_Code__c = resp.getStatusCode();
                newError.Status__c = resp.getStatus();
                insert newError;
            }
        }
        
    }

    public class Cin7Discount{
        public Date ExpirationDate;
        public String TenantID;
        public Double Discount;
        public String Username;
        public String DiscountID;
        public String SubscriptionFeatureGroup;
    }
}