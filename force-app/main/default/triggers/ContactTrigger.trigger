trigger ContactTrigger on Contact (
    before insert,
    before update,
    after insert,
    after update,
    before delete,
    after delete,
    after undelete)
{

    switch on Trigger.operationType { 

        // when BEFORE_INSERT {}         
        when BEFORE_UPDATE {
            ContactTriggerHandler.UpdateStaleAccounts(Trigger.new);
        } 
        // when BEFORE_DELETE {}         
        when AFTER_INSERT {
            ContactTriggerHandler.SubscribeToNorthpass(Trigger.new, Trigger.oldMap);
        }         
        when AFTER_UPDATE {
            ContactTriggerHandler.SubscribeToNorthpass(Trigger.new, Trigger.oldMap);
        }         
        // when AFTER_DELETE {}         
        // when AFTER_UNDELETE {}      
    } 
}