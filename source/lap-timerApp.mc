import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Communications;

(:TimerState)
enum {
    TIMER_STOPPED,
    TIMER_RUNNING,
    TIMER_PAUSED
}

class Listener extends Communications.ConnectionListener {
    function initialize() {
        Communications.ConnectionListener.initialize();
    }
    function onComplete() {
        System.println("Connection successful!");
    }
}

class lap_timerApp extends Application.AppBase {
    private var _currentView as lap_timerView?;
    private var _listener = new Listener();

    function initialize() {
        AppBase.initialize();
    }


    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        Communications.registerForPhoneAppMessages(method(:onPhoneAppMessage));
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {

    }

    // Handle incoming messages from the phone app
    function onPhoneAppMessage(msg as Communications.PhoneAppMessage) as Void {
        System.println("Received message from phone app: " + msg.toString());    
    }

    // Method to send a message to the phone app
    public function sendMessageToPhoneApp(content) as Void {
        Communications.transmit("Sending message: " + content, null, _listener);
        Communications.transmit(content, null, _listener);
        System.println("Sent message to phone app: " + content);
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

    // Method to get current timer state
    public function getState() as Number {
        if (_currentView != null) {
            return _currentView.getState();
        } else {
            return TIMER_STOPPED;
        }
    }

    // Method to pause the timer
    public function pause() as Void {
        System.println("App.pause() called");
        
        if (_currentView != null) {
            _currentView.pause();
        } else {
            System.println("ERROR: No stored view reference!");
        }
    }

    // Method to resume the timer
    public function resume() as Void {
        System.println("App.resume() called");
        
        if (_currentView != null) {
            _currentView.resume();
        } else {
            System.println("ERROR: No stored view reference!");
        }
    }

    // Method to stop timer, send data, and exit app
    public function stopAndExit() as Void {
        System.println("App.stopAndExit() called");
        
        if (_currentView != null) {
            _currentView.stopAndExit();
        } else {
            System.println("ERROR: No stored view reference!");
        }
    }

    // Method to start the timer
    public function start() as Void {
        System.println("App.start() called");
        
        if (_currentView != null) {
            _currentView.start(); // Use direct start method
        } else {
            System.println("ERROR: No stored view reference!");
        }
    }

}

function getApp() as lap_timerApp {
    return Application.getApp() as lap_timerApp;
}