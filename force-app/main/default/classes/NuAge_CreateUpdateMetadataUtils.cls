/**
 * @description       : 
 * @author            : NuAge 
 * @last modified on  : 2023-05-10
 * @last modified by  : NuAge
**/
public with sharing class NuAge_CreateUpdateMetadataUtils implements Metadata.DeployCallback{
    
    /**
    * @description - Callback method for async custom metadata DML
    * @author NuAge | 
    * @param result - When async metadata deployment finishes, we are provided an instance of Metadata.DeployResult which we can handle successes/errors
    * @param context 
    **/
    public void handleResult(Metadata.DeployResult result, Metadata.DeployCallbackContext context) {
        if(result.status == Metadata.DeployStatus.SUCCEEDED) {
            String details = '';
            for(Metadata.DeployMessage dm : result.details.componentSuccesses) {
                details += dm.fullName + ' - Created: ' + dm.created + ' Changed: ' + dm.changed + '\r\n';
            }
        }
        else {
            System.debug(' fail : '+ result);
        }
    }

    /**
    * @description 
    * @author NuAge | 
    * @param fullName - Custom Metadata API name + DeveloperName (e.g., 'Automation_Switch.Account')
    * @param label - Label name
    * @param fieldWithValuesMap - Map to set indivdual fields in metadata
    **/
    public static void CreateUpdateMetadata(String fullName, String label, Map<String, Object> fieldWithValuesMap){
        //Create custom metadata instance, set full name and label
        Metadata.CustomMetadata customMetadata =  new Metadata.CustomMetadata();
        customMetadata.fullName = fullName;
        customMetadata.label = label;
        //Iterate thru map and set ind'l fields
        for(String key : fieldWithValuesMap.keySet()){
            Metadata.CustomMetadataValue customField = new Metadata.CustomMetadataValue();
            customField.field = key;
            customField.value = fieldWithValuesMap.get(key); 
            customMetadata.values.add(customField);
        }
        //Instantiate DeployContainer
        Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
        mdContainer.addMetadata(customMetadata);
        //Set up callback
        NuAge_CreateUpdateMetadataUtils callback = new NuAge_CreateUpdateMetadataUtils();
        //Run Queueable call to avoid any DML Operation issues. If test, do not run (AsyncException)
        if(!Test.isRunningTest()) Metadata.Operations.enqueueDeployment(mdContainer, callback);
    }
}