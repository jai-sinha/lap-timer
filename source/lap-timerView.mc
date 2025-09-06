import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Position;

class lap_timerView extends WatchUi.View {

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
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        // Call the parent onUpdate function to redraw the layout
    View.onUpdate(dc);

    // draw dynamic lap stats
    var totalMs = getTotalTimeMillis();
    var curLapMs = getCurrentLapMillis();
    var prevMs = getPrevLapMillis();
    var fastMs = getFastestLapMillis();

    // set both foreground and background colors
    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    // drawText signature: drawText(x,y,font,text,justification)
    dc.drawText(10, 40, Graphics.FONT_TINY, Rez.Strings.label_total + ": " + formatDuration(totalMs), Graphics.TEXT_JUSTIFY_LEFT);
    dc.drawText(10, 56, Graphics.FONT_TINY, Rez.Strings.label_current + ": " + formatDuration(curLapMs), Graphics.TEXT_JUSTIFY_LEFT);
    dc.drawText(10, 72, Graphics.FONT_TINY, Rez.Strings.label_prev + ": " + formatDuration(prevMs), Graphics.TEXT_JUSTIFY_LEFT);
    dc.drawText(10, 88, Graphics.FONT_TINY, Rez.Strings.label_fastest + ": " + formatDuration(fastMs), Graphics.TEXT_JUSTIFY_LEFT);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

}
