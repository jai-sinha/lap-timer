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
        
        // Check for start/stop button (KEY_ENTER in simulator, KEY_START/KEY_LAP on device)
        if (key == KEY_START || key == KEY_LAP || key == KEY_ENTER) {
            System.println("Start/Lap/Enter key detected, saving lap...");
            
            // Call the app's saveLap method
            var app = Application.getApp();
            if (app != null && app has :saveLap) {
                app.saveLap();
                System.println("Lap saved and timer reset via app");
                return true;
            } else {
                System.println("Error: Could not access app saveLap method");
                return false;
            }
        }
        
        return false;
    }

    function onKeyPressed(evt as WatchUi.KeyEvent) as Boolean {
        var key = evt.getKey();
        if (key == KEY_START || key == KEY_LAP || key == KEY_ENTER) {
            System.println("Start/Lap/Enter key pressed");
            // Could also trigger saveLap here if needed for press events
        }
        return false;
    }

    function onKeyReleased(evt as WatchUi.KeyEvent) as Boolean {
        var key = evt.getKey();
        if (key == KEY_START || key == KEY_LAP || key == KEY_ENTER) {
            System.println("Start/Lap/Enter key released");
        }
        return false;
    }

}