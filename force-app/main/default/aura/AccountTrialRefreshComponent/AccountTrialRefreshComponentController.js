({
    doInit : function(component, event, helper) {
        var channel = "/event/Trial_Account_Created__e";
        const replayId = -1;
       
        const empApi = component.find("empApi");
    
        var recordId = component.get("v.recordId");
        console.log("record ID: ", recordId);
        // A callback function that’s invoked for every event received
        const callback = function (message)
        {
            var obj = message.data.payload;
            console.log("obj: ", obj.Message__c);
            if (obj.Message__c == "Reload" && (recordId === obj.AccountId__c))
                {
                // Notify user of trial creation success and refresh Account page
                console.log(" ==== > Refreshed Sucessfully < === ");
                $A.get("e.force:refreshView").fire();
                helper.showToastSuccess();
            } else if (obj.Message__c == "Queued") {
                // Let user know Trial Creation is in progress
                helper.showToastQueued();
            } else if (obj.Message__c.contains('Exception')) {
                // Show warning on caught Exceptions
                helper.showToastError(message);
            }
        };
       
        // Subscribe to the channel and save the returned subscription object.
        empApi.subscribe(channel, replayId, callback).then(function(newSubscription) {
            //console.log(“Subscribed to channel 1” + channel);
        });
       
        const errorHandler = function (message) {
            console.error("Received error ", JSON.stringify(message));
        };
       
        //A callback function that’s called when an error response is received from the server for the handshake, connect, subscribe, and unsubscribe meta channels.
        empApi.onError(errorHandler);
    }
})