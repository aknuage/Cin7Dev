@isTest(seeAllData=false)
public class OnboardingInsertUpdateTriggerTest {
    public static List<Onboarding__c> onboardingsList;
    public static List<Account> accountList;
    
    static void init(){
        accountList = new List<Account>();
        accountList.add(new Account( Name='Test Account'  ));        
        onboardingsList = new List<Onboarding__c>();
        //onboardingsList.add(new Onboarding__c( Onboarding_Status__c   = 'Live' ));
    }

    /** Test with an existing contact **/
    static testMethod void testWithExistingOnboarding() {
        init();
        Test.startTest();
        insert accountList;
        // Get the account we just created back with its ID
        accountList = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test Account'
        ];
        
        onboardingsList.add(new Onboarding__c(
            Onboarding_Status__c   = 'Live',
            Account__c = accountList.get(0).Id
        ));
        insert onboardingsList;
        
        onboardingsList[0].Onboarding_Status__c = 'Done';
        update onboardingsList;
        
        // Getting the case to verify that the ‘ContactId’ field is not null
        accountList = [
            SELECT Id
            FROM Account
            WHERE Id = :accountList[0].Id
        ];
     
        // Verification
        System.assertEquals(onboardingsList[0].Account__c, accountList[0].Id);
     
        Test.stopTest();
    }
}