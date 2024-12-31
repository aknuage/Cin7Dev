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
				// Current test coverage: 76% - akelly @ NuAge : 12/9/2024
				Database.executeBatch(new IncomingReqNewSubscriptionBatch(this.incomingRequests), 30);
			}
			when UpdateSubscription 
			{ 
				// Current test coverage: 93% - akelly @ NuAge : 12/8/24
				Database.executeBatch(new IncomingReqUpdateSubscriptionBatch(this.incomingRequests), 30);
				
			}
			when DiscountChange
			{ 
				// Current test coverage: 95% - akelly @ NuAge : 12/8/24
				Database.executeBatch(new IncomingReqDiscountChangeBatch(this.incomingRequests), 30); 
			}
			when ContactUpdate 
			{
				// Current test coverage: 100% - akelly @ NuAge : 12/8/24
				new IncomingReqContactUpdateQueueable(this.incomingRequests);
			}
			when RenewalSubscription { 
				// Current test coverage: 96% - akelly @ NuAge : 12/9/24
				Database.executeBatch(new IncomingReqRenewalSubscriptionBatch(this.incomingRequests), 30); 
			}
			when CancelSubscription { 
				// current test coverage: 85% - akelly @ Nuage : 12/8/24
				Database.executeBatch(new IncomingReqCancelSubscriptionBatch(this.incomingRequests), 30);
			}
			when else { 
				Database.executeBatch(new IncomingRequestBatchableNewOpp(this.incomingRequests), 30); 
			}
		}
    }
}