### Garmin Lap Timer

## About

This is a lap timer app for Garmin watches (specifically the Forerunner 255, as that's what I have). It's for racing cars (or I guess anything else) around tracks with pre-determined start/finish lines.

## Functionality

1. Store a list of start/finish line coordinates for tracks, selectable by user when starting a race session. (Could also be selected for user based on current proximity, i.e. if you're within 500m of track X s/f line, track X is selected for you).

2. Once a session is started, automatically track laps as the user crosses the s/f line.

3. Data fields for curr lap time, prev lap time, best lap time, list of completed laps, curr speed, avg speed, max speed (all mph).

# Garmin API Permissions needed
Positioning, Sensor, Activity Recording, Persisted Content and Locations

# Button mapping

UP - cycle through data screens, move up one. each with different information (i.e. one for curr and prev laps, one for best lap, etc.)

DOWN - cycle through data screens, move down one.

BACK - return to watch home screen, exit app (but continue running in background if activity started)

START/STOP - start activity if not currently running, otherwise pause and enter screen to either save and end activity or resume it

LIGHT - toggle backlight
