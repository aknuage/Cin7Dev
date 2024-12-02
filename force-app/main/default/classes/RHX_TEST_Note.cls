@isTest(SeeAllData=true)
public class RHX_TEST_Note {
	static testMethod void RHX_Testmethod() {
        List<sObject> sourceList = [SELECT Id 
			FROM Note LIMIT 1];
        if(sourceList.size() == 0) {
            sourceList.add(
                    new Note()
            );
        }
    	rh2.ParentUtil.UpsertRollupTestRecords( sourceList );
    }
}