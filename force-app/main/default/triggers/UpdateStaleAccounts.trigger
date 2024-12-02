trigger UpdateStaleAccounts on Contact (before update) 
{
    if(Trigger.isBefore)
    {
        if(Trigger.isUpdate)
        {
            ContactTriggerHandler.beforeUpdate(Trigger.new);
        }
    }
}