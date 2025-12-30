import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Lang;

class SelectView extends WatchUi.View {
    private var _highlightedOption as Number = 0;
    private var _tracks as Array<String>;

    function initialize() {
        View.initialize();
        // For now, we'll have a hardcoded list of tracks.
        _tracks = ["Track 1"];
    }

    function onLayout(dc as Dc) as Void {
        // No layout needed for simple drawing
    }

    function onShow() as Void {
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        View.onUpdate(dc);
        
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        var titleFont = Graphics.FONT_LARGE;
        var titleText = "Select Track";
        var titleWidth = dc.getTextWidthInPixels(titleText, titleFont);
        var titleX = (dc.getWidth() - titleWidth) / 2;
        var titleY = dc.getHeight() / 4;
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(titleX, titleY, titleFont, titleText, Graphics.TEXT_JUSTIFY_LEFT);
        
        var optionFont = Graphics.FONT_MEDIUM;
        var optionHeight = dc.getFontHeight(optionFont);
        var spacing = 20;
        var startY = titleY + dc.getFontHeight(titleFont) + spacing;

        for (var i = 0; i < _tracks.size(); i++) {
            var optionText = _tracks[i];
            var optionWidth = dc.getTextWidthInPixels(optionText, optionFont);
            var optionX = (dc.getWidth() - optionWidth) / 2;
            var optionY = startY + (i * (optionHeight + spacing));

            if (_highlightedOption == i) {
                dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
                dc.fillRectangle(optionX - 5, optionY - 2, optionWidth + 10, optionHeight + 4);
                dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
            } else {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
            }
            dc.drawText(optionX, optionY, optionFont, optionText, Graphics.TEXT_JUSTIFY_LEFT);
        }
    }

    function onHide() as Void {
    }

    public function cycleOption() as Void {
        _highlightedOption = (_highlightedOption + 1) % _tracks.size();
        WatchUi.requestUpdate();
    }

    public function cycleOptionReverse() as Void {
        _highlightedOption = (_highlightedOption - 1 + _tracks.size()) % _tracks.size();
        WatchUi.requestUpdate();
    }

    public function getSelectedTrack() as Number {
        return _highlightedOption;
    }
}
