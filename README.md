# Garmin Lap Timer

## Intended Functionality

- Automatic lap time recording based on uploaded start/finish line coordinates
- Data sent to/from companion iOS app upon ending a session
- Speed, heart rate, and positioning data collection in addition to lap times

### Current Status: Beta testing basic functions on watch

# Lap Timer Companion

This is the iOS companion to the Garmin app. It is written in Swift and uses the Connect IQ iOS SDK to communicate with the watch over Bluetooth.

## Goals

- Save and display sessions recorded by the watch app
- Send track coordinates to the watch app

## Notes

- This project borrows from [this example's](https://github.com/dougw/Garmin-ExampleApp-Swift) Swift implementation of the Connect IQ iOS SDK. (Thanks, Doug!)
