import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;

class lap_timerDelegate extends WatchUi.BehaviorDelegate {
    private var _model as lapTimerModel?;

    function initialize() {
        BehaviorDelegate.initialize();
        var app = Application.getApp() as lap_timerApp;
        _model = app.getModel();
    }

    function onKey(evt as WatchUi.KeyEvent) as Boolean {
        var key = evt.getKey();
        var model = _model;
        if (model == null) {
            return false;
        }

        // DOWN key for lap saving
        if (key == WatchUi.KEY_DOWN) {
            if (model.getState() == TIMER_RUNNING) {
                System.println("LapTimerDelegate - Saving lap time");
                model.saveLapAndReset();
                return true;
            }
        }

        // Start/Stop/Enter key
        if (key == WatchUi.KEY_ENTER) {
            var state = model.getState();
            if (state == TIMER_RUNNING) {
                model.pause();
                var pausedView = new PausedView();
                WatchUi.pushView(pausedView, new PausedViewDelegate(pausedView), WatchUi.SLIDE_UP);
            } else if (state == TIMER_STOPPED) {
                model.start();
            } else if (state == TIMER_PAUSED) {
                // This case should be handled by PausedViewDelegate
            }
            return true;
        }

        return false;
    }
}
