import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Lang;
import Toybox.Position;
import Toybox.Timer;

class lap_timerView extends WatchUi.View {

    var uiTimer as Timer.Timer or Null = null;

    function initialize() {
        View.initialize();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.MainLayout(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
        if (isRunning() and uiTimer == null) {
            uiTimer = new Timer.Timer();
            uiTimer.start(method(:updateDisplay), 1000, true);
        }
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        // Call the parent onUpdate function to redraw the layout
    View.onUpdate(dc);

    // draw dynamic lap stats
    var screenIndex = getScreenIndex();
    if (screenIndex == 0) {
        // Times screen
        var totalMs = getTotalTimeMillis();
        var curLapMs = getCurrentLapMillis();
        var prevMs = getPrevLapMillis();
        var fastMs = getFastestLapMillis();
        dc.drawText(10, 10, Graphics.FONT_TINY, Rez.Strings.label_total + ": " + formatDuration(totalMs), Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(10, 26, Graphics.FONT_TINY, Rez.Strings.label_current + ": " + formatDuration(curLapMs), Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(10, 42, Graphics.FONT_TINY, Rez.Strings.label_prev + ": " + formatDuration(prevMs), Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(10, 58, Graphics.FONT_TINY, Rez.Strings.label_fastest + ": " + formatDuration(fastMs), Graphics.TEXT_JUSTIFY_LEFT);
    } else if (screenIndex == 1) {
        // Speeds screen
        var curSpeed = getCurrentSpeed();
        var avgSpeed = getAvgSpeed();
        var maxSpeed = getMaxSpeed();
        dc.drawText(10, 10, Graphics.FONT_TINY, "Current Speed: " + curSpeed.format("%.1f") + " mph", Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(10, 26, Graphics.FONT_TINY, "Avg Speed: " + avgSpeed.format("%.1f") + " mph", Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(10, 42, Graphics.FONT_TINY, "Max Speed: " + maxSpeed.format("%.1f") + " mph", Graphics.TEXT_JUSTIFY_LEFT);
    } else if (screenIndex == 2) {
        // Laps screen
        var laps = getLaps();
        dc.drawText(10, 10, Graphics.FONT_TINY, "Completed Laps:", Graphics.TEXT_JUSTIFY_LEFT);
        for (var i = 0; i < laps.size() and i < 5; i++) {
            dc.drawText(10, 26 + i * 16, Graphics.FONT_TINY, "Lap " + (i + 1) + ": " + formatDuration(laps[i]), Graphics.TEXT_JUSTIFY_LEFT);
        }
    }
    // Draw GPS status and toast/status area
    drawGpsStatus(dc);
    drawStatusToast(dc);
    }

    // Timer callback removed — kept out to simplify analyzer and builds here.

    // Draw GPS status in the top-right
    function drawGpsStatus(dc as Dc) as Void {
        if (Position == null) {
            return;
        }
        try {
            var info = Position.getInfo();
            var status = "GPS: ?";
            if (info == null || !(info has :position) || info.position == null) {
                status = "GPS: No Fix";
            } else {
                status = "GPS: OK";
            }
            dc.drawText(dc.getWidth() - 10, 5, Graphics.FONT_TINY, status, Graphics.TEXT_JUSTIFY_RIGHT);
        } catch (ex) {
            // ignore
        }
    }

    // Draw a simple toast at the bottom center showing the latest status message
    function drawStatusToast(dc as Dc) as Void {
        try {
            var msgs = getStatusMessages();
            if (msgs != null and msgs.size() > 0) {
                var last = msgs[msgs.size() - 1];
                var text = last[:msg];
                // Draw semi-transparent background box; approximate width since getTextWidth may vary
                var w = (text.size() * 6) + 16;
                var h = 18;
                var x = (dc.getWidth() - w) / 2;
                var y = dc.getHeight() - h - 5;
                dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
                // background rectangle (filled)
                dc.fillRectangle(x, y, w, h);
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(x + (w/2), y + 4, Graphics.FONT_TINY, text, Graphics.TEXT_JUSTIFY_CENTER);
            }
        } catch (ex) {
            // ignore
        }
    }

    function startTimer() as Void {
        if (uiTimer == null) {
            uiTimer = new Timer.Timer();
            uiTimer.start(method(:updateDisplay), 1000, true);
        }
    }

    function stopTimer() as Void {
        if (uiTimer != null) {
            uiTimer.stop();
            uiTimer = null;
        }
    }

    function updateDisplay() as Void {
        WatchUi.requestUpdate();
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
        if (uiTimer != null) {
            uiTimer.stop();
            uiTimer = null;
        }
    }


}
