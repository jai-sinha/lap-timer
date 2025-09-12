import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class lap_timerApp extends Application.AppBase {
    private var _currentView as lap_timerView?;

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    // Return the initial view of your application here
    function getInitialView() as [Views] or [Views, InputDelegates] {
        _currentView = new lap_timerView();
        return [ _currentView, new lap_timerDelegate() ];
    }

    // Method to handle lap saving from the delegate
    public function saveLap() as Void {
        System.println("App.saveLap() called");
        
        if (_currentView != null) {
            System.println("Calling saveLapAndReset on stored view reference");
            _currentView.saveLapAndReset();
            System.println("saveLapAndReset called successfully on stored view");
        } else {
            System.println("ERROR: No stored view reference!");
        }
    }

}

function getApp() as lap_timerApp {
    return Application.getApp() as lap_timerApp;
}