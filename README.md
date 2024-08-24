<p align="center">
<img src="https://raw.githubusercontent.com/ivoronin/TomatoBar/main/TomatoBar/Assets.xcassets/AppIcon.appiconset/icon_128x128%402x.png" width="128" height="128"/>
<p>
 
<h1 align="center">TomatoBar fork</h1>
<p align="center">
<img src="https://img.shields.io/github/actions/workflow/status/ivoronin/TomatoBar/main.yml?branch=main"/> <img src="https://img.shields.io/github/downloads/ivoronin/TomatoBar/total"/> <img src="https://img.shields.io/github/v/release/ivoronin/TomatoBar?display_name=tag"/> <img src="https://img.shields.io/homebrew/cask/v/tomatobar"/>
</p>

<img
  src="https://github.com/ivoronin/TomatoBar/raw/main/screenshot.png?raw=true"
  alt="Screenshot"
  width="50%"
  align="right"
/>

## Overview
Have you ever heard of Pomodoro? It’s a great technique to help you keep track of time and stay on task during your studies or work. Read more about it on <a href="https://en.wikipedia.org/wiki/Pomodoro_Technique">Wikipedia</a>.

TomatoBar is world's neatest Pomodoro timer for the macOS menu bar. All the essential features are here - configurable
work and rest intervals, optional sounds, discreet actionable notifications, global hotkey.

TomatoBar is fully sandboxed with no entitlements (except for the Apple Events entitlement, used to run the Do Not Disturb toggle shortcut).

## Fork notes
This fork makes a couple additions/modifications:

- Adds an option to toggle Do Not Disturb automatically using a shortcut. The first time you start the timer you'll be prompted to add the shortcut, it will work fine afterwards (also PRed to https://github.com/ivoronin/TomatoBar/pull/82)
- Adds a pause button and keyboard shortcut (based on https://github.com/ivoronin/TomatoBar/pull/52)
- Makes numbers in the settings editable (based on https://github.com/ivoronin/TomatoBar/pull/63)
- Adds an option for a full screen mask (taken rom https://github.com/ivoronin/TomatoBar/pull/65)
- Increased the minimum macOS version requirement to Monterey

## Integration with other tools
### Event log
TomatoBar logs state transitions in JSON format to `~/Library/Containers/com.github.ivoronin.TomatoBar/Data/Library/Caches/TomatoBar.log`. Use this data to analyze your productivity and enrich other data sources.
### Starting and stopping the timer
TomatoBar can be controlled using `tomatobar://` URLs. To start or stop the timer from the command line, use `open tomatobar://startStop`. To pause use `open tomatobar://pauseResume`.

## Older versions
Touch bar integration and older macOS versions (earlier than Big Sur) are supported by TomatoBar versions prior to 3.0

## Licenses
 - Timer sounds are licensed from buddhabeats
 - "macos-focus-mode.shortcut" is taken from the <a href="https://github.com/arodik/macos-focus-mode">macos-focus-mode</a> project under the MIT license.