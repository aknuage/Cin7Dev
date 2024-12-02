/**
 * @description       : 
 * @author            : AS | NuAge Experts
 * @group             : 
 * @last modified on  : 10-05-2023
 * @last modified by  : AS | NuAge Experts
**/
public with sharing class IncomingRequestQueueable implements Queueable,Database.AllowsCallouts 
{
	private IncomingRequestHelper.RequestType requestType;
	private List<Incoming_Request__c> incomingRequests;

    public IncomingRequestQueueable(IncomingRequestHelper.RequestType requestType, List<Incoming_Request__c> incomingRequests) 
	{
		this.requestType = requestType;
		this.incomingRequests = incomingRequests;
    }

    public void execute(QueueableContext context)
	{
		if (incomingRequests.size() == 0 || requestType == null) return;

		switch on requestType 
		{
			when NewSubscription 
			{ 
				Database.executeBatch(new IncomingRequestBatchable(this.incomingRequests), 30); 
			}
			when UpdateSubscription 
			{ 
				Database.executeBatch(new IncomingRequestBatchableNewOpp(this.incomingRequests), 30); 
			}
			when DiscountChange
			{ 
				// Database.executeBatch(new IncomingRequestBatchableNewOpp(this.incomingRequests), 30);
				Database.executeBatch(new IncomingRequestDiscountChange(this.incomingRequests), 30); 
			}
			when ContactUpdate 
			{
				// Database.executeBatch(new IncomingRequestContactUpdate(this.incomingRequests), 30); 
				new IncomingRequestContactUpdate(this.incomingRequests);
			}
			when RenewalSubscription { 
				Database.executeBatch(new IncomingRequestBatchableNewOpp(this.incomingRequests), 30); 
			}
			when CancelSubscription { 
				// Database.executeBatch(new IncomingRequestBatchableNewOpp(this.incomingRequests), 30); 
				Database.executeBatch(new IncomingRequestCancelSubscription(this.incomingRequests), 30);
			}
			when else { 
				Database.executeBatch(new IncomingRequestBatchableNewOpp(this.incomingRequests), 30); 
			}
		}
    }
}