import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Lang;
import Toybox.Timer;
import Toybox.Communications;
import Toybox.Position;
import Toybox.Math;

class lap_timerView extends WatchUi.View {
    private var _timer as Timer.Timer?;
    private var _startTime as Number = 0;
    private var _elapsedMs as Number = 0;
    private var _lapTimes as Array<String> = [];
    private var _lapTimesMs as Array<Number> = [];  // Keep raw ms for best lap calculation
    private var _bestLap as String = "";  // Best lap time (formatted string)
    private var _prevLap as String = "";  // Previous lap time (formatted string)
    private var _isRunning as Boolean = false;
    private var _state as Number = TIMER_STOPPED;
    
    // GPS-related variables
    private var _currentLocation as Position.Location?;
    private var _lastLocation as Position.Location?;
    private var _startFinishLat as Float = 37.52126; // San Francisco test coordinates
    private var _startFinishLon as Float = -122.302884;
    private var _crossingThreshold as Float = 0.0001; // ~11 meters at this latitude
    private var _hasStarted as Boolean = false;
    private var _lastCrossingSide as Number = 0; // -1 or 1 to track which side of line we're on

    function initialize() {
        View.initialize();
        // Enable position tracking
        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
    }

    function onLayout(dc as Dc) as Void {
        // No layout needed for simple drawing
    }

    function onShow() as Void {
        // Timer will be started via user input
    }

    function onUpdate(dc as Dc) as Void {
        View.onUpdate(dc);
        var timeString = formatTime(_elapsedMs);
        var font = Graphics.FONT_LARGE;
        var textWidth = dc.getTextWidthInPixels(timeString, font);
        var textHeight = dc.getFontHeight(font);
        
        // Draw "Current Lap" label with lap count above the timer
        var lapCount = getLapCount();
        var labelText = "Current Lap";
        if (lapCount > 0) {
            labelText += " (" + (lapCount + 1) + ")";
        }
        var labelFont = Graphics.FONT_MEDIUM;
        var labelWidth = dc.getTextWidthInPixels(labelText, labelFont);
        var labelHeight = dc.getFontHeight(labelFont);
        var labelX = (dc.getWidth() - labelWidth) / 2;
        var labelY = (dc.getHeight() - textHeight - labelHeight) / 2;
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(labelX, labelY, labelFont, labelText, Graphics.TEXT_JUSTIFY_LEFT);
        
        // Draw timer below the label
        var x = (dc.getWidth() - textWidth) / 2;
        var y = labelY + labelHeight + 5; // 5 pixels spacing
        dc.drawText(x, y, font, timeString, Graphics.TEXT_JUSTIFY_LEFT);
        
        // Draw Best Lap and Prev Lap below the timer
        var tinyFont = Graphics.FONT_XTINY;
        var bestText = "B: " + (_bestLap.length() > 0 ? _bestLap : "--:--.-");
        var prevText = "P: " + (_prevLap.length() > 0 ? _prevLap : "--:--.-");
        
        var bestWidth = dc.getTextWidthInPixels(bestText, tinyFont);
        var prevWidth = dc.getTextWidthInPixels(prevText, tinyFont);
        
        var bestX = (dc.getWidth() / 2 - bestWidth) / 2;  // Left side
        var prevX = dc.getWidth() / 2 + (dc.getWidth() / 2 - prevWidth) / 2;  // Right side
        var statsY = y + textHeight + 8;  // Below timer
        
        dc.drawText(bestX, statsY, tinyFont, bestText, Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(prevX, statsY, tinyFont, prevText, Graphics.TEXT_JUSTIFY_LEFT);
    }

    function onHide() as Void {
        if (_timer != null) {
            _timer.stop();
            _timer = null;
        }
        _isRunning = false;
        // Disable position tracking when view is hidden
        Position.enableLocationEvents(Position.LOCATION_DISABLE, null);
    }

    // Check if the user has crossed the start/finish line
    private function checkLineCrossing() as Void {
        if (_currentLocation == null || _lastLocation == null) {
            return;
        }
        
        var currentCoords = _currentLocation.toDegrees();
        var currentLat = currentCoords[0].toFloat();
        var currentLon = currentCoords[1].toFloat();
        var lastCoords = _lastLocation.toDegrees();
        var lastLat = lastCoords[0].toFloat();
        
        // Calculate distance from current position to start/finish line
        var currentDistance = calculateDistance(currentLat, currentLon, _startFinishLat, _startFinishLon);
        
        // Determine which side of the line we're on (simple approach using latitude difference)
        var currentSide = currentLat > _startFinishLat ? 1 : -1;
        var lastSide = lastLat > _startFinishLat ? 1 : -1;
        
        // Check if we've crossed the line (different sides) and are close enough
        if (currentSide != lastSide && currentDistance < _crossingThreshold) {
            if (!_hasStarted) {
                // First crossing establishes our starting position
                _hasStarted = true;
                _lastCrossingSide = currentSide;
                System.println("GPS: Timer started, established start/finish line");
            } else if (_lastCrossingSide != 0 && currentSide != _lastCrossingSide) {
                // We've crossed back to complete a lap
                System.println("GPS: Line crossing detected! Auto-counting lap");
                saveLapAndReset();
                _lastCrossingSide = currentSide;
            }
        }
    }

    // Calculate distance between two GPS coordinates (simple approximation)
    private function calculateDistance(lat1 as Float, lon1 as Float, lat2 as Float, lon2 as Float) as Float {
        var latDiff = lat1 - lat2;
        var lonDiff = lon1 - lon2;
        return Math.sqrt(latDiff * latDiff + lonDiff * lonDiff);
    }

    // GPS position callback
    function onPosition(info as Position.Info) as Void {
        if (info.position != null) {
            _lastLocation = _currentLocation;
            _currentLocation = info.position;
            
            // Check for start/finish line crossing if timer is running
            if (_isRunning && _currentLocation != null && _lastLocation != null) {
                checkLineCrossing();
            }
        }
    }

    private function startTimer() as Void {
        _startTime = System.getTimer() - _elapsedMs;  // Adjust for paused time
        _timer = new Timer.Timer();
        _timer.start(method(:updateTimer), 100, true);
        _isRunning = true;
        _state = TIMER_RUNNING;
        
        // Reset GPS tracking state when starting
        _hasStarted = false;
        _lastCrossingSide = 0;
        
        WatchUi.requestUpdate();
    }

    private function stopTimer() as Void {
        if (_timer != null) {
            _timer.stop();
            _timer = null;
        }
        _isRunning = false;
        _state = TIMER_STOPPED;
        WatchUi.requestUpdate();
    }

    public function pause() as Void {
        if (_timer != null) {
            _timer.stop();
            _timer = null;
        }
        _isRunning = false;
        _state = TIMER_PAUSED;
        WatchUi.requestUpdate();
    }

    public function resume() as Void {
        _startTime = System.getTimer() - _elapsedMs;  // Adjust for paused time
        _timer = new Timer.Timer();
        _timer.start(method(:updateTimer), 100, true);
        _isRunning = true;
        _state = TIMER_RUNNING;
        WatchUi.requestUpdate();
    }

    public function getState() as Number {
        return _state;
    }

    public function stopAndExit() as Void {
        stopTimer();
        sendDataToPhone();
        System.exit();
    }

    public function start() as Void {
        if (!_isRunning) {
            startTimer();
        }
    }

    private function sendDataToPhone() as Void {
        var data = {
            "lapTimes" => _lapTimes,
            "bestLap" => _bestLap,
            "totalTime" => formatTime(_elapsedMs)
        };
        Communications.makeWebRequest(
            "https://example.com/api/lap-data",  // Replace with actual endpoint
            data,
            {
                :method => Communications.HTTP_REQUEST_METHOD_POST,
                :headers => {
                    "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON
                }
            },
            method(:onDataSent)
        );
    }

    function onDataSent(responseCode as Number, data as Dictionary) as Void {
        if (responseCode == 200) {
            System.println("Data sent successfully");
        } else {
            System.println("Failed to send data: " + responseCode);
        }
    }

    private function formatTime(ms as Number) as String {
        var totalSeconds = ms / 1000;
        var minutes = totalSeconds / 60;
        var seconds = totalSeconds % 60;
        var milliseconds = (ms % 1000) / 100;
        return minutes.format("%02d") + ":" + seconds.format("%02d") + "." + milliseconds.format("%1d");
    }

    public function updateTimer() as Void {
        _elapsedMs = System.getTimer() - _startTime;
        WatchUi.requestUpdate();
    }

    public function saveLapAndReset() as Void {
        System.println("saveLapAndReset called! Current elapsed: " + _elapsedMs);
        
        // Format current lap time as string
        var formattedLapTime = formatTime(_elapsedMs);
        
        // Save current lap time as formatted string and raw milliseconds
        _lapTimes.add(formattedLapTime);
        _lapTimesMs.add(_elapsedMs);
        System.println("Added lap time: " + formattedLapTime + ", total laps: " + _lapTimes.size());
        
        // Update previous lap
        _prevLap = formattedLapTime;
        
        // Update best lap (find minimum by comparing raw millisecond values)
        if (_lapTimes.size() == 1) {
            _bestLap = formattedLapTime;
        } else {
            // Find the index of the best lap by comparing raw milliseconds
            var bestIndex = 0;
            for (var i = 1; i < _lapTimesMs.size(); i++) {
                if (_lapTimesMs[i] < _lapTimesMs[bestIndex]) {
                    bestIndex = i;
                }
            }
            _bestLap = _lapTimes[bestIndex];
        }
        
        // Print lap times array, best lap, and prev lap to console
        System.println("Lap times array: " + _lapTimes.toString());
        System.println("Best lap: " + _bestLap);
        System.println("Previous lap: " + _prevLap);
        
        // Reset timer
        _startTime = System.getTimer();
        _elapsedMs = 0;
        System.println("Timer reset to 0");
        
        // Request update to refresh display
        WatchUi.requestUpdate();
        System.println("Requested UI update");
    }

    public function getLapCount() as Number {
        return _lapTimes.size();
    }

    public function getLapTimes() as Array<String> {
        return _lapTimes;
    }
}