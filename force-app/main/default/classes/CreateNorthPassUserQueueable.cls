/**
 * This class is responsible for creating a NorthPass user from a contact record and then assigning that 
 * new user to a Group based on tenant Id and Cin7 Account Username. If a contact is passed to this queueable it has 
 * already been qualified for Northpass sign-up.
 * 
 * CIN7-107 : nkoonce @ NuAge : May 2024
 */
public with sharing class CreateNorthPassUserQueueable implements Queueable, Database.AllowsCallouts
{
    List<NorthpassSubscriptionWrapper> subscriptions;

    String northpassGroupId;


    public CreateNorthPassUserQueueable(List<NorthpassSubscriptionWrapper> wrappers)
    {
        subscriptions = wrappers;
    }

    public void execute(QueueableContext qc)
    {
        CalloutHelper.CreateNorthPassUserAndAssignToGroup(subscriptions);
    }
}