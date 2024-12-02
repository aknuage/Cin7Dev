/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_Customer_Satisfaction_SurveyTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_Customer_Satisfaction_SurveyTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new Customer_Satisfaction_Survey__c());
    }
}