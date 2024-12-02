({
    callToServer : function(component, method, callback, params) {
        console.log('Calling helper callToServer function');
		var action = component.get(method);
        if(params){
            action.setParams(params);
        }
        console.log(JSON.stringify(params));
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                //alert('Processed successfully at server');
                callback.call(this,response.getReturnValue());
            }else if(state === "ERROR"){
                alert('Problem with connection. Please try again.');
            }
        });
		$A.enqueueAction(action);
    },
    
    getAccountDetail : function(component, event,helper,recId) {
        const action = component.get('c.fetchAccountDetails');
        action.setParams({
            'recId' : recId
        });
        action.setCallback(this,function(response){
            const state = response.getState();
            if(state==='SUCCESS'){
                const res = response.getReturnValue();
                component.set('v.accountName',res.Name);
                component.set('v.accountDetail',res);
            }
        });
        $A.enqueueAction(action); 
    }
})