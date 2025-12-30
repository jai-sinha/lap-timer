import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;

class SelectViewDelegate extends WatchUi.BehaviorDelegate {
    private var _selectView as SelectView;

    function initialize(selectView as SelectView) {
        BehaviorDelegate.initialize();
        _selectView = selectView;
    }

    function onKey(evt as WatchUi.KeyEvent) as Boolean {
        var key = evt.getKey();
        
        // DOWN key for cycling through options
        if (key == 8) { // KEY_DOWN
            _selectView.cycleOption();
            return true;
        }
        
        // UP key for cycling through options in reverse
        if (key == 13) { // KEY_UP
            _selectView.cycleOptionReverse();
            return true;
        }
        
        // ENTER key for selecting option
        if (key == 4) { // KEY_ENTER
            var selectedTrack = _selectView.getSelectedTrack();
            System.println("Selected track index: " + selectedTrack);
            
            // Transition to the main timer view
            var app = Application.getApp();
            if (app != null) {
                app.startTimer(selectedTrack);
            }
            
            return true;
        }
        
        return false;
    }
}
