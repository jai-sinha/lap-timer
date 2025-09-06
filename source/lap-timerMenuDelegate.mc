import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class lap_timerMenuDelegate extends WatchUi.MenuInputDelegate {

    function initialize() {
        MenuInputDelegate.initialize();
    }

    function onMenuItem(item as Symbol) as Void {
        if (item == :start_stop) {
            // call model API
            if (isRunning()) {
                stop();
            } else {
                start();
            }
        } else if (item == :reset) {
            reset();
        } else if (item == :presets) {
            // cycle presets via model
            var next = (getSelectedPresetIndex() + 1) % getPresetCount();
            selectPreset(next);
            System.println("Selected preset: " + getSelectedPresetName());
        }
    }

}