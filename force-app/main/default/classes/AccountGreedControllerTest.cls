@isTest
public class AccountGreedControllerTest {
    static testMethod void GreedControllerTest(){
        
        Account a = new Account();
        a.Name = 'Test';
        insert a ;
        
        AccountGreedController.fetchAccountDetails(a.Id);
        AccountGreedController.findHierarchyData(a.Id);
        AccountGreedController.GetUltimateParentId(a.Id);
    }
}