import Toybox.Lang;
import Toybox.WatchUi;

class lap_timerDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onMenu() as Boolean {
        WatchUi.pushView(new Rez.Menus.MainMenu(), new lap_timerMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }

}