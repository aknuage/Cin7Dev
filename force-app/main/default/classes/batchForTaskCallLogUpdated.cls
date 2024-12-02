global class batchForTaskCallLogUpdated implements Database.Batchable<sObject>{
	public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id,Subject,Description,Type,Type__c FROM Task'
        );
    }
     public void execute(Database.BatchableContext bc, List<Task> records){
         List<Task> taskList = new List<Task>();
         for(Task t:records){
             if(t.Description!=null){
                 if(t.Description.Contains('Tenant: cin7xx01') && t.Description.Contains('Direction: InboundCall')){
                     t.Type = '8x8 Call';
                     t.Type__c = 'InboundCall';
                     taskList.add(t);
                 }
                 if(t.Description.Contains('Tenant: cin7xx01') && t.Description.Contains('Direction: OutboundCall')){
                     t.Type = '8x8 Call';
                     t.Type__c = 'OutboundCall';
                     taskList.add(t);
                 }   
             }
         }
         List<Database.SaveResult> results = Database.update(taskList, false);
    }
    public void finish(Database.BatchableContext bc){
        // execute any post-processing operations
    }
}