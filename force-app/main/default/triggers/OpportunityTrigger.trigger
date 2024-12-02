/**
 * @description       : 
 * @author            : AS | NuAge Experts
 * @group             : 
 * @last modified on  : 06-20-2023
 * @last modified by  : AS | NuAge Experts
**/
trigger OpportunityTrigger on Opportunity (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    switch on Trigger.operationType { 

        //when BEFORE_INSERT {}         
        //when BEFORE_UPDATE {} 
        // when BEFORE_DELETE {} 
        /*when AFTER_INSERT {
            System.debug('Opportunity Trigger');
            OpportunityTriggerHandler.createOpportunityDiscount(Trigger.new);
        }*/        
        when AFTER_UPDATE {
            OpportunityTriggerHandler.createOpportunityDiscount(Trigger.new,Trigger.old);
            OpportunityTriggerHandler.updateOpportunityDiscount(Trigger.new,Trigger.old);
            OpportunityTriggerHandler.CheckIsOnboardingOptional(Trigger.new,Trigger.oldMap);
        }         
        // when AFTER_DELETE {}         
        // when AFTER_UNDELETE {}      
    } 

}