/**
 * @description       : 
 * @author            : AS | NuAge Experts
 * @group             : 
 * @last modified on  : 01-10-2024
 * @last modified by  : AS | NuAge Experts
**/
public with sharing class LeadTriggerHandler {

    // For Hubspot
    public static void accountProvisioningForLead(List<Lead> newLeads, Map<Id,Lead> oldMap) {
        if(NuAge_UtilityClass.CheckAutomationToRun('Lead_accountProvisioningForLead')){
            for(Lead hubspotLead : newLeads){
                if(hubspotLead.Free_Trial_Creation__c == true && (oldMap == null || (oldMap.containsKey(hubspotLead.Id) && !oldMap.get(hubspotLead.Id).Free_Trial_Creation__c))){
                    // System.debug(hubspotLead);
                    System.enqueueJob(new LeadTriggerQueueable(hubspotLead, 'callout:Account_Provisions'));
                }
            }
        }
    }

    // For Allbound
    public static void partnerAccountProvisioning(List<Lead> newLeads){
        if(NuAge_UtilityClass.CheckAutomationToRun('Lead_partnerAccountProvisioning')){
            for(Lead allbound : newLeads){
                if(allbound.Type__c == 'Partner'){
                    // System.debug(allbound);
                    System.enqueueJob(new LeadTriggerQueueable(allbound, 'callout:Partner_Account_Provisions'));
                }
            }
        }
    }

    public static void updatePartnerAccountProvisioning(List<Lead> newLeads, Map<Id,Lead> oldMap){
        if(NuAge_UtilityClass.CheckAutomationToRun('Lead_updatePartnerAccountProvisioning')){
            for(Lead ld : newLeads){                    
                if(ld.Type__c == 'Partner' && (ld.Country != oldMap.get(ld.Id).Country || ld.Website != oldMap.get(ld.Id).Website || 
                    ld.Core_Payment_Frequency__c != oldMap.get(ld.Id).Core_Payment_Frequency__c || ld.Company != oldMap.get(ld.Id).Company ||
                    ld.Core_Plan_Type__c != oldMap.get(ld.Id).Core_Plan_Type__c)){
                        // System.debug('Partner Account Provisions Web Service Callout...');
                        System.enqueueJob(new LeadTriggerQueueable(ld, 'callout:Partner_Account_Provisions'));
                }
            }
        }
    }


    // dear tenant id is known and referrer acct goes from blank to something
    // dear tenant id goes from unknown to known and referrer account is known
    // jira 48
    public static void updatePartnerClientRelationship(List<Lead> newLeads, Map<Id,Lead> oldLeads){
        if(NuAge_UtilityClass.CheckAutomationToRun('Lead_updatePartnerClientRelationship')){

            for(Lead ld : newLeads){
                if(oldLeads.containsKey(ld.Id) && 
                    ((ld.DEAR_Tenant_ID__c != null && ld.ImpartnerPRM__PartnerAccount__c != null && ld.ImpartnerPRM__PartnerAccount__c != oldLeads.get(ld.Id).ImpartnerPRM__PartnerAccount__c) ||
                    (ld.ImpartnerPRM__PartnerAccount__c != null && ld.DEAR_Tenant_ID__c != null && ld.DEAR_Tenant_ID__c != oldLeads.get(ld.Id).DEAR_Tenant_ID__c)||
                    ld.DEAR_Tenant_ID__c != null && ld.ImpartnerPRM__PartnerAccount__c != null && ld.IsPartnerOnboarding__c != oldLeads.get(ld.Id).IsPartnerOnboarding__c)) {
                        // System.debug('Update Partner Client Relationship Web Service Callout...');
                        System.enqueueJob(new LeadTriggerQueueable(ld, 'callout:Partner_Client_Relationship'));
                    }
            }
        }
    }

}