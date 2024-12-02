public class LiveChatTransriptTriggerHandler {
    
    public static boolean recordSave =false ;
    public static void updateCalendarHours(List<LiveChatTranscript> chatLst) {
        
        List<LiveChatTranscript> updateLst = new List<LiveChatTranscript>();
        for (LiveChatTranscript obj : chatLst){
            LiveChatTranscript objNew = new LiveChatTranscript(Id = obj.Id);
            Datetime myDT = obj.RequestTime;
            
            
            if(myDT != null) {
                System.debug('@@ myDT == '+ myDT);
                Datetime d1 = Datetime.valueOf(myDT);
                System.debug('@@@@@@@@@@@ d1 '+d1);
                string s1=d1.format();
                System.debug('@@@@@@@@@@@ final '+s1);
                Datetime dt = Datetime.parse(s1);
                Integer hourTime = dt.hour();
                System.debug('@@ hourTime == '+hourTime);
                String str = '';
                if(hourTime <= 9) {
                    str = '0'+ String.valueOf(hourTime) + ':00';
                } else {
                    str = String.valueOf(hourTime) + ':00';
                }
                objNew.Calendar_Hours__c = str;
                updateLst.add(objNew);
            }
            
        }
        System.debug('@@ updateLst == '+updateLst);
        if( updateLst.size() > 0) {
            
            recordSave = true;
            
            update updateLst;            
        }
    }
}