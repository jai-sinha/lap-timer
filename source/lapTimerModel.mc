import Toybox.System;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Position;

// Simple global model for lap timer state and logic.

var lt_running = false;
var lt_startTime = 0;
var lt_currentLapStart = 0;
var lt_lastStopTime = 0;
var lt_prevLap = 0;
var lt_fastestLap = 0;
var lt_laps as Array = [];
var lt_lastWasInside = false;
var lt_currentSpeed = 0;
var lt_avgSpeed = 0;
var lt_maxSpeed = 0;
var lt_speedSum = 0;
var lt_speedCount = 0;
// Simple status log (most recent messages shown as a toast)
var lt_statuses as Array = [];

// Each preset: [ name, lat, lon, radius ]
// presets: Array of [String, Number, Number, Number]
var lt_presets as Array = [
    [ "Track Start", 37.4219999, -122.0840575, 25 ],
    [ "Park Gate",    40.712776,  -74.005974,   30 ],
    [ "Home",         51.507351,  -0.127758,    25 ]
];

var lt_selectedPreset as Number = 0;
var lt_screenIndex as Number = 0;

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
        lt_currentSpeed = 0;
        lt_avgSpeed = 0;
        lt_maxSpeed = 0;
        lt_speedSum = 0;
        lt_speedCount = 0;
        // Enable continuous GPS updates when timer starts. Use Position if available.
        if (Position != null) {
            // Request continuous updates and deliver to positionListener
            try {
                Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, new Lang.Method(self, :positionListener));
            } catch (ex) {
                // ignore if device doesn't support or permission not granted
            }
        }
    addStatus("Started");
    }
}

function stop() as Void {
    if (lt_running) {
        lt_lastStopTime = _nowMillis();
        lt_running = false;
        // Disable GPS updates when timer stops
        if (Position != null) {
            try {
                // Request no location events to stop updates. Some platforms accept LOCATION_NONE.
                if (Position has :LOCATION_NONE) {
                    Position.enableLocationEvents(Position.LOCATION_NONE, null);
                } else {
                    // Fallback: request one-shot with null listener to stop continuous updates
                    Position.enableLocationEvents(Position.LOCATION_ONE_SHOT, new Lang.Method(self, :positionListener));
                }
            } catch (ex) {
                // ignore
            }
        }
    addStatus("Stopped");
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
    lt_currentSpeed = 0;
    lt_avgSpeed = 0;
    lt_maxSpeed = 0;
    lt_speedSum = 0;
    lt_speedCount = 0;
    // Ensure GPS updates are disabled on reset
    if (Position != null) {
        try {
            if (Position has :LOCATION_NONE) {
                Position.enableLocationEvents(Position.LOCATION_NONE, null);
            } else {
                Position.enableLocationEvents(Position.LOCATION_ONE_SHOT, new Lang.Method(self, :positionListener));
            }
        } catch (ex) {
            // ignore
        }
    }
    addStatus("Reset");
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
    addStatus("Lap: " + formatDuration(lapTime));
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

// Position listener invoked by Toybox.Position. Receives a Position.Info object.
function positionListener(info) as Void {
    if (info == null) {
        return;
    }
    // info.position is a Position.Location object
    if (info has :position and info.position != null) {
        // Convert to degrees array: [lat, lon]
        var degs = info.position.toDegrees();
        if (degs != null and degs.size() >= 2) {
            var lat = degs[0] as Number;
            var lon = degs[1] as Number;
            // Forward numeric lat/lon to existing adapter
            onPositionUpdate(lat, lon);
        }
    }
    // Update speed if available
    if (info has :speed and info.speed != null) {
        lt_currentSpeed = info.speed * 2.23694; // m/s to mph
        lt_speedSum += lt_currentSpeed;
        lt_speedCount += 1;
        lt_avgSpeed = lt_speedSum / lt_speedCount;
        if (lt_currentSpeed > lt_maxSpeed) {
            lt_maxSpeed = lt_currentSpeed;
        }
    }
}

// Status log API
function addStatus(msg as String) as Void {
    var ts = _nowMillis();
    // keep a short ring of recent messages
    lt_statuses.add({:time => ts, :msg => msg});
    // limit to last 5 messages
    while (lt_statuses.size() > 5) {
        lt_statuses.remove(0);
    }
}

function getStatusMessages() as Array {
    return lt_statuses;
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

function getCurrentSpeed() as Number {
    return lt_currentSpeed;
}

function getAvgSpeed() as Number {
    return lt_avgSpeed;
}

function getMaxSpeed() as Number {
    return lt_maxSpeed;
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

function getScreenIndex() as Number {
    return lt_screenIndex;
}

function setScreenIndex(idx as Number) as Void {
    lt_screenIndex = idx;
}

function getScreenCount() as Number {
    return 3; // times, speeds, laps
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

