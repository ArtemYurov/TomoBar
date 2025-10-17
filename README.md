<p align="center">
<img src="https://github.com/ArtemYurov/TomoBar/raw/main/TomoBar/Assets.xcassets/AppIcon.appiconset/icon_128x128%402x.png?raw=true" width="128" height="128"/>
<p>
 
<h1 align="center">TomoBar (fork of TomatoBar)</h1>

<img
  src="https://github.com/ArtemYurov/TomoBar/raw/main/screenshot.png?raw=true"
  alt="Screenshot"
  width="50%"
  align="right"
/>

## Overview
Have you ever heard of Pomodoro? It’s a great technique to help you keep track of time and stay on task during your studies or work. Read more about it on <a href="https://en.wikipedia.org/wiki/Pomodoro_Technique">Wikipedia</a>.

TomoBar is world's neatest Pomodoro timer for the macOS menu bar. All the essential features are here - configurable
work and rest intervals, optional sounds, discreet actionable notifications, global hotkey.

TomoBar is fully sandboxed with no entitlements (except for the Apple Events entitlement, used to run the Do Not Disturb toggle shortcut).

## Requirements
Minimum macOS version requirement to Monterey

## Integration with other tools
### Event log
TomoBar logs state transitions in JSON format to `~/Library/Containers/com.github.ArtemYurov.TomoBar/Data/Library/Caches/TomoBar.log`. Use this data to analyze your productivity and enrich other data sources.
### Controlling the timer
TomoBar can be controlled using `tomobar://` URLs. 
- use `open tomatobar://startStop` to start or stop the timer from the command line 
- use `open tomobar://pauseResume` to pause or resume 
- use `open tomobar://skip` to skip 
- use `open tomobar://addMinute` to add a minute
- use `open tomobar://addFiveMinutes` to add a 5 minutes

## Older versions
Touch bar integration and older macOS versions (earlier than Big Sur) are supported by TomatoBar versions prior to 3.0

## Licenses
 - Based of TomatoBar fork https://github.com/AuroraWright/TomatoBar
 - Originally TomatoBar https://github.com/AuroraWright/TomatoBar
 - Timer sounds are licensed from buddhabeats
 - "macos-focus-mode.shortcut" is taken from the <a href="https://github.com/arodik/macos-focus-mode">macos-focus-mode</a> project under the MIT license.
 
