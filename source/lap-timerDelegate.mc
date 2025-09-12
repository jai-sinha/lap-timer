import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Attention;

class lap_timerDelegate extends WatchUi.BehaviorDelegate {

    var backlightOn as Boolean = false;

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onKey(key as KeyEvent) as Boolean {
        var keyCode = key[:key];
        var state = key[:state];
        if (state == WatchUi.PRESS_TYPE_DOWN) {
            if (keyCode == WatchUi.KEY_START) {
                if (isRunning()) {
                    stop();
                    var view = WatchUi.getCurrentView()[0] as lap_timerView;
                    if (view != null) {
                        view.stopTimer();
                    }
                } else {
                    start();
                    var view = WatchUi.getCurrentView()[0] as lap_timerView;
                    if (view != null) {
                        view.startTimer();
                    }
                }
                WatchUi.requestUpdate();
                return true;
            } else if (keyCode == WatchUi.KEY_UP) {
                // cycle screen up
                var next = (getScreenIndex() + 1) % getScreenCount();
                setScreenIndex(next);
                WatchUi.requestUpdate();
                return true;
            } else if (keyCode == WatchUi.KEY_DOWN) {
                // cycle screen down
                var prev = (getScreenIndex() - 1 + getScreenCount()) % getScreenCount();
                setScreenIndex(prev);
                WatchUi.requestUpdate();
                return true;
            } else if (keyCode == WatchUi.KEY_LIGHT) {
                // toggle backlight
                backlightOn = !backlightOn;
                if (Attention != null) {
                    Attention.backlight(backlightOn);
                }
                return true;
            } else if (keyCode == WatchUi.KEY_ESC) {
                // back, exit to home
                WatchUi.popView(WatchUi.SLIDE_DOWN);
                return true;
            }
        }
        return false;
    }

}