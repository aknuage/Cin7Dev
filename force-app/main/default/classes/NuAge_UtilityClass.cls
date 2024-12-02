/**
 * @description       : 
 * @author            : NuAge
 * @group             : 
 * @last modified by  : NuAge
**/
public with sharing class NuAge_UtilityClass {
    private static Map<String,Boolean> objNameDoRun;
    private static Database.DMLOptions dml;
    private static final String SWITCH_METADATA = 'Automation_Switch.';
    /**
    * @description: Overload method for Triggers. Will get SObject name from Trigger.new record
    * @author NuAge | 
    * @return Boolean 
    **/
    public static Boolean CheckAutomationToRun() {
        try{
            //If this is called from a non-Trigger context, skip logic an return true
            if(!Trigger.isExecuting) return true;
            return CheckAutomationToRun(String.valueOf(Trigger.new[0].getSObjectType()));
        }
        catch(Exception e) {
			System.debug(e.getStackTraceString());
            return true;
        }
        
    }

    /**
    * @description: Primary method to find if automation should be run. 
    * @author NuAge | 
    * @param automationName 
    * @return Boolean 
    **/
    public static Boolean CheckAutomationToRun(String automationName) {
        //If automationName is blank/empty, run automation
        if(String.isBlank(automationName)) return true;
        //Populate Map first time thru
        if(objNameDoRun == null) {
            objNameDoRun = new Map<String,Boolean>();
            for(Automation_Switch__mdt autoSwitch : [Select DeveloperName, Is_Active__c FROM Automation_Switch__mdt]) {
                objNameDoRun.put(autoSwitch.DeveloperName,autoSwitch.Is_Active__c);
            }
        }
        //Remove '__c' as DeveloperName cannot have that in custom metadata
        if(automationName.endsWith('__c')) automationName = automationName.removeEnd('__c');
        //If map contains key, return value associated with it
        if(objNameDoRun.containsKey(automationName)) return objNameDoRun.get(automationName);
        //Else, we need to create new metatdata record and return true
        Id jobId = System.enqueueJob(new NuAge_CustomMetadataQueueable(SWITCH_METADATA + automationName, automationName, new Map<String,Object>{'Is_Active__c' => true}));
        objNameDoRun.put(automationName,true);
        return true;
    }

}