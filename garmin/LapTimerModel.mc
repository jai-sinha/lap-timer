import Toybox.Lang;
import Toybox.System;
import Toybox.Timer;
import Toybox.Position;
import Toybox.Math;
import Toybox.ActivityRecording;
import Toybox.Activity;
import Toybox.Sensor;

(:TimerState)
enum {
    TIMER_STOPPED,
    TIMER_RUNNING,
    TIMER_PAUSED
}

class lapTimerModel {
    private var _state as Number = TIMER_STOPPED;
    private var _timer as Timer.Timer?;
    private var _session as ActivityRecording.Session?;
    private var _startTime as Number = 0;
    private var _elapsedMs as Number = 0;
    private var _lapTimes as Array<String> = [];
    private var _lapTimesMs as Array<Number> = [];
    private var _bestLap as String = "";
    private var _prevLap as String = "";
    private var _currentHeartRate as Number = 0;

    // GPS-related variables
    private var _currentLocation as Position.Location?;
    private var _lastLocation as Position.Location?;
    private var _startFinishLat as Float = 37.52126; // San Francisco test coordinates
    private var _startFinishLon as Float = -122.302884;
    private var _crossingThreshold as Float = 0.0001; // ~11 meters at this latitude
    private var _hasStarted as Boolean = false;
    private var _lastCrossingSide as Number = 0; // -1 or 1 to track which side of line we're on
    private var _selectedTrack as Number = 0;

    private var _view as WeakReference?;

    function initialize() {
        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
        Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE]);
        Sensor.enableSensorEvents(method(:onSensor));
        _timer = new Timer.Timer();
    }

    public function getTimer() as Timer.Timer? {
        return _timer;
    }

    public function createTimer() as Void {
        if (_timer == null) {
            _timer = new Timer.Timer();
        }
    }

    public function setView(view as lap_timerView) {
        _view = view.weak();
    }

    public function setTrack(track as Number) as Void {
        _selectedTrack = track;
        if (_selectedTrack == 0) {
            // Default to SF test coordinates
            _startFinishLat = 37.52126;
            _startFinishLon = -122.302884;
        } else if (_selectedTrack == 1) {
            // Another set of coordinates
            _startFinishLat = 34.0522;
            _startFinishLon = -118.2437;
        }
    }

    // --- Timer Controls ---

    public function start() as Void {
        if (_state != TIMER_RUNNING) {
            _state = TIMER_RUNNING;
            _startTime = System.getTimer();
            _hasStarted = true;
            
            // Start Activity Recording
            if (_session == null) {
                _session = ActivityRecording.createSession({
                    :name => "Track Session",
                    :sport => Activity.SPORT_AUTO_RACING, // Using Auto Racing as base sport
                    :subSport => Activity.SUB_SPORT_GENERIC
                });
            }
            if (_session != null) {
                _session.start();
            }

            if (_timer != null) {
                _timer.start(method(:onTimer), 100, true);
            }
            System.println("Model: Timer state set to RUNNING");
            notifyView();
        }
    }

    public function pause() as Void {
        if (_state == TIMER_RUNNING) {
            if (_timer != null) {
                _timer.stop();
            }
            if (_session != null && _session.isRecording()) {
                _session.stop();
            }
            _state = TIMER_PAUSED;
            _elapsedMs += System.getTimer() - _startTime;
            System.println("Model: Timer paused");
            notifyView();
        }
    }

    public function resume() as Void {
        if (_state == TIMER_PAUSED) {
            _state = TIMER_RUNNING;
            _startTime = System.getTimer();
            if (_session != null) {
                _session.start();
            }
            if (_timer != null) {
                _timer.start(method(:onTimer), 100, true);
            }
            System.println("Model: Timer resumed");
            notifyView();
        }
    }

    public function stop() as Void {
        if (_state != TIMER_STOPPED) {
            if (_timer != null) {
                _timer.stop();
            }
            if (_session != null && _session.isRecording()) {
                _session.stop();
            }
            if (_state == TIMER_RUNNING) {
                 _elapsedMs += System.getTimer() - _startTime;
            }
            _state = TIMER_STOPPED;
            System.println("Model: Timer stopped");
            notifyView();
        }
    }

    public function saveRecording() as Void {
        if (_session != null) {
            // For development: Discard the session to avoid saving .fit files to the watch
            // In production, you would use _session.save() to let Garmin Connect sync it
            _session.discard(); 
            _session = null;
            System.println("Model: Session saved (Simulated - Discarded for Dev)");
        }
    }

    public function discardRecording() as Void {
        if (_session != null) {
            _session.discard();
            _session = null;
            System.println("Model: Session discarded");
        }
    }

    public function reset() as Void {
        if (_timer != null) {
            _timer.stop();
        }
        discardRecording(); // Discard any active session on reset
        _state = TIMER_STOPPED;
        _elapsedMs = 0;
        _lapTimes = [];
        _lapTimesMs = [];
        _bestLap = "";
        _prevLap = "";
        _hasStarted = false;
        _lastCrossingSide = 0;
        System.println("Model: Timer reset");
        notifyView();
    }

    public function saveLapAndReset() as Void {
        var lapTimeMs = getElapsedTime();
        if (lapTimeMs > 0) {
            // Add lap to FIT file
            if (_session != null && _session.isRecording()) {
                _session.addLap();
            }

            _lapTimesMs.add(lapTimeMs);
            var lapTimeFormatted = formatTime(lapTimeMs);
            _lapTimes.add(lapTimeFormatted);
            _prevLap = lapTimeFormatted;

            // Update best lap
            if (_lapTimesMs.size() > 0) {
                var bestLapMs = min(_lapTimesMs);
                if (lapTimeMs == bestLapMs) {
                    _bestLap = lapTimeFormatted;
                }
            } else {
                _bestLap = lapTimeFormatted;
            }
        }
        // Reset the current lap timer
        _startTime = System.getTimer();
        _elapsedMs = 0;
        notifyView();
    }

    // --- Getters ---

    public function getState() as Number {
        return _state;
    }

    public function getElapsedTime() as Number {
        var currentElapsed = _elapsedMs;
        if (_state == TIMER_RUNNING) {
            currentElapsed += System.getTimer() - _startTime;
        }
        return currentElapsed;
    }

    public function getLapCount() as Number {
        return _lapTimes.size();
    }

    public function getBestLap() as String {
        return _bestLap;
    }

    public function getPrevLap() as String {
        return _prevLap;
    }

    public function getLapTimes() as Array<String> {
        return _lapTimes;
    }

    public function getTotalTime() as String {
        return formatTime(sum(_lapTimesMs));
    }

    public function getCurrentHeartRate() as Number {
        return _currentHeartRate;
    }

    public function onTimer() as Void {
        if (_state == TIMER_RUNNING) {
            notifyView();
        }
    }

    public function onSensor(info as Sensor.Info) as Void {
        if (info.heartRate != null) {
            _currentHeartRate = info.heartRate;
            System.println("HR: " + _currentHeartRate);
        }
    }

    // --- Private Helpers ---

    private function notifyView() as Void {
        if (_view != null) {
            var view = _view.get();
            if (view != null && view instanceof lap_timerView) {
                view.onModelUpdate();
            }
        }
    }

    private function formatTime(ms as Number) as String {
        var totalSeconds = ms / 1000;
        var minutes = totalSeconds / 60;
        var seconds = totalSeconds % 60;
        var hundredths = (ms % 1000) / 10;
        return Lang.format("$1$:$2$.$3$", [
            minutes.format("%02d"),
            seconds.format("%02d"),
            hundredths.format("%02d")
        ]);
    }

    private function sum(arr as Array<Number>) as Number {
        var total = 0;
        for (var i = 0; i < arr.size(); i++) {
            total += arr[i];
        }
        return total;
    }

    private function min(arr as Array<Number>) as Number {
        if (arr.size() == 0) {
            return 0;
        }
        var minVal = arr[0];
        for (var i = 1; i < arr.size(); i++) {
            if (arr[i] < minVal) {
                minVal = arr[i];
            }
        }
        return minVal;
    }

    // --- GPS Handling ---
    public function onPosition(info as Position.Info) as Void {
        if (info.accuracy >= Position.QUALITY_USABLE) {
            _currentLocation = info.position;
            var deg = _currentLocation.toDegrees();
            System.println("GPS: " + deg[0] + ", " + deg[1]);
            if (_lastLocation != null && _hasStarted) {
                checkStartFinishLineCrossing();
            }
            _lastLocation = _currentLocation;
        }
    }

    private function checkStartFinishLineCrossing() as Void {
        if (_currentLocation == null || _lastLocation == null) {
            return;
        }

        var currentLat = _currentLocation.toDegrees()[0];
        var currentLon = _currentLocation.toDegrees()[1];
        var lastLat = _lastLocation.toDegrees()[0];
        var lastLon = _lastLocation.toDegrees()[1];

        // A simple line crossing algorithm. This assumes the start/finish line is mostly North-South.
        // A more robust solution would use vector math.
        var currentSide = (currentLon > _startFinishLon) ? 1 : -1;
        var lastSide = (lastLon > _startFinishLon) ? 1 : -1;

        if (_lastCrossingSide != 0 && currentSide != lastSide) {
            // Check if the crossing point is within the latitude bounds of the start/finish line segment
            var lat1 = _startFinishLat - _crossingThreshold;
            var lat2 = _startFinishLat + _crossingThreshold;

            // A simple interpolation to estimate the latitude at the crossing point
            var lonDiff = currentLon - lastLon;
            if (lonDiff != 0) {
                var crossingLat = lastLat + (currentLat - lastLat) * (_startFinishLon - lastLon) / lonDiff;
                if (crossingLat >= lat1 && crossingLat <= lat2) {
                    System.println("Start/Finish line crossed!");
                    saveLapAndReset();
                }
            }
        }
        _lastCrossingSide = currentSide;
    }
}
