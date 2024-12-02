public with sharing class IsOnboardingOptionalQueueable implements Queueable, Database.AllowsCallouts 
{
    String tenantId;
    Boolean isOnboardingOptional;

    public IsOnboardingOptionalQueueable(String tenant_id, Boolean is_onboarding_optional) 
    {
        tenantId = tenant_id;
        isOnboardingOptional = is_onboarding_optional;
    }

    public void execute(QueueableContext qc)
    {
        CalloutHelper.SendIsOnboardingOptional(tenantId, isOnboardingOptional);
    }
}