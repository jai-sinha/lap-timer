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
        
        // LIGHT key for lap saving
        if (key == 8) {
            System.println("LIGHT key (8) detected, saving lap...");
            var app = Application.getApp();
            if (app != null && app has :saveLap) {
                app.saveLap();
                return true;
            }
            return false;
        }
        
        // Start/Stop/Enter key for program start/stop and data send
        if (key == KEY_START || key == KEY_LAP || key == KEY_ENTER) {
            System.println("Start/Lap/Enter key detected, starting/stopping program...");
            var app = Application.getApp();
            if (app != null && app has :toggleProgram) {
                app.toggleProgram();
                return true;
            }
            return false;
        }
        
        return false;
    }

}