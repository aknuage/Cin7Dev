({
    showToastSuccess : function() {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type": "Success",
            "title": "Success!",
            "message": "Trial Account was successfully created."
        });
        toastEvent.fire();
    },
    showToastQueued: function() {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type": "Info",
            "title": "Queued",
            "message": "Trial Account creation in progress....",
            "mode": "sticky"
        });
        toastEvent.fire();
    },
    showToastError: function(errorMsg) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type": "Warning",
            "title": "Trial Account Exception",
            "message": errorMsg
        });
        toastEvent.fire();
    }
})