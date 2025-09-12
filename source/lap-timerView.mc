import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Timer;
import Toybox.System;
import Toybox.Lang;

class lap_timerView extends WatchUi.View {
    private var _timer as Timer.Timer?;
    private var _startTime as Number = 0;
    private var _elapsedMs as Number = 0;

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
        
        // Draw "Current Lap" label above the timer
        var labelText = "Current Lap";
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
}