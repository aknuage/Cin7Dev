// after transcripts come in or are updated, look for corresponding responses to add transcript ID to
trigger AttachToResponse on LiveChatTranscript (after insert, after update) {
    // create new map of transcripts keyed by chat keys (strings)
    Map<String, LiveChatTranscript> transcriptMap = new Map<String, LiveChatTranscript>();
    
    // populate map with transcripts
    for(LiveChatTranscript transcript : Trigger.new) {
      transcriptMap.put(transcript.ChatKey, transcript);
    }

    // query for responses matching set of chat keys
    List<GetFeedback_Aut__Response__c> responses = [SELECT Id, ChatKey__c FROM GetFeedback_Aut__Response__c WHERE ChatKey__c = :transcriptMap.keySet()];

    // loop through and update responses with IDs from matching transcripts
    for (GetFeedback_Aut__Response__c response : responses) {
        if (null != transcriptMap && transcriptMap.containsKey(response.ChatKey__c)) {
            LiveChatTranscript transcript = transcriptMap.get(response.ChatKey__c);
            
            // attach transcript to response
            response.LiveChatTranscript__c = transcript.Id;
        }
    }

    update responses;
}