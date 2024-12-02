({
        
    doInit : function(component, event, helper) {
        
    var action = component.get( "c.fetchUserDetails" );
        action.setCallback( this, function( response ) {
            var state = response.getState();
            console.log("State="  + state );
            if ( state === "SUCCESS" ) {
                
                var storeResponse = response.getReturnValue();
                component.set( "v.userInfo", storeResponse );
            }
        });
        $A.enqueueAction( action );
        
    }
    
})