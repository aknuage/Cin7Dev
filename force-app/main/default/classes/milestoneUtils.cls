public class milestoneUtils {
    
    public static void completeMilestone(List<Id> caseIds, String milestoneName, DateTime complDate) {
      
      List<CaseMilestone> cmsToUpdate = [select Id, completionDate
                       from CaseMilestone cm
                       where caseId in :caseIds 
                         and cm.MilestoneType.Name=:milestoneName 
                         and completionDate = null 
                       limit 1];
        
      if (cmsToUpdate.isEmpty() == false){
        for (CaseMilestone cm : cmsToUpdate){ cm.completionDate = complDate; } update cmsToUpdate;
      } // end if
    }
/*   
    public static void completeMilestone(Map<Id, DateTime> caseData, String milestoneName) {
 
      Set<id> casesToUpdate = caseData.keySet();    
        
      List<CaseMilestone> cmsToUpdate = [select Id, completionDate, caseId
        						           from CaseMilestone cm
                       					   where caseId in :casesToUpdate and cm.MilestoneType.Name=:milestoneName and completionDate = null limit 1];
	  if (cmsToUpdate.isEmpty() == false){
      	for (CaseMilestone cm : cmsToUpdate){
            System.debug('CaseData: ' + caseData.get(cm.caseId));
          cm.completionDate = caseData.get(cm.caseId);
      	}
      	update cmsToUpdate;
      }
    }
*/        
}