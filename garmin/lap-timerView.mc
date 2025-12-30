import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Lang;

class lap_timerView extends WatchUi.View {
    private var _model as lapTimerModel;

    function initialize(model as lapTimerModel) {
        View.initialize();
        _model = model;
    }

    function onLayout(dc as Dc) as Void {
        // No layout needed for simple drawing
    }

    function onShow() as Void {
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        View.onUpdate(dc);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var elapsedTime = _model.getElapsedTime();
        var timeString = formatTime(elapsedTime);
        var font = Graphics.FONT_LARGE;
        var textWidth = dc.getTextWidthInPixels(timeString, font);
        var textHeight = dc.getFontHeight(font);
        
        // Draw "Current Lap" label with lap count above the timer
        var lapCount = _model.getLapCount();
        var labelText = "Current Lap";
        if (lapCount > 0) {
            labelText += " (" + (lapCount + 1) + ")";
        }
        var labelFont = Graphics.FONT_MEDIUM;
        var labelWidth = dc.getTextWidthInPixels(labelText, labelFont);
        var labelHeight = dc.getFontHeight(labelFont);
        var labelX = (dc.getWidth() - labelWidth) / 2;
        var labelY = (dc.getHeight() - textHeight - labelHeight) / 2;
        
        dc.drawText(labelX, labelY, labelFont, labelText, Graphics.TEXT_JUSTIFY_LEFT);
        
        // Draw timer below the label
        var x = (dc.getWidth() - textWidth) / 2;
        var y = labelY + labelHeight + 5; // 5 pixels spacing
        dc.drawText(x, y, font, timeString, Graphics.TEXT_JUSTIFY_LEFT);
        
        // Draw Best Lap and Prev Lap below the timer
        var tinyFont = Graphics.FONT_XTINY;
        var bestLap = _model.getBestLap();
        var prevLap = _model.getPrevLap();

        var bestText = "B: " + (bestLap.length() > 0 ? bestLap : "--:--.--");
        var prevText = "P: " + (prevLap.length() > 0 ? prevLap : "--:--.--");
        
        var bestWidth = dc.getTextWidthInPixels(bestText, tinyFont);
        var prevWidth = dc.getTextWidthInPixels(prevText, tinyFont);
        
        var bestX = (dc.getWidth() / 2 - bestWidth) / 2;  // Left side
        var prevX = dc.getWidth() / 2 + (dc.getWidth() / 2 - prevWidth) / 2;  // Right side
        var statsY = y + textHeight + 8;  // Below timer
        
        dc.drawText(bestX, statsY, tinyFont, bestText, Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(prevX, statsY, tinyFont, prevText, Graphics.TEXT_JUSTIFY_LEFT);
    }

    function onHide() as Void {
        // The model will handle disabling GPS listeners if needed
    }

    // This method will be called by the model when its data changes
    public function onModelUpdate() as Void {
        WatchUi.requestUpdate();
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
}