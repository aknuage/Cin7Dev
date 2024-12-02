({
	getURL : function(component) {
		var action = component.get("c.getURL");
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (component.isValid() && state === "SUCCESS") {
				component.set("v.URL", response.getReturnValue());
				
			}
		});
		$A.enqueueAction(action);
	}
 
})