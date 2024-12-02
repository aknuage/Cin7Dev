@isTest
public class testBatchForTaskCallLogUpdated {
	@isTest
    public static void method1(){
        task obj = new Task();
        obj.Subject = '8*8 Call Log Test';
        obj.Status = 'Completed';
        obj.Priority = 'Normal';
        obj.Type__c = 'InboundCall';
        obj.Type = '8x8 Call';
        obj.Description = 'Call answered at: Fri Oct 08 2021 03:58:53 GMT'
                         +'Call ended at: Fri Oct 08 2021 04:05:04 GMT'
                         +'Duration of the call: 00:06:10'
                         +'Tenant: cin7xx01'
                         +'Agent: Ritik Sharma'
                         +'Call Id: 122566'
                         +'Transaction Id: 122566'
                         +'Interaction Guid: int-17c5e0dae5a-Z1LVmZ29bwhNqMwwclnPFM190-phone-01-cin7xx01'
                         +'Terminate Reason: completed'
                         +'Direction: InboundCall'
                         +'Caller Name: European Educationall Group Pty Ltd'
                         +'Caller Record Id: 0062u00000DcNw0AAF'
                         +'Caller Phone: 61401040054'
                         +'ChannelName: AU All'
                         +'DirectionNextGen: InboundCall';
        insert obj;
        Test.startTest();
            batchForTaskCallLogUpdated uca = new batchForTaskCallLogUpdated();
            Id batchId = Database.executeBatch(uca);
       		//System.schedule('schduleBatchForTaskCallLogUpdated', '0 0 22 1/1 * ? *', new schduleBatchForTaskCallLogUpdated());
        Test.stopTest();
    }
    
    @isTest
    public static void method2(){
        task obj = new Task();
        obj.Subject = '8*8 Call Log Test1';
        obj.Status = 'Completed'; 
        obj.Priority = 'Normal';
        obj.Type__c = 'OutboundCall';
        obj.Type = '8x8 Call';
        obj.Description = 'Call answered at: Fri Oct 08 2021 03:58:53 GMT'
                         +'Call ended at: Fri Oct 08 2021 04:05:04 GMT'
                         +'Duration of the call: 00:06:10'
                         +'Tenant: cin7xx01'
                         +'Agent: Ritik Sharma'
                         +'Call Id: 122566'
                         +'Transaction Id: 122566'
                         +'Interaction Guid: int-17c5e0dae5a-Z1LVmZ29bwhNqMwwclnPFM190-phone-01-cin7xx01'
                         +'Terminate Reason: completed'
                         +'Direction: OutboundCall'
                         +'Caller Name: European Educationall Group Pty Ltd'
                         +'Caller Record Id: 0062u00000DcNw0AAF'
                         +'Caller Phone: 61401040054'
                         +'ChannelName: AU All'
                         +'DirectionNextGen: OutboundCall';
        insert obj;
        Test.startTest();
            batchForTaskCallLogUpdated uca = new batchForTaskCallLogUpdated();
            Database.executeBatch(uca);
        	//System.schedule('schduleBatchForTaskCallLogUpdated', '0 0 22 1/1 * ? *', new schduleBatchForTaskCallLogUpdated());
        Test.stopTest();
        
    }
}