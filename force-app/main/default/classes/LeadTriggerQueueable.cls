/**
 * @description       : 
 * @author            : AS | NuAge Experts
 * @group             : 
 * @last modified on  : 02-13-2024
 * @last modified by  : AS | NuAge Experts
**/

public with sharing class LeadTriggerQueueable implements Queueable,Database.AllowsCallouts {
    private Lead nLead;
    private Cin7Account jsonObject;
    private Cin7ClientPartnerRelationship clientPartnerObject;
    private String endpoint;

    public LeadTriggerQueueable(Lead newLead, String context) {
        this.nLead = new Lead(Id = newLead.Id);
        this.endpoint = context;

        // create map of Olson timezone format
        List<Olson_Timezone_Mapping__mdt> timezoneList = [SELECT Olson_Timezone_Format__c, label FROM Olson_Timezone_Mapping__mdt];
        Map<String,String> timezoneMap = new Map<String,String>();
        for(Olson_Timezone_Mapping__mdt timezone : timezoneList){
            timezoneMap.put(timezone.label, timezone.Olson_Timezone_Format__c);
        }

        if(context == 'callout:Account_Provisions'){
            this.jsonObject = new Cin7Account();
            this.jsonObject.Email = newLead.Email == null ? '' : newLead.Email;
            this.jsonObject.ContactName = newLead.FirstName + newLead.LastName == null ? '' : newLead.FirstName + ' ' + newLead.LastName;
            this.jsonObject.CompanyName = newLead.Company == null ? '' : newLead.Company;
            this.jsonObject.Phone = newLead.Phone == null ? '' : newLead.Phone;
            this.jsonObject.AddressLine1 = newLead.Street == null ? '' : newLead.Street;
            this.jsonObject.AddressLine2 = null; 
            this.jsonObject.City = newLead.City == null ? '' : newLead.City;
            this.jsonObject.State = newLead.State == null ? '' : newLead.State;
            this.jsonObject.ZipPostcode = newLead.PostalCode == null ? '' : newLead.PostalCode;
            // translate country labels to country codes 
            this.jsonObject.Country = newLead.Country == null ? '' : Country_Code__mdt.getInstance(newLead.CountryCode).Cin7_Core_Country_Code__c;
            this.jsonObject.Timezone = newLead.Timezone__c == null ? '' : timezoneMap.get(newLead.Timezone__c);
            this.jsonObject.Industry = newLead.Core_Industry__c == null ? '' : newLead.Core_Industry__c;
            this.jsonObject.WebsiteURL = newLead.Website == null ? '' : newLead.Website;
            this.jsonObject.TrialDays = newLead.Core_Trial_Days__c == null ? null : newLead.Core_Trial_Days__c;
            this.jsonObject.DemoData = newLead.Interested_in_demo__c == true ? 'yes' : 'no';
            this.jsonObject.CouponReferralCode = newLead.Core_Coupon_Referral_Code__c == null ? null : newLead.Core_Coupon_Referral_Code__c;
        }
        
        if(context == 'callout:Partner_Account_Provisions'){
            this.jsonObject = new Cin7Account();
            this.jsonObject.Email = newLead.Email == null ? '' : newLead.Email;
            this.jsonObject.FirstName = newLead.FirstName == null ? '' : newLead.FirstName;
            this.jsonObject.LastName = newLead.LastName == null ? '' : newLead.LastName;
            this.jsonObject.CompanyName = newLead.Company == null ? '' : newLead.Company;
            this.jsonObject.Phone = newLead.Phone == null ? '' : newLead.Phone;
            this.jsonObject.Address = newLead.Street == null ? '' : newLead.Street;
            this.jsonObject.City = newLead.City == null ? '' : newLead.City;
            this.jsonObject.State = newLead.State == null ? '' : newLead.State;
            this.jsonObject.ZipPostcode = newLead.PostalCode == null ? '' : newLead.PostalCode;
            // translate country labels to country codes 
            this.jsonObject.Country = newLead.Country == null ? '' : Country_Code__mdt.getInstance(newLead.CountryCode).Cin7_Core_Country_Code__c;
            this.jsonObject.Timezone = newLead.Timezone__c == null ? '' : timezoneMap.get(newLead.Timezone__c);
            this.jsonObject.WebsiteURL = newLead.Website == null ? '' : newLead.Website;
            this.jsonObject.PaymentFrequency = newLead.Core_Payment_Frequency__c == null ? '' : newLead.Core_Payment_Frequency__c;
            this.jsonObject.Type = newLead.Core_Plan_Type__c == null ? '' : newLead.Core_Plan_Type__c;
            this.jsonObject.TenantId = newLead.DEAR_Tenant_ID__c == null ? '' : newLead.DEAR_Tenant_ID__c;
        }

        if(context == 'callout:Partner_Client_Relationship'){
            this.clientPartnerObject = new Cin7ClientPartnerRelationship();
            Account accnt = [SELECT DEAR_Tenant_ID__c,Core_Plan_Type__c FROM Account WHERE Id =: newLead.ImpartnerPRM__PartnerAccount__c];
            String planType = accnt.Core_Plan_Type__c;
            String partnerID = accnt.DEAR_Tenant_ID__c;
            this.clientPartnerObject.ClientID = newLead.DEAR_Tenant_ID__c;
            this.clientPartnerObject.PartnerID = partnerID;
            this.clientPartnerObject.Type = planType;
            this.clientPartnerObject.IsPartnerOnboarding = newLead.IsPartnerOnboarding__c;
            System.debug(this.clientPartnerObject);
        }
    }

    public void execute(QueueableContext context){
        System.debug('Entering queueable context...');

        HttpRequest req = new HttpRequest();
        if(this.endpoint == 'callout:Account_Provisions'){
            System.debug(JSON.serializePretty(this.jsonObject));
            req.setEndpoint(this.endpoint);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Accept', '*/*');
            req.setTimeout(120000);
            req.setBody(JSON.serialize(this.jsonObject));

            Http http = new Http();
            HTTPResponse resp = http.send(req);
            System.debug(resp);

            LeadTriggerJSONParse jsonResp = LeadTriggerJSONParse.parse(resp.getBody());
            System.debug('jsonResp: ' + JSON.serializePretty(jsonResp));

            if(jsonResp.Errors == null){
                this.nLead.DEAR_Tenant_ID__c = jsonResp.Data.TenantID;
                this.nLead.Core_Request_ID__c = jsonResp.Data.RequestID;
                this.nLead.Core_Last_Synced__c = System.now();
                update this.nLead;
            }
            else{
                API_Error_Log__c newError = new API_Error_Log__c();
                newError.Error_Message__c = String.join(jsonResp.Errors, ',');
                newError.HTTP_Status_Code__c = resp.getStatusCode();
                newError.Status__c = resp.getStatus();
                newError.Lead__c = this.nLead.Id;
                insert newError;
            }
        }

        if(this.endpoint == 'callout:Partner_Account_Provisions'){
            System.debug(JSON.serializePretty(this.jsonObject));
            req.setEndpoint(this.endpoint);

            if(this.jsonObject.TenantID != ''){
                req.setMethod('PUT');
            }
            else{
                req.setMethod('POST');
            }

            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Accept', '*/*');
            req.setTimeout(120000);
            req.setBody(JSON.serialize(this.jsonObject));
            system.debug(req.getEndpoint());
            system.debug(req.getHeader('api-auth-applicationkey'));
            system.debug(req.getHeader('Accept'));

            Http http = new Http();
            HTTPResponse resp = http.send(req);

            if(resp.getBody() != null && resp.getBody().length() != 0){
                LeadTriggerJSONParse jsonResp = LeadTriggerJSONParse.parse(resp.getBody());
                System.debug(jsonResp);

                if(jsonResp.Errors == null){ 
                    this.nLead.DEAR_Tenant_ID__c = jsonResp.Data.TenantID;
                    this.nLead.Core_Request_ID__c = jsonResp.Data.RequestID;
                    this.nLead.Core_Last_Synced__c = System.now();
                    update this.nLead;
                }
                else{
                    API_Error_Log__c newError = new API_Error_Log__c();
                    newError.Error_Message__c = String.join(jsonResp.Errors, ',');
                    newError.HTTP_Status_Code__c = resp.getStatusCode();
                    newError.Status__c = resp.getStatus();
                    newError.Lead__c = this.nLead.Id;
                    insert newError;
                }
            }
            else{
                this.nLead.Core_Last_Synced__c = System.now();
                update this.nLead;
            }
        }

        if(this.endpoint == 'callout:Partner_Client_Relationship'){
            System.debug(this.clientPartnerObject);
            req.setEndpoint(this.endpoint);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Accept', '*/*');
            req.setTimeout(120000);
            req.setBody(JSON.serialize(this.clientPartnerObject));

            Http http = new Http();
            HTTPResponse resp = http.send(req);
            System.debug(resp);

            if(resp.getBody() != null && resp.getBody().length() != 0){
                LeadTriggerJSONParse jsonResp = LeadTriggerJSONParse.parse(resp.getBody());
                System.debug(jsonResp);

                if(jsonResp.Errors != null){ 
                    API_Error_Log__c newError = new API_Error_Log__c();
                    newError.Error_Message__c = String.join(jsonResp.Errors, ',');
                    newError.HTTP_Status_Code__c = resp.getStatusCode();
                    newError.Status__c = resp.getStatus();
                    newError.Lead__c = this.nLead.Id;
                    insert newError;
                }
            }
            else{
                this.nLead.Core_Last_Synced__c = System.now();
                update this.nLead;
            }
        }
    }

    public class Cin7Account{
        public String Email;
        public String FirstName;
        public String LastName;
        public String ContactName;
        public String CompanyName;
        public String Phone;
        public String Address;
        public String AddressLine1;
        public String AddressLine2;
        public String City;
        public String State;
        public String ZipPostcode;
        public String Country;
        public String Timezone;
        public String Industry;
        public String WebsiteURL;
        public String PaymentFrequency;
        public String Type;
        public Decimal TrialDays;
        public String DemoData;
        public String CouponReferralCode;
        public String TenantID; // field used to update partner account info
    }

    public class Cin7ClientPartnerRelationship{
        public String PartnerID;
        public String ClientID;
        public String Type;
        public Boolean IsPartnerOnboarding;
    }
}