({
	itemsChange: function (component, event, helper) {
		// if (event.getSource().get("v.value").length < 3) return;
		var appEvent = $A.get("e.selfService:caseCreateFieldChange");
		var params = {
			// modifiedField: event.getSource().get("v.fieldName"),
			modifiedField: "Subject",
			modifiedFieldValue: event.getSource().get("v.value")
		};
		appEvent.setParams(params);
		console.log(params);
		appEvent.fire();
	},
	handleSubmit: function (cmp) {
		var spinner = cmp.find("mySpinner");
		cmp.set("v.isDisabled", true);
		$A.util.toggleClass(spinner, "slds-hide");
	},
	handleSuccess: function (cmp, event, hlp) {
		var toastEvent = $A.get("e.force:showToast");
		toastEvent.setParams({
			title: "Success!",
			type: "success",
			message: "You case has been recorded."
		});
		toastEvent.fire();
		cmp.find("field").forEach(function (f) {
			f.reset();
		});
		cmp.set("v.isDisabled", false);
		var spinner = cmp.find("mySpinner");
		$A.util.toggleClass(spinner, "slds-hide");
		console.log("Successfully creased the case");
	},
	handleError: function (cmp, event, hlp) {
		console.log(event.getParam("error"));
		cmp.set("v.isDisabled", false);
		var spinner = cmp.find("mySpinner");
		$A.util.toggleClass(spinner, "slds-hide");
	}
});