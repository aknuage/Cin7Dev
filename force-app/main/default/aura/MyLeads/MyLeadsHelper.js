({
	getAllLeads : function() {
		var action = component.get("c.getAllLeads");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                component.set("v.leads", response.getReturnValue());                
            }
        });
        $A.enqueueAction(action);
	}
})