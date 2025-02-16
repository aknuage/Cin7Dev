// when transcripts come in or are updated, look for corresponding responses to add record IDs to
trigger LookForResponse on LiveChatTranscript (before insert, before update) {
    // create new map of transcripts keyed by chat keys (strings)
    Map<String, LiveChatTranscript> transcriptMap = new Map<String, LiveChatTranscript>();
    
    // populate map with transcripts
    for(LiveChatTranscript transcript : Trigger.new) {
      transcriptMap.put(transcript.ChatKey, transcript);
    }

    // query for responses matching set of chat keys
    List<GetFeedback_Aut__Response__c> responses = [SELECT Id, ChatKey__c, GetFeedback_Aut__Account__c, GetFeedback_Aut__Case__c, GetFeedback_Aut__Contact__c,
                                                           GetFeedback_Aut__Lead__c 
                                                      FROM GetFeedback_Aut__Response__c 
                                                     WHERE ChatKey__c = :transcriptMap.keySet()];

    // loop through and update responses with IDs from matching transcripts
    for (GetFeedback_Aut__Response__c response : responses) {
        if (null != transcriptMap && transcriptMap.containsKey(response.ChatKey__c)) {
            LiveChatTranscript transcript = transcriptMap.get(response.ChatKey__c);
            
            // attach response to transcript
            transcript.GF_Response__c = response.Id;

            // attach records from the corresponding transcript
            response.GetFeedback_Aut__Account__c = transcript.AccountId;
            response.GetFeedback_Aut__Case__c    = transcript.CaseId;
            response.GetFeedback_Aut__Contact__c = transcript.ContactId;
            response.GetFeedback_Aut__Lead__c    = transcript.LeadId;
        }
    }

    update responses;
}