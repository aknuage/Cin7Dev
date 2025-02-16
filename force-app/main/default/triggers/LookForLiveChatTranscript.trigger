// when responses come in, look for corresponding transcripts to get record IDs from
trigger LookForLiveChatTranscript on GetFeedback_Aut__Response__c (before insert) {
    // create new set of strings
    Set<String> chatKeySet = new Set<String>();

    // populate set with chat keys from new responses
    for(GetFeedback_Aut__Response__c response : Trigger.new) {
        if (null != response.ChatKey__c && '' != response.ChatKey__c) {
            chatKeySet.add(response.ChatKey__c);
        }
    }

    // create new map of transcripts keyed by chat keys (strings)
    Map<String, LiveChatTranscript> transcriptMap = new Map<String, LiveChatTranscript>();
    
    for (LiveChatTranscript transcript : [SELECT Id, ChatKey, AccountId, CaseId, ContactId, LeadId FROM LiveChatTranscript WHERE ChatKey IN :chatKeySet]) {
        transcriptMap.put(transcript.ChatKey, transcript);
    }

    // loop through and update responses with IDs from matching transcripts
    if (transcriptMap.size() > 0) {
        for (GetFeedback_Aut__Response__c response : Trigger.new) {
            if (null != transcriptMap && transcriptMap.containsKey(response.ChatKey__c)) {
                LiveChatTranscript transcript = transcriptMap.get(response.ChatKey__c);
                
                // attach transcript to response
                response.LiveChatTranscript__c = transcript.Id;
                
                // attach records from the corresponding transcript
                response.GetFeedback_Aut__Account__c = transcript.AccountId;
                response.GetFeedback_Aut__Case__c    = transcript.CaseId;
                response.GetFeedback_Aut__Contact__c = transcript.ContactId;
                response.GetFeedback_Aut__Lead__c    = transcript.LeadId;
            }
        }
    }
}