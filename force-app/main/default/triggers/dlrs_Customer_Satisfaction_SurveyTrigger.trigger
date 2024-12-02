/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
trigger dlrs_Customer_Satisfaction_SurveyTrigger on Customer_Satisfaction_Survey__c
    (before delete, before insert, before update, after delete, after insert, after undelete, after update)
{
    dlrs.RollupService.triggerHandler(Customer_Satisfaction_Survey__c.SObjectType);
}