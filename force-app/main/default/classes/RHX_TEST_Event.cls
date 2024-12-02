@isTest(SeeAllData=true)
public class RHX_TEST_Event {
	static testMethod void RHX_Testmethod() {
        List<sObject> sourceList = [SELECT Id 
			FROM Event LIMIT 1];
        if(sourceList.size() == 0) {
            sourceList.add(
                    new Event()
            );
        }
    	rh2.ParentUtil.UpsertRollupTestRecords( sourceList );
    }
}