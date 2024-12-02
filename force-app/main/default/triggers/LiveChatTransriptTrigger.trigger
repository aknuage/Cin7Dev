trigger LiveChatTransriptTrigger on LiveChatTranscript (After insert, After update) {
    if(label.TriggerActive=='true')
       {
   if(Trigger.IsAfter && (Trigger.IsUpdate) && LiveChatTransriptTriggerHandler.recordSave== false) {
        LiveChatTransriptTriggerHandler.updateCalendarHours(Trigger.New);
    } 
    
    if(trigger.IsInsert && trigger.IsAfter) {
        LiveChatTransriptTriggerHandler.updateCalendarHours(Trigger.New);
    }
   }
}