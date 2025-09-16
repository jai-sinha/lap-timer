import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;

class lap_timerDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onMenu() as Boolean {
        WatchUi.pushView(new Rez.Menus.MainMenu(), new lap_timerMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }

    function onKey(evt as WatchUi.KeyEvent) as Boolean {
        var key = evt.getKey();
        System.println("Key pressed: " + key);
        System.println(evt.getKey());
        
        // DOWN key for lap saving
        if (key == 8) {
            var app = Application.getApp();
            // Save lap if not paused
            if (app != null && app has :saveLap) {
                app.saveLap();
                return true;
            }
            return false;
        }
        
        // Start/Stop/Enter key for program start/stop and data send
        if (key == 4) {
            var app = Application.getApp();
            System.println("ENTER key pressed, app: " + app);
            if (app != null) {
                var state = app.getState();
                System.println("Current state: " + state);
                if (state == TIMER_RUNNING) {
                    // Pause and show the PausedView
                    System.println("Pausing timer...");
                    app.pause();
                    var pausedView = new PausedView();
                    WatchUi.pushView(pausedView, new PausedViewDelegate(pausedView), WatchUi.SLIDE_UP);
                    return true;
                } else if (state == TIMER_STOPPED) {
                    System.println("Starting timer...");
                    app.start();
                    System.println("app.start() called");
                    return true;
                }
            }
            return false;
        }
        
        return false;
    }

}