import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Lang;

class PausedView extends WatchUi.View {
    private var _highlightedOption as Number = 0; // 0: Resume, 1: Stop and Send Data

    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Dc) as Void {
        // No layout needed for simple drawing
    }

    function onShow() as Void {
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        View.onUpdate(dc);
        
        // Clear the screen
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        // Draw "PAUSED" title
        var titleFont = Graphics.FONT_LARGE;
        var titleText = "PAUSED";
        var titleWidth = dc.getTextWidthInPixels(titleText, titleFont);
        var titleHeight = dc.getFontHeight(titleFont);
        var titleX = (dc.getWidth() - titleWidth) / 2;
        var titleY = dc.getHeight() / 4;
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(titleX, titleY, titleFont, titleText, Graphics.TEXT_JUSTIFY_LEFT);
        
        // Draw options
        var optionFont = Graphics.FONT_MEDIUM;
        var optionHeight = dc.getFontHeight(optionFont);
        var spacing = 20;
        var startY = titleY + titleHeight + spacing;
        
        // Option 1: Resume
        var resumeText = "Resume";
        var resumeWidth = dc.getTextWidthInPixels(resumeText, optionFont);
        var resumeX = (dc.getWidth() - resumeWidth) / 2;
        var resumeY = startY;
        
        if (_highlightedOption == 0) {
            // Highlight Resume option
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
            dc.fillRectangle(resumeX - 5, resumeY - 2, resumeWidth + 10, optionHeight + 4);
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
        } else {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        }
        dc.drawText(resumeX, resumeY, optionFont, resumeText, Graphics.TEXT_JUSTIFY_LEFT);
        
        // Option 2: Stop and Send Data
        var stopText = "Stop & Send";
        var stopWidth = dc.getTextWidthInPixels(stopText, optionFont);
        var stopX = (dc.getWidth() - stopWidth) / 2;
        var stopY = resumeY + optionHeight + spacing;
        
        if (_highlightedOption == 1) {
            // Highlight Stop option
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
            dc.fillRectangle(stopX - 5, stopY - 2, stopWidth + 10, optionHeight + 4);
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
        } else {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        }
        dc.drawText(stopX, stopY, optionFont, stopText, Graphics.TEXT_JUSTIFY_LEFT);
        
    }

    function onHide() as Void {
        // Nothing to clean up
    }

    public function cycleOption() as Void {
        _highlightedOption = (_highlightedOption + 1) % 2;
        WatchUi.requestUpdate();
    }

    public function cycleOptionReverse() as Void {
        _highlightedOption = (_highlightedOption - 1 + 2) % 2;
        WatchUi.requestUpdate();
    }

    public function selectOption() as Number {
        return _highlightedOption;
    }

    public function getHighlightedOption() as Number {
        return _highlightedOption;
    }
}