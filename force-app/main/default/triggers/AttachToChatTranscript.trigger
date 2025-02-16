// after responses come in, look for corresponding transcripts to add response ID to
trigger AttachToChatTranscript on GetFeedback_Aut__Response__c (after insert) {
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
    
    for (LiveChatTranscript transcript : [SELECT Id, ChatKey FROM LiveChatTranscript WHERE ChatKey IN :chatKeySet]) {
        transcriptMap.put(transcript.ChatKey, transcript);
    }

    // loop through and update responses with IDs from matching transcripts
    if (transcriptMap.size() > 0) {
        for (GetFeedback_Aut__Response__c response : Trigger.new) {
            if (null != transcriptMap && transcriptMap.containsKey(response.ChatKey__c)) {
                LiveChatTranscript transcript = transcriptMap.get(response.ChatKey__c);
                
                // attach response to transcript
                transcript.GF_Response__c = response.Id;
            }
        }
        
        update transcriptMap.values();
    }
}