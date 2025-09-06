import Toybox.System;
import Toybox.Lang;
import Toybox.Math;

// Simple global model for lap timer state and logic.

var lt_running = false;
var lt_startTime = 0;
var lt_currentLapStart = 0;
var lt_lastStopTime = 0;
var lt_prevLap = 0;
var lt_fastestLap = 0;
var lt_laps as Array = [];
var lt_lastWasInside = false;

// Each preset: [ name, lat, lon, radius ]
// presets: Array of [String, Number, Number, Number]
var lt_presets as Array = [
    [ "Track Start", 37.4219999, -122.0840575, 25 ],
    [ "Park Gate",    40.712776,  -74.005974,   30 ],
    [ "Home",         51.507351,  -0.127758,    25 ]
];

var lt_selectedPreset as Number = 0;

function _nowMillis() as Number {
    // System.getClockTime() returns a ClockTime struct; use its seconds field
    var t = System.getClockTime();
    // access the 'seconds' field explicitly
    var sec = t[:seconds];
    // Ensure we return an integer Number (avoid Float/Double polytypes)
    return Toybox.Math.floor(sec * 1000);
}

function isRunning() as Boolean {
    return lt_running;
}

function _distanceMeters(lat1 as Number, lon1 as Number, lat2 as Number, lon2 as Number) as Number {
    var R = 6371000.0;
    var toRad = 3.141592653589793 / 180.0;
    var dLat = (lat2 - lat1) * toRad;
    var dLon = (lon2 - lon1) * toRad;
    var a = Toybox.Math.sin(dLat/2.0) * Toybox.Math.sin(dLat/2.0) + Toybox.Math.cos(lat1*toRad) * Toybox.Math.cos(lat2*toRad) * Toybox.Math.sin(dLon/2.0) * Toybox.Math.sin(dLon/2.0);
    var c = 2.0 * Toybox.Math.atan2(Toybox.Math.sqrt(a), Toybox.Math.sqrt(1.0 - a));
    // return as Number (integer) to match expected return type
    return Toybox.Math.floor(R * c);
}

function start() as Void {
    if (!lt_running) {
        var now = _nowMillis();
        lt_running = true;
        lt_startTime = now;
        lt_currentLapStart = now;
        lt_lastStopTime = 0;
        lt_laps = [];
        lt_prevLap = 0;
        lt_fastestLap = 0;
        lt_lastWasInside = false;
    }
}

function stop() as Void {
    if (lt_running) {
        lt_lastStopTime = _nowMillis();
        lt_running = false;
    }
}

function reset() as Void {
    lt_running = false;
    lt_startTime = 0;
    lt_currentLapStart = 0;
    lt_lastStopTime = 0;
    lt_prevLap = 0;
    lt_fastestLap = 0;
    lt_laps = [];
    lt_lastWasInside = false;
}

function _recordLapAtTime(t as Number) as Void {
    var lapTime = t - lt_currentLapStart;
    lt_prevLap = lapTime;
    if (lt_fastestLap == 0 or lapTime < lt_fastestLap) {
        lt_fastestLap = lapTime;
    }
    // Append lapTime to the laps array using Array.add
    lt_laps.add(lapTime);
    lt_currentLapStart = t;
}

function recordLap() as Void {
    _recordLapAtTime(_nowMillis());
}

// Position adapter: call with plain numbers (lat, lon)
function onPositionUpdate(lat as Number, lon as Number) as Void {
    if (!lt_running) {
        return;
    }
    var p = lt_presets[lt_selectedPreset] as Array;
    // access preset fields with explicit expected types
    var plat = p[1] as Number;
    var plon = p[2] as Number;
    var prad = p[3] as Number;
    var d = _distanceMeters(lat, lon, plat, plon);
    var inside = (d <= prad);
    if (!lt_lastWasInside and inside) {
        recordLap();
    }
    lt_lastWasInside = inside;
}

function getTotalTimeMillis() as Number {
    if (lt_running) {
        return _nowMillis() - lt_startTime;
    } else if (lt_startTime != 0 and lt_lastStopTime != 0) {
        return lt_lastStopTime - lt_startTime;
    }
    return 0;
}

function getCurrentLapMillis() as Number {
    if (lt_currentLapStart == 0) {
        return 0;
    }
    if (lt_running) {
        return _nowMillis() - lt_currentLapStart;
    }
    if (lt_lastStopTime != 0) {
        return lt_lastStopTime - lt_currentLapStart;
    }
    return 0;
}

function getPrevLapMillis() as Number {
    return lt_prevLap;
}

function getFastestLapMillis() as Number {
    return lt_fastestLap;
}

function getLaps() as Array {
    return lt_laps;
}

function getSelectedPresetName() as String {
    var p = lt_presets[lt_selectedPreset] as Array;
    return p[0] as String;
}

function getSelectedPresetIndex() as Number {
    return lt_selectedPreset;
}

function getPresetCount() as Number {
    return lt_presets.size();
}

function selectPreset(idx as Number) as Void {
    if (idx >= 0 and idx < lt_presets.size()) {
        lt_selectedPreset = idx;
    }
}

function formatDuration(ms as Number) as String {
    // Use integer math to avoid float/mod type issues
    var totalSec = Toybox.Math.floor(ms / 1000);
    var tenths = Toybox.Math.floor((ms % 1000) / 100);
    var hours = Toybox.Math.floor(totalSec / 3600);
    var minutes = Toybox.Math.floor((totalSec % 3600) / 60);
    var seconds = totalSec % 60;
    if (hours > 0) {
        return Lang.format("%d:%02d:%02d", [ hours, minutes, seconds ]);
    }
    return Lang.format("%d:%02d.%d", [ minutes, seconds, tenths ]);
}

