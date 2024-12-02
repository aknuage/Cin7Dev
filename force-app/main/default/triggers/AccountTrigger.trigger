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
        } 
        when AFTER_UPDATE {
            AccountTriggerHandler.ProcessAccountForNorthpass(Trigger.newMap, Trigger.oldMap);
        }         

    } 

}