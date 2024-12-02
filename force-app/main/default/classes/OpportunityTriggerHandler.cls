/**
 * @description       : 
 * @author            : AS | NuAge Experts
 * @group             : 
 * @last modified on  : 03-20-2024
 * @last modified by  : AS | NuAge Experts
**/
// TO-DO Could implement as SOQL and consolidate two methods into single method with dynamic SOQL query
public without sharing class OpportunityTriggerHandler {
    
    // Method used to determine if web service callout should be invoked for CREATING Opportunity Discount in Cin7 CORE
    public static void createOpportunityDiscount(List<Opportunity> newOpps, List<Opportunity> oldOpps) {
        List<String> approversList = getSalesforceOrg();

        //Only allow web service callout to execute if the user approving the discount is listed in the approversList
        if(approversList.contains(UserInfo.getUserName())){
            for(Opportunity opp : newOpps){
                for(Opportunity oldOpp : oldOpps){
                    if(opp.Discount_Approval_Status__c == 'Approved' && (oldOpp.Discount_Approval_Status__c != opp.Discount_Approval_Status__c) && opp.Core_Discount_ID__c == null){
                        System.debug('Discount CREATE Callout');
                        System.enqueueJob(new OpportunityTriggerQueueable(opp));
                    }
                }
            }
        }
        else{
            for(Opportunity opp : newOpps){
                for(Opportunity oldOpp : oldOpps){
                    if(opp.Discount_Approval_Status__c == 'Approved' && (oldOpp.Discount_Approval_Status__c != opp.Discount_Approval_Status__c) && opp.Core_Discount_ID__c == null){
                        //Displays error message
                        opp.addError('Only assigned approvers can approve opportunity discounts!');
                    }
                }
            }
        }
    }

    // Method used to determine if web service callout should be invoked for UPDATING Opportunity Discount in Cin7 CORE
    public static void updateOpportunityDiscount(List<Opportunity> newOpps, List<Opportunity> oldOpps){
        List<String> approversList = getSalesforceOrg();

        //Only allow web service callout to execute if the user approving the discount is listed in the approversList
        if(approversList.contains(UserInfo.getUserName())){
            for(Opportunity opp : newOpps){
                for(Opportunity oldOpp : oldOpps){
                    if(opp.Discount_Approval_Status__c == 'Approved' && (oldOpp.Discount_Approval_Status__c != opp.Discount_Approval_Status__c) && opp.Core_Discount_ID__c != null){
                        System.debug('Discount UPDATE Callout');
                        System.enqueueJob(new OpportunityTriggerQueueable(opp,'PUT'));
                    }
                }
            }
        }
        else{
            for(Opportunity opp : newOpps){
                for(Opportunity oldOpp : oldOpps){
                    if(opp.Discount_Approval_Status__c == 'Approved' && (oldOpp.Discount_Approval_Status__c != opp.Discount_Approval_Status__c) && opp.Core_Discount_ID__c != null){
                        //Displays error message
                        opp.addError('Only assigned approvers can approve opportunity discounts!');
                    }
                }
            }
        }
    }

    private static List<String> getSalesforceOrg(){
        List<String> approversList = new List<String>();
        Organization cin7_ORG = [SELECT Id, Name,InstanceName, IsSandbox FROM Organization];
        if(cin7_ORG.IsSandbox == true){
            //Check the sandbox name
            System.Domain domain = System.DomainParser.parse(URL.getOrgDomainUrl());
            String sbName = domain.getSandboxName();
    
            //Get Sandbox CMD
            if(sbName == 'nuagedev'){
                String usernameslist = [SELECT usernames_List__c FROM Approver_List__mdt WHERE DeveloperName = 'Opportunity_Discount_NuAgeDev'].usernames_List__c;
                approversList = usernameslist.split(',');
            }
            if(sbName == 'uat'){
                String usernameslist = [SELECT usernames_List__c FROM Approver_List__mdt WHERE DeveloperName = 'Opportunity_Discount_UAT'].usernames_List__c;
                approversList = usernameslist.split(',');
            }
        }else{
            //Get Production CMD
            String usernameslist = [SELECT usernames_List__c FROM Approver_List__mdt WHERE DeveloperName = 'Opportunity_Discount_Production'].usernames_List__c;
            approversList = usernameslist.split(',');
        }
        return approversList;
    }

    /**
     * If IsOnboardingOptional changes value, callout to push new value
     * 
     * Called by OpportunityTrigger after update
     * 
     * @param newList - list of Opportunities being updated
     * @param oldMap
     * @return void
     * @author nkoonce @ NuAge : CIN7-101 : March 2024
     */ 
    public static void CheckIsOnboardingOptional(List<Opportunity> newList, Map<Id,Opportunity> oldMap)
    {
        // Interate updated opps, if IsOnboardingOptional changes, callout with the new value
        for (Opportunity o : newList)
        {
            if (oldMap != null && o.IsOnboardingOptional__c != oldMap.get(o.Id).IsOnboardingOptional__c)
            {
                System.enqueueJob(new IsOnboardingOptionalQueueable(o.DEAR_Tenant_Id__c, o.IsOnboardingOptional__c));
            }
        }
    }
}