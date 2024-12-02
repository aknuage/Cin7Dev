/**
 * @description       : 
 * @author            : AS | NuAge Experts
 * @group             : 
 * @last modified on  : 06-28-2023
 * @last modified by  : AS | NuAge Experts
**/
trigger LeadTrigger on Lead (before insert, 
                            before update, 
                            before delete, 
                            after insert, 
                            after update, 
                            after delete,
                            after undelete) {
    switch on Trigger.operationType { 
        // when BEFORE_INSERT {}         
        when BEFORE_UPDATE {
            LeadTriggerHandler.updatePartnerAccountProvisioning(Trigger.new,Trigger.oldMap);
            LeadTriggerHandler.updatePartnerClientRelationship(Trigger.new,Trigger.oldMap);
        } 
                                        
        // when BEFORE_DELETE {}         
        when AFTER_INSERT {
            LeadTriggerHandler.accountProvisioningForLead(Trigger.new, null);
            LeadTriggerHandler.partnerAccountProvisioning(Trigger.new);
        }         
        when AFTER_UPDATE {
            LeadTriggerHandler.accountProvisioningForLead(Trigger.new, Trigger.oldMap);
                             
        }         
        // when AFTER_DELETE {}         
        // when AFTER_UNDELETE {}      
                            
    }
}