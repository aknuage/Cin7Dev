/** a scheduled job to set the due-date on a case based on the First-Response milestone target date 
    this class is triggered under After-Insert trigger on the Case Object
*/
global class FirstResponseDueDateScheduledJob implements Schedulable {
    
    public Id[] newCases {set;get;}
    public FirstResponseDueDateScheduledJob(Id[] caseIds){
        newCases = caseIds;
    }
    
    global void execute(SchedulableContext SC) {
        system.debug(newCases);
        
        if(newCases!=null && !newCases.isEmpty()){
        	Map<ID, Case>cMap = new Map<ID, Case>([select Due_Date__c from Case where id in :newCases]);
            Case[]updCases = new Case[]{};
            CaseMilestone[] ms=[select TargetDate, caseId from CaseMilestone where caseId in :newCases and MilestoneType.Name = 'First Response'];
            BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault=true];
            
            system.debug(ms);
        	for( CaseMilestone cm: ms) {
                
                Case c = cMap.get(cm.caseId);
                if (c!=null){
                    DateTime TargetDate = BusinessHours.nextStartDate(bh.id, cm.TargetDate.Date());
                    c.due_date__c = TargetDate.date();
                    updCases.add(c);
                }
            } 

            if(!updCases.isEmpty()){
                boolean allOrNothing = false;
                Database.update(updCases, allOrNothing);
            }
    	}
        
    }
    

}