/**
 * @description       : 
 * @author            : AS | NuAge Experts
 * @group             : 
 * @last modified on  : 2023-05-11
 * @last modified by  : NuAge
**/
public with sharing class PartnerActivationQueueable implements Queueable,Database.AllowsCallouts {
    private Account newAccount;
    private Cin7Partner partner;
    public PartnerActivationQueueable() {
    }

    public PartnerActivationQueueable(Account newAcc) {
        this.newAccount = newAcc;
        this.partner = new Cin7Partner();
        this.partner.IsApproved = newAcc.Partner_Status__c == 'Active' ? true : false;
        this.partner.PartnerID = newAcc.DEAR_Tenant_ID__c;
        System.debug(this.partner);
    }

    public void execute(QueueableContext context){
        //TO-DO: Insert a LIST<Incoming_Requests__c> to invoke getCustomerDetails. 
        List<Incoming_Request__c> newRequests = new List<Incoming_Request__c>();
        List<String> tenantIDs = new List<String>();

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Partner_Activation');

        if(this.newAccount != null){
            req.setMethod('PUT');
            req.setBody(JSON.serialize(this.partner));
        }

        //BACKLOG ITEM: Scheduled partner activation job (phase 2).
        //---------------------------------------------------------
        /*else{
            req.setMethod('GET');
        }*/
        //---------------------------------------------------------
        
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', '*/*');
        req.setTimeout(120000);

        Http http = new Http();
        HTTPResponse resp = http.send(req);
        System.debug(resp);

        if(resp.getBody() != null && resp.getBody().length() != 0){
            //BACKLOG ITEM: Scheduled partner activation job (phase 2).
            //---------------------------------------------------------
           /* PartnerActivationJSONParse jsonResp = PartnerActivationJSONParse.parse(resp.getBody());
            System.debug(jsonResp);

            if(jsonResp.Errors == null){
                for(PartnerActivationJSONParse.Data d : jsonResp.Data){
                    // TO-DO: Chain Jobs
                    System.debug(d.PartnerID);
                    Incoming_Request__c reqst = new Incoming_Request__c();
                    reqst.Tenant_ID__c = d.PartnerID;
                    reqst.Message__c = 'Scheduled Job Partner Verification';
                    newRequests.add(reqst);
                    tenantIDs.add(d.PartnerID);
                }
                System.enqueueJob(new IncomingRequestQueueable(newRequests));
            }
            else{
                System.debug('Something went wrong when updating partner status...');
                API_Error_Log__c newError = new API_Error_Log__c();
                newError.Error_Message__c = String.join(jsonResp.Errors, ',');
                newError.HTTP_Status_Code__c = resp.getStatusCode();
                newError.Status__c = resp.getStatus();

                insert newError;
            }*/
            //---------------------------------------------------------
        }
    }

    public class Cin7Partner{
        public String PartnerID;
        public Boolean IsApproved;
    }
}