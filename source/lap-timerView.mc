import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Lang;
import Toybox.Timer;

class lap_timerView extends WatchUi.View {
    private var _timer as Timer.Timer?;
    private var _startTime as Number = 0;
    private var _elapsedMs as Number = 0;
    private var _lapTimes as Array<String> = [];
    private var _lapTimesMs as Array<Number> = [];  // Keep raw ms for best lap calculation
    private var _bestLap as String = "";  // Best lap time (formatted string)
    private var _prevLap as String = "";  // Previous lap time (formatted string)

    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Dc) as Void {
        // No layout needed for simple drawing
    }

    function onShow() as Void {
        _startTime = System.getTimer();
        _timer = new Timer.Timer();
        _timer.start(method(:updateTimer), 100, true);
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
        var statsY = y + textHeight + 8;  // Below timer (reduced spacing)
        
        dc.drawText(bestX, statsY, tinyFont, bestText, Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(prevX, statsY, tinyFont, prevText, Graphics.TEXT_JUSTIFY_LEFT);
    }

    function onHide() as Void {
        if (_timer != null) {
            _timer.stop();
            _timer = null;
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