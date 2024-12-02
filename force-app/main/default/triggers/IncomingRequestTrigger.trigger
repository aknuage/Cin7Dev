trigger IncomingRequestTrigger on Incoming_Request__c (
    before insert,
    before update,
    after insert,
    after update,
    before delete,
    after delete,
    after undelete)
{
    if (Trigger.isBefore)
    {
        if (Trigger.isInsert)
        {
            IncomingRequestTriggerHandler.RouteIncomingRequests(Trigger.new);
        }
    }
}