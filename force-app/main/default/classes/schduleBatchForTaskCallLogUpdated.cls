global class schduleBatchForTaskCallLogUpdated implements Schedulable{
    global void execute(SchedulableContext sc){
      	batchForTaskCallLogUpdated uca = new batchForTaskCallLogUpdated();
        Id batchId = Database.executeBatch(uca);  
    } 
}