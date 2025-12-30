import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;

class PausedViewDelegate extends WatchUi.BehaviorDelegate {
    private var _pausedView as PausedView;

    function initialize(pausedView as PausedView) {
        BehaviorDelegate.initialize();
        _pausedView = pausedView;
    }

    function onKey(evt as WatchUi.KeyEvent) as Boolean {
        var key = evt.getKey();
        System.println("PausedViewDelegate - Key pressed: " + key);
        
        // DOWN key (8) for cycling through options
        if (key == 8) {
            _pausedView.cycleOption();
            return true;
        }
        
        // UP key (13) for cycling through options in reverse
        if (key == 13) {
            _pausedView.cycleOptionReverse();
            return true;
        }
        
        // ENTER key for selecting option
        if (key == 4) {
            var selectedOption = _pausedView.selectOption();
            System.println("PausedViewDelegate - Selected option: " + selectedOption);
            
            // Pop this view and return the selected option to the calling delegate
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            
            // Get the app and perform the selected action
            var app = Application.getApp();
            if (app != null) {
                if (selectedOption == 0) {
                    // Resume
                    System.println("PausedViewDelegate - Resuming timer");
                    app.resume();
                } else {
                    // Stop and send data, then exit app
                    System.println("PausedViewDelegate - Stopping and sending data, exiting app");
                    app.stopAndExit();
                }
            }
            
            return true;
        }
        
        // BACK key to resume (default action)
        if (key == WatchUi.KEY_ESC) {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            var app = Application.getApp();
            if (app != null) {
                app.resume();
            }
            return true;
        }
        
        return false;
    }
}