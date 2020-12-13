using Toybox.Application;

class AerobicDecouplingHRRvs6minPApp extends Application.AppBase {

	var AerobicDecouplingHRRvs6minPViewInstance;

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state) {
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
    }

    // Return the initial view of your application here
    function getInitialView() {
    	AerobicDecouplingHRRvs6minPViewInstance = new AerobicDecouplingHRRvs6minPView();
        return [ AerobicDecouplingHRRvs6minPViewInstance ];
    }

    function onSettingsChanged() {
        AerobicDecouplingHRRvs6minPViewInstance.readHRPowerSettings();
    }
}