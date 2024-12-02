@isTest(SeeAllData=true)
public class RHX_TEST_Unqualified_Lead_Survey {
	static testMethod void RHX_Testmethod() {
        List<sObject> sourceList = [SELECT Id 
			FROM Unqualified_Lead_Survey__c LIMIT 1];
        if(sourceList.size() == 0) {
            sourceList.add(
                    new Unqualified_Lead_Survey__c()
            );
        }
    	rh2.ParentUtil.UpsertRollupTestRecords( sourceList );
    }
}