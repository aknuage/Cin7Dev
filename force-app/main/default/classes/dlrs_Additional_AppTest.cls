/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_Additional_AppTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_Additional_AppTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new Additional_App__c());
    }
}