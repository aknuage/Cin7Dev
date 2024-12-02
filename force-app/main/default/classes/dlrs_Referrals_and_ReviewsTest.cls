/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_Referrals_and_ReviewsTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_Referrals_and_ReviewsTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new Referrals_and_Reviews__c());
    }
}