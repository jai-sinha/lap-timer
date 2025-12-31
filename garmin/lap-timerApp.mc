import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Communications;

class Listener extends Communications.ConnectionListener {
    function initialize() {
        Communications.ConnectionListener.initialize();
    }
    function onComplete() {
        System.println("Connection successful!");
    }
    function onError() {
        System.println("Connection failed!");
    }
}

class lap_timerApp extends Application.AppBase {
    private var _model as lapTimerModel?;
    private var _view as lap_timerView?;
    private var _delegate as lap_timerDelegate?;

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        _model = new lapTimerModel();
        _view = new lap_timerView(_model);
        _delegate = new lap_timerDelegate();
        var model = _model;
        if (model != null) {
            model.setView(_view);
        }
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    public function getModel() as lapTimerModel? {
        return _model;
    }

    // Return the initial view of your application here
    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        var view = _view;
        var delegate = _delegate;
        if (view != null && delegate != null) {
            return [view, delegate];
        } else if (view != null) {
            return [view];
        }
        throw new Lang.InvalidValueException("View not initialized");
    }

    public function start() as Void {
        var model = _model;
        if (model != null) {
            model.start();
        }
    }

    public function pause() as Void {
        var model = _model;
        if (model != null) {
            model.pause();
        }
    }

    public function saveLapAndReset() as Void {
        var model = _model;
        if (model != null) {
            model.saveLapAndReset();
        }
    }

    public function startTimer(selectedTrack as Number) as Void {
        var model = _model;
        var view = _view;
        var delegate = _delegate;
        if (model != null && view != null && delegate != null) {
            model.setTrack(selectedTrack);
            System.println("Starting timer for track: " + selectedTrack);
            WatchUi.pushView(view, delegate, WatchUi.SLIDE_UP);
        }
    }

    public function resume() as Void {
        var model = _model;
        if (model != null) {
            model.resume();
        }
    }

    public function stopAndExit() as Void {
        var model = _model;
        if (model != null) {
            model.stop();
        }
        sendSessionData();
        System.exit();
    }

    private function sendSessionData() as Void {
        var model = _model;
        if (model == null) {
            return;
        }
        var lapTimes = model.getLapTimes();
        var bestLap = model.getBestLap();
        var totalTime = model.getTotalTime();

        var payload = {
            "results" => {
                "lapTimes" => lapTimes,
                "bestLap" => bestLap,
                "totalTime" => totalTime
            }
        };

        var jsonString = toJsonString(payload);
        System.println("Sending session data to phone app: " + jsonString);
        sendMessageToPhoneApp(jsonString);
    }

    private function sendMessageToPhoneApp(message as String) as Void {
        var listener = new Listener();
        Communications.transmit(message, null, listener);
    }

    // Manually serialize a dictionary to a JSON string
    private function toJsonString(payload as Dictionary) as String {
        var results = payload["results"] as Dictionary;
        var lapTimesArr = results["lapTimes"] as Array<String>;
        var lapTimesStr = "[";
        for (var i = 0; i < lapTimesArr.size(); i++) {
            lapTimesStr += "\"" + (lapTimesArr[i] as String) + "\"";
            if (i < lapTimesArr.size() - 1) {
                lapTimesStr += ",";
            }
        }
        lapTimesStr += "]";
        var bestLapStr = results["bestLap"] as String;
        var totalTimeStr = results["totalTime"] as String;
        var json = "{\"results\":{";
        json += "\"lapTimes\":" + lapTimesStr + ",";
        json += "\"bestLap\":\"" + bestLapStr + "\",";
        json += "\"totalTime\":\"" + totalTimeStr + "\"";
        json += "}}";
        return json;
    }
}

function getApp() as lap_timerApp {
    return Application.getApp() as lap_timerApp;
}
