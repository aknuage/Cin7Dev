@isTest
public class TEST_caseTriggerClass {
    
    @testSetup 
    static void SetupTestData(){
              
        System.debug('TEST - Create acc');
        Account acc = new Account();
        acc.Name = 'Test Account 1';
        
        insert acc;
        
        System.debug('Add Test Contact');
        Contact con = new Contact();
        con.FirstName = 'Joe';
        con.LastName = 'Blogs Test';
        con.phone = '12345676';
        con.Email = 'test@test.com';
        con.AccountId = acc.id;
        
        
        insert con;
        
        //Create Cases and insert as a List
        Case c = new Case();
        c.AccountId = acc.Id;
        c.ContactId = con.Id;
        c.Status = 'Open';
        c.Subject = 'Case 1';
        c.Origin = 'Email';
        c.Modules__c = 'Accounting';
        c.Sub_Modules__c = 'Xero';
        c.Classifications__c = 'Inquiry-Cin7 Billing';
        //c.Queue__c = '3PL';
                
        System.debug('TEST - Insert Cases');
        insert c;
       
    }
    
    public static testMethod void testBusinessHoursBucketer() {
        System.test.startTest();
        
        Case c1 = [SELECT id, BusinessHoursId FROM Case WHERE Subject = 'Case 1'];
        
        /*c1.Status = 'With Customer - Awaiting Reply';
        c1.Last_Status_Change__c = System.Now();
        update c1;*/

        c1.Status = 'With_Customer';
        update c1;

        c1.Status = 'Open';
        update c1;

		Case updatedCase = [select Hours_With_Customer__c,Hours_With_Support__c,Hours_Open__c from Case where Id=:c1.Id LIMIT 1];
		System.assert(updatedCase.Hours_With_Customer__c!=null);
        System.assert(updatedCase.Hours_With_Support__c!=null);
        System.assert(updatedCase.Hours_Open__c==null);

        c1.Status = 'Closed';
        update c1;

        updatedCase = [select Hours_With_Customer__c,Hours_With_Support__c,Hours_Open__c from Case where Id=:c1.Id LIMIT 1];
        System.assert(updatedCase.Hours_With_Customer__c!=null);
        System.assert(updatedCase.Hours_With_Support__c!=null);
        System.assert(updatedCase.Hours_Open__c!=null);
        System.test.stopTest();
    }

}