/**
 * @description       : 
 * @author            : AS | NuAge Experts
 * @group             : 
 * @last modified on  : 2023-05-11
 * @last modified by  : NuAge
**/
trigger AccountTrigger on Account (before insert, before update, before delete, after insert, after update, after delete, after undelete) { 
    switch on Trigger.operationType { 

        when BEFORE_UPDATE {
            AccountTriggerHandler.checkAccountPartnerStatus(Trigger.newMap,Trigger.oldMap);
            // AccountTriggerHandler.updatePartnerAccountProvisioning();
        } 
        when AFTER_UPDATE {
            AccountTriggerHandler.ProcessAccountForNorthpass(Trigger.newMap, Trigger.oldMap);
            List<Account> triggerNew = (List<Account>)Trigger.new;
            Map<Id, Account> triggerOldMap = (Map<Id, Account>)Trigger.oldMap;
            // Cin7-120 - Make Callout to Account Partner Client endpoint if conditions met
            AccountTriggerHandler.UpdatePartnerClientRelationship(triggerNew, triggerOldMap);
        }

    } 

}