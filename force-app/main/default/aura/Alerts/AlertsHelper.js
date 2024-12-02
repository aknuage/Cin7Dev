({
	doInit : function(component, event, helper) {
		this.setLanguage(component);
		var language = component.get("v.language");
		var action = component.get("c.GetAlerts");
		var componentName = component.get("v.componentName");
		action.setParams({"componentName":componentName, "language":language});
		action.setCallback(this, function(actionResult) {
			var data = actionResult.getReturnValue();
			var dataEx = data.map(function(alert) {
				if ("default" !== alert.Type__c.toLowerCase()) {
					alert.Style = "slds-theme--"+alert.Type__c.toLowerCase();
				}
				return alert;
			});
			component.set("v.alerts", dataEx);
		});
		$A.enqueueAction(action);
	},

	setLanguage: function(component) {
		var search = window.location.search;
		if (search.length > 0) {
			var params = search.replace("?","").split("&");
			for(var q = 0; q < params.length; q++) {
				if (0 < params[q].indexOf("language")) {
					var kvp = params[q].split("=");
					component.set("v.language", kvp[1]);
					break;
				}
			}
		}
	}
})