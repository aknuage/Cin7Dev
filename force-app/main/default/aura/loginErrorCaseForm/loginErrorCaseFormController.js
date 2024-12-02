({
    onInit: function (component, event, helper){ 
        document.addEventListener("grecaptchaVerified", function(e) {
            component.set('v.recaptchaResponse', e.detail.response);
            let myButton = component.find("myButton");
            myButton.set('v.disabled', false);
        });
        
        document.addEventListener("grecaptchaExpired", function() {
            let myButton = component.find("myButton");
            myButton.set('v.disabled', true);
        }); 
    },
    onRender: function (component, event, helper){ 
        document.dispatchEvent(new CustomEvent("grecaptchaRender", { "detail" : { element: 'recaptchaCheckbox'} }));
    },
    doSubmit: function (component, event, helper){
        var action = component.get("c.insertCase");
        action.setParams({
            recaptchaResponse: component.get('v.recaptchaResponse'),
            suppliedName: component.get('v.suppliedName'),
            suppliedCompany: component.get('v.suppliedCompany'),
            subject: component.get('v.subject'),
            description: component.get('v.description'),
            suppliedEmail: component.get('v.suppliedEmail')
        });
        let myButton = component.find("myButton");
        myButton.set('v.disabled', true);
        myButton.set('v.label', 'Submitting');
        
        action.setCallback(this, function(response) {
            document.dispatchEvent(new Event("grecaptchaReset"));
            
            var state = response.getState();
            if (state === "SUCCESS") {
               // var result = response.getReturnValue();
               // alert(result);
                myButton.set('v.label', 'Submit');
                if (response.getReturnValue() === 'Invalid Verification Request' || response.getReturnValue() === 'Invalid Verification'){
                    component.find('notifLib').showNotice({
                        "variant": "error",
                        //"header": "Case created",
                        "title": "reCaptcha Error",
                        "message": "Please try again or reload the page.",
                        closeCallback: function() {
                            //alert('You closed the alert!');
                    	}
                    })
                }
                else if (response.getReturnValue() === 'Success'){
                    //alert('Successfully created Case');
                    component.set('v.suppliedName','');
                    component.set('v.suppliedCompany','');
                    component.set('v.subject','');
                    component.set('v.description','');
                    component.set('v.suppliedEmail','');
                    component.find('notifLib').showNotice({
                        "variant": "info",
                        //"header": "Case created",
                        "title": "Your ticket has been submitted to our support team.",
                        "message": "Thanks for creating a case. We will be in touch shortly.",
                        closeCallback: function() {
                            //alert('You closed the alert!');
                    	}
                    })
                }
                else if (response.getReturnValue() === 'Blank Fields'){
                    component.find('notifLib').showNotice({
                        "variant": "error",
                        "header": "ERROR",
                        "title": "Blank Fields",
                        "message": "Please complete all required fields.",
                        closeCallback: function() {
                            //alert('You closed the alert!');
                    	}
                    })
                }
                else {
                	//alert('Case could not be created. Please try again. If problem persists please contact Support directly.');        
                	component.find('notifLib').showNotice({
                        "variant": "error",
                        "header": "ERROR",
                        "title": "We could not create your ticket.",
                        "message": "Please check that you have filled in the required fields correctly and try again.",
                        closeCallback: function() {
                            //alert('You closed the alert!');
                    	}
                    })
                }  
            } else {
                var errors = response.getError();
                if (errors) {
                    console.log(errors[0]);
                }
            }
        });
        
        $A.enqueueAction(action);
    }
})