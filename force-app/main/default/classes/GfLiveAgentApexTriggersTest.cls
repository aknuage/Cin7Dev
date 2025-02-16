@isTest(seeAllData=false)
private class GfLiveAgentApexTriggersTest {
    static TestMethod void testCaseResponseTranscript() {
        Test.startTest();

        String testChatKey = 'testchatkey123';

        Case case_one = new Case();
        insert case_one;

        LiveChatVisitor visitor = new LiveChatVisitor();
        insert visitor;

        LiveChatTranscript transcript = new LiveChatTranscript(
          LiveChatVisitorId = visitor.Id,
          CaseId = case_one.Id,
          ChatKey = testChatKey
        );
        
        GetFeedback_Aut__Survey__c survey = new GetFeedback_Aut__Survey__c(
          GetFeedback_Aut__GetFeedbackId__c = 123
        );
        insert survey;
        
        GetFeedback_Aut__Response__c response = new GetFeedback_Aut__Response__c(
          GetFeedback_Aut__GetFeedbackId__c = 1234,
          GetFeedback_Aut__Survey__c = survey.Id,
          ChatKey__c = transcript.ChatKey
        );
        insert response;
        
        insert transcript;
        
        GetFeedback_Aut__Response__c[] responses = [SELECT Id, LiveChatTranscript__c, GetFeedback_Aut__Case__c FROM GetFeedback_Aut__Response__c WHERE ChatKey__c = :testChatKey];
        LiveChatTranscript[] transcripts = [SELECT Id, GF_Response__c, CaseId FROM LiveChatTranscript WHERE ChatKey = :testChatKey];
        
        System.assertEquals(transcripts[0].GF_Response__c, responses[0].Id);
        System.assertEquals(responses[0].LiveChatTranscript__c, transcripts[0].Id);
        System.assertEquals(responses[0].GetFeedback_Aut__Case__c, transcripts[0].CaseId);
        
        Test.stopTest();
    }

    static TestMethod void testTranscriptResponseCase() {
        Test.startTest();

        String testChatKey = 'testchatkey123';

        LiveChatVisitor visitor = new LiveChatVisitor();
        insert visitor;

        LiveChatTranscript transcript = new LiveChatTranscript(
          LiveChatVisitorId = visitor.Id,
          ChatKey = testChatKey
        );
        insert transcript;
                
        GetFeedback_Aut__Survey__c survey = new GetFeedback_Aut__Survey__c(
          GetFeedback_Aut__GetFeedbackId__c = 123
        );
        insert survey;
        
        GetFeedback_Aut__Response__c response = new GetFeedback_Aut__Response__c(
          GetFeedback_Aut__GetFeedbackId__c = 1234,
          GetFeedback_Aut__Survey__c = survey.Id,
          ChatKey__c = transcript.ChatKey
        );
        insert response;
        
        Case case_one = new Case();
        insert case_one;
    
        transcript.CaseId = case_one.Id;
        update transcript;
        
        GetFeedback_Aut__Response__c[] responses = [SELECT Id, LiveChatTranscript__c, GetFeedback_Aut__Case__c FROM GetFeedback_Aut__Response__c WHERE ChatKey__c = :testChatKey];
        LiveChatTranscript[] transcripts = [SELECT Id, GF_Response__c, CaseId FROM LiveChatTranscript WHERE ChatKey = :testChatKey];
        
        System.assertEquals(transcripts[0].GF_Response__c, responses[0].Id);
        System.assertEquals(responses[0].LiveChatTranscript__c, transcripts[0].Id);
        System.assertEquals(responses[0].GetFeedback_Aut__Case__c, transcripts[0].CaseId);
        
        Test.stopTest();
    }

    static TestMethod void testCaseTranscriptResponse() {
        Test.startTest();

        String testChatKey = 'testchatkey123';

        Case case_one = new Case();
        insert case_one;

        LiveChatVisitor visitor = new LiveChatVisitor();
        insert visitor;

        LiveChatTranscript transcript = new LiveChatTranscript(
          LiveChatVisitorId = visitor.Id,
          CaseId = case_one.Id,
          ChatKey = testChatKey
        );
        insert transcript;
        
        GetFeedback_Aut__Survey__c survey = new GetFeedback_Aut__Survey__c(
          GetFeedback_Aut__GetFeedbackId__c = 123
        );
        insert survey;
        
        GetFeedback_Aut__Response__c response = new GetFeedback_Aut__Response__c(
          GetFeedback_Aut__GetFeedbackId__c = 1234,
          GetFeedback_Aut__Survey__c = survey.Id,
          ChatKey__c = transcript.ChatKey
        );
        insert response;
        
        GetFeedback_Aut__Response__c[] responses = [SELECT Id, LiveChatTranscript__c, GetFeedback_Aut__Case__c FROM GetFeedback_Aut__Response__c WHERE ChatKey__c = :testChatKey];
        LiveChatTranscript[] transcripts = [SELECT Id, GF_Response__c, CaseId FROM LiveChatTranscript WHERE ChatKey = :testChatKey];
        
        System.assertEquals(transcripts[0].GF_Response__c, responses[0].Id);
        System.assertEquals(responses[0].LiveChatTranscript__c, transcripts[0].Id);
        System.assertEquals(responses[0].GetFeedback_Aut__Case__c, transcripts[0].CaseId);
        
        Test.stopTest();
    }
}