trigger taskTrigger on Task (after insert) {
    // Cannot be a portal user
    if (UserInfo.getUserType() == 'Standard'){
        DateTime completionDate = System.now();
        List<Id> caseIds = new List<Id>();
        for (Task t : Trigger.new){
            if(t.Type == 'Call' && t.WhatId != null){ 
                Id taskId = t.WhatId;
                if(taskId.getSObjectType().getDescribe().getName() == 'Case'){
                    caseIds.add(t.WhatId);
                }
            }
        }
        System.debug('caseIds: ' + caseIds.size());
        if (caseIds.isEmpty() == false){
            List<Case> caseList = [Select c.Id, c.ContactId, c.Contact.Email,
                              c.OwnerId, c.Status,
                              c.EntitlementId,c.Outbound_Email_Count__c,c.First_Response__c
                           From Case c
                           Where c.Id IN :caseIds];
            if (caseList.isEmpty() == false){
                List<Id> updateCases = new List<Id>();
                List<Case> casesToUpdate = new List<Case>();
                
                for (Case caseObj:caseList) {
                    // consider an outbound email to the contact on the case a valid first response
                    if ((caseObj.EntitlementId != null && caseObj.Outbound_Email_Count__c <=1 && caseObj.First_Response__c == null )){
                        updateCases.add(caseObj.Id);
                        caseObj.First_Response__c = completionDate;
                        casesToUpdate.add(caseObj);
                    }
                }
                
                if(updateCases.isEmpty() == false){
                    milestoneUtils.completeMilestone(updateCases, 'First Response', completionDate);
                    update casesToUpdate;
                }
                
            }
        }
    }
}