@isTest(seeAllData=true)

Public class  	LiveChatTransriptTriggerHandlerTestClass {
    
    @isTest
    Public static void method11()
    {
  
        
        Id lV = [SELECT Id from LiveChatVisitor LIMIT 1].id;
        
        List<LiveChatTranscript> lCLst = new List<LiveChatTranscript>();
        LiveChatTranscript cT1 = new LiveChatTranscript();
        cT1.LiveChatVisitorId= lV;
        cT1.Status = 'Missed';
        cT1.RequestTime = datetime.newInstance(2022, 5, 10, 12, 30, 0);
        lCLst.add(cT1);
        insert lCLst;
        
        
        Test.startTest();
        LiveChatTransriptTriggerHandler.updateCalendarHours(lCLst);
        Test.stopTest();
    }
    
    @isTest
     Private static void method12()
    {
  
        
        Id lV = [SELECT Id from LiveChatVisitor LIMIT 1].id;
        
        List<LiveChatTranscript> lCLst = new List<LiveChatTranscript>();
        LiveChatTranscript cT1 = new LiveChatTranscript();
        cT1.LiveChatVisitorId= lV;
        cT1.Status = 'Completed';
        cT1.RequestTime = datetime.newInstance(2022, 5, 10, 07, 30, 0);
        lCLst.add(cT1);
        insert lCLst;
        
        
        Test.startTest();
        LiveChatTransriptTriggerHandler.updateCalendarHours(lCLst);
        Test.stopTest();
    }
    
    @isTest
     private static void method13()
    {
  
        
        Id lV = [SELECT Id from LiveChatVisitor LIMIT 1].id;
        
        List<LiveChatTranscript> lCLst = new List<LiveChatTranscript>();
        LiveChatTranscript cT1 = new LiveChatTranscript();
        cT1.LiveChatVisitorId= lV;
        cT1.Status = 'Missed';
        lCLst.add(cT1);
        insert lCLst;
        
        
        Test.startTest();
        LiveChatTransriptTriggerHandler.updateCalendarHours(lCLst);
        Test.stopTest();
    }

}