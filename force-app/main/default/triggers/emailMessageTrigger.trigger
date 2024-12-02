trigger emailMessageTrigger on EmailMessage (after insert) {
    // Cannot be a portal user
    if (UserInfo.getUserType() == 'Standard'){
        DateTime completionDate = System.now();
        Map<Id, String> emIds = new Map<Id, String>();
        List<Id> outboundCount = new List<Id>();
        for (EmailMessage em : Trigger.new){
            if(em.Incoming == false){
                emIds.put(em.ParentId, em.ToAddress);
                outboundCount.add(em.ParentId);
            }
        }
        if (outboundCount.isEmpty() == false){
            List<Case> toUpdate = new List<Case>();
            for(case c : [select id, Outbound_Email_Count__c, Origin  FROM case WHERE id in:outboundCount]){
                if(c.Origin == 'Web' && c.Outbound_Email_Count__c ==0 )
                 {
                    c.Outbound_Email_Count__c = 1;
                  }
                
                if(c.Outbound_Email_Count__c == null)
                {
                                    c.Outbound_Email_Count__c = 1;
                    }
                else
                    c.Outbound_Email_Count__c = c.Outbound_Email_Count__c + 1;
                toUpdate.add(c);
            }
            update toUpdate;
        }       
        if (emIds.isEmpty() == false){
            Set <Id> emCaseIds = new Set<Id>();
            emCaseIds = emIds.keySet();
            List<Case> caseList = [Select c.Id, c.ContactId, c.Contact.Email,
                              c.OwnerId, c.Status,
                              c.EntitlementId,
                              c.SlaStartDate, c.SlaExitDate, c.Outbound_Email_Count__c,c.First_Response__c
                           From Case c where c.Id IN :emCaseIds];
            if (caseList.isEmpty()==false){
                List<Id> updateCases = new List<Id>();
                List<Case> casesToUpdate = new List<Case>();
                for (Case caseObj:caseList) {
                    // consider an outbound email to the contact on the case a valid first response
                    if ((emIds.get(caseObj.Id)==caseObj.Contact.Email)&&(caseObj.EntitlementId != null) && caseObj.Outbound_Email_Count__c == 2 && caseObj.First_Response__c==null){
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