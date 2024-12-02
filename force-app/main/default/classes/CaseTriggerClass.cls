public class CaseTriggerClass {
    
     private final Map<Id, Case> oldMap;
     private final Map<Id, Case> newMap;
     private final List<Case> newObjs;
     private final Boolean isInsert;
     private final Boolean isUpdate;
     private final Boolean isDelete;
     private final Boolean isBulk;
    
     // get the default business hours
     private final BusinessHours defaultHours = [select Id from BusinessHours where IsDefault=true];

     /**
     * The constructor
     *
     * @param xoldMap The old map from the trigger
     * @param xnewObj The list of new objects from the trigger
     * @param isBefore If the trigger is in before or after
     */
     private caseTriggerClass(Map<Id, Case> xoldMap, List<Case> xnewObjs, Boolean isBefore) {
          oldMap = xoldMap;
          newObjs = xnewObjs;

          if (!isBefore && newObjs != null) {
               newMap = new Map<Id, Case>(newObjs);
          }

          isDelete = (((newObjs == null || newObjs.isEmpty()) && isBefore) || ((newMap == null || newMap.isEmpty()) && !isBefore));
          isUpdate = ! (isDelete || oldMap == null || oldMap.isEmpty());
          isInsert = ! (isDelete || isUpdate);
          isBulk = (((!isDelete) && (newObjs.size() > 1)) || ((isDelete) && (oldMap.size() > 1)));
     }

    /**
    * Method to initiate trigger logic
    *
    * @param oldMap The old map from the trigger
    * @param newObj The list of new objects from the trigger
    * @param isBefore If the trigger is in before or after
    */
    public static void processTrigger(Map<Id, Case> oldMap, List<Case> newObj, Boolean isBefore) {
         final caseTriggerClass myTrigger = new caseTriggerClass(oldMap, newObj, isBefore);  
         
         if (isBefore) {
            myTrigger.calculateBusinessHoursAges();
            myTrigger.closeMilestones();
         }
         
         if (!isBefore) {
            myTrigger.setDueDateOnAfterInsert();
         }
    }
       
    // this is used to close any milestones that have the Soft Close Milestone field filled out on the case
    public void closeMilestones(){
       if(isUpdate){
           Set<ID> toClose = new Set<ID>();
           Set<ID> toRemind = new Set<ID>();
           
           for(Case c : newObjs){
               Case oldCase = oldMap.get(c.Id);
               if(c.Customer_Reminder_Set__c != oldCase.Customer_Reminder_Set__c){
                toRemind.add(c.id);
               }
               if(c.Inactive_Case_Closed__c != oldCase.Inactive_Case_Closed__c){
                   toClose.add(c.id);
               }
           }
           closeMilestones(toRemind, 'Customer Reminder');
           closeMilestones(toclose, 'Close Inactive Case');
       }
   }
    
    @future 
    public static void closeMilestones(Set<ID> caseIds, String milestoneNames) {
        DateTime complDateTime = DateTime.now();
        List<CaseMilestone> cmsToUpdate = [select Id, completionDate from CaseMilestone cm where caseId in :caseIds and cm.MilestoneType.Name = :milestoneNames and IsCompleted = false ];     
        if (!cmsToUpdate.isEmpty() ){
            for (CaseMilestone cm : cmsToUpdate){ 
                cm.completionDate = complDateTime; 
            } 
            update cmsToUpdate;
        } // end if
    }
    
    public void setDueDateOnAfterInsert(){
        if(isInsert){
            FirstResponseDueDateScheduledJob sch = new FirstResponseDueDateScheduledJob(new List<id>(newMap.keySet()));
            // delay schedule jobs for 20 seconds
            Utilities.scheduleNext(sch, 'DueDateJob_'+system.now().getTime(), 10);
        }
    }
    
    public void calculateBusinessHoursAges() {
        if(isDelete) return;
        System.debug('Case Age Start');
        
        if (isInsert) {
            System.debug('Case Age Insert');
            // set the default values when the cases are created.
            for (Case updatedCase:newObjs) {
                updatedCase.Last_Status_Change__c = System.now();
                updatedCase.Hours_With_Customer__c = 0;
                updatedCase.Hours_With_Support__c = 0;
            }
        } else {
            System.debug('Case Age Update');
            //Get the closed statuses (because at the point of this trigger Case.IsClosed won't be set yet)
            Set<String> closedStatusSet = new Set<String>();
            for (CaseStatus status:[Select MasterLabel From CaseStatus where IsClosed=true]) {
                closedStatusSet.add(status.MasterLabel);
            }
    
            //For any case where the status is changed, recalc the business hours in the buckets
            for (Case updatedCase:newObjs) {
                Case oldCase = oldMap.get(updatedCase.Id);
    
                if (oldCase.Status!=updatedCase.Status && updatedCase.Last_Status_Change__c!=null) {
                    //OK, the status has changed
                    
                    if (!oldCase.IsClosed) {
                        //We only update the buckets for open cases
    
                        //On the off-chance that the business hours on the case are null, use the default ones instead
                        Id hoursToUse = updatedCase.BusinessHoursId!=null?updatedCase.BusinessHoursId:defaultHours.Id;
    
                        //The diff method comes back in milliseconds, so we divide by 3600000 to get hours.
                        Double timeSinceLastStatus = BusinessHours.diff(hoursToUse, updatedCase.Last_Status_Change__c, System.now())/3600000.0;

                        //We decide which bucket to add it to based on whether it was in a stop status before
                        if (oldCase.Status == 'With_Customer') {
                            if(updatedCase.Hours_With_Customer__c==null){updatedCase.Hours_With_Customer__c=0;}
                            updatedCase.Hours_With_Customer__c += timeSinceLastStatus;
                        } else if (oldCase.Status == 'With Dev') {
                            if(updatedCase.Hours_With_Dev__c ==null){updatedCase.Hours_With_Dev__c =0;}
                            updatedCase.Hours_With_Dev__c += timeSinceLastStatus;
                        } else if (oldCase.Status == 'With Tier3') {
                            if(updatedCase.Hours_With_T3__c ==null){updatedCase.Hours_With_T3__c =0;}
                            updatedCase.Hours_With_T3__c += timeSinceLastStatus;
                        } else {
                            if(updatedCase.Hours_With_Support__c ==null){updatedCase.Hours_With_Support__c =0;}
                            updatedCase.Hours_With_Support__c += timeSinceLastStatus;
                        }
                        
                        if (closedStatusSet.contains(updatedCase.Status)) {
                            updatedCase.Hours_Open__c = updatedCase.Hours_With_Customer__c + updatedCase.Hours_With_Support__c;
                        }
                    }
    
                    updatedCase.Last_Status_Change__c = System.now();
                }
            }
        }
        System.debug('Case Age End');
    }
    
}