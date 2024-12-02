/**
 * @description       : Covers testing for NuAge_UtilityClass, NuAgeCustomMetadataQueueable, NuAge_CreateUpdateMetadataUtils
 * @author            : NuAge Experts
 * @last modified on  : 2023-05-11
 * @last modified by  : NuAge
**/
@isTest
private class NuAge_UtilityClassTest {

    @isTest
    static void CheckAutomationToRun_NoTrigger() {
        //Assemble
        //No data needed to assemble

        //Act
        Test.startTest();

        Boolean doRun = NuAge_UtilityClass.CheckAutomationToRun();

        Test.stopTest();

        //Assert
        System.assert(doRun, 'Called method with no parameters, and this is not a Trigger. Return should be true.');

    }

    @isTest
    static void CheckAutomationToRun_OverrideSuccess() {
        //Assemble
        //No data needed to assemble

        //Act
        Test.startTest();

        Boolean doRun = NuAge_UtilityClass.CheckAutomationToRun('TestRun');

        Test.stopTest();

        //Assert
        System.assert(doRun, 'Called method with parameters and metadata record does not exist. Return should be true.');
        List<Automation_Switch__mdt> newMetadata = [SELECT Id FROM Automation_Switch__mdt WHERE DeveloperName = 'TestRun'];
    }

    @isTest
    static void HandleMetadataCallback_Success() {
        //Assemble
        //No data needed to assemble

        //Act
        Test.startTest();
        // Instantiate the callback.
        Metadata.DeployCallback callback = new NuAge_CreateUpdateMetadataUtils();
        // Create test result and context objects.
        Metadata.DeployResult result = new Metadata.DeployResult();
        //Set SUCCESS status
        result.status = Metadata.DeployStatus.SUCCEEDED;
        //Set DeployDetails info
        Metadata.DeployDetails dets = new Metadata.DeployDetails();
        dets.componentSuccesses = new List<Metadata.DeployMessage>();
        Metadata.DeployMessage successMsg1 = new Metadata.DeployMessage();
        successMsg1.fullName = 'New CMDT Created';
        successMsg1.created = true;
        successMsg1.changed = false;
        dets.componentSuccesses.add(successMsg1);
        Metadata.DeployCallbackContext context = new Metadata.DeployCallbackContext();
        result.details = dets;
        // Invoke the callback's handleResult method.
        callback.handleResult(result, context);

        Test.stopTest();


    }

    @isTest
    static void HandleMetadataCallback_Error() {
        //Assemble
        //No data needed to assemble

        //Act
        Test.startTest();
        // Instantiate the callback.
        Metadata.DeployCallback callback = new NuAge_CreateUpdateMetadataUtils();
        // Create test result and context objects.
        Metadata.DeployResult result = new Metadata.DeployResult();
        result.status = Metadata.DeployStatus.FAILED;
        result.errorMessage = 'FAILED';
        Metadata.DeployCallbackContext context = new Metadata.DeployCallbackContext();
        // Invoke the callback's handleResult method.
        callback.handleResult(result, context);

        Test.stopTest();

    }

}