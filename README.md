<img src="https://github.com/ArtemYurov/TomoBar/raw/main/TomoBar/Assets.xcassets/AppIcon.appiconset/icon_128x128%402x.png?raw=true" width="128" height="128" align="left"/>
<img
src="https://github.com/ArtemYurov/TomoBar/raw/main/screenshot.png?raw=true"
alt="Screenshot"
width="40%"
align="right"
/>

### TomoBar

*Pomodoro timer for macOS menu bar*
<br clear="left"/>

### Get TomoBar

#### Mac App Store

<p align="left">
<a href="https://apps.apple.com/us/app/tomobar/id6755073574" rel="nofollow">
<img src="https://upload.wikimedia.org/wikipedia/commons/3/3c/Download_on_the_App_Store_Badge.svg"
alt="Download on the Mac App Store"
style="max-width: 100%; width: 180px;"/>
</a>
</p>

#### Github Releases

<p align="left">
<a href="https://github.com/ArtemYurov/TomoBar/releases/latest">
<img src="https://img.shields.io/github/v/release/ArtemYurov/TomoBar?label=Download&style=for-the-badge&color=d9534f"
alt="Download Latest Release"
style="max-width: 100%; width: 180px;"/>
</a>
</p>

#### Homebrew

```bash
brew install --cask ArtemYurov/tomobar/tomobar
```

### Overview
Have you ever heard of Pomodoro? It’s a great technique to help you keep track of time and stay on task during your studies or work. Read more about it on <a href="https://en.wikipedia.org/wiki/Pomodoro_Technique">Wikipedia</a>.

TomoBar is world's neatest Pomodoro timer for the macOS menu bar. All the essential features are here - configurable
work and rest intervals, optional sounds, discreet actionable notifications, global hotkey.

TomoBar is fully sandboxed with no entitlements (except for the Apple Events entitlement, used to run the Do Not Disturb toggle shortcut).

### Requirements
Minimum macOS version requirement to Monterey 12

### Integration with other tools
#### Event log
TomoBar logs state transitions in JSON format to `~/Library/Containers/org.yurov.tomobar/Data/Library/Caches/TomoBar.log`. Use this data to analyze your productivity and enrich other data sources.
#### Controlling the timer
TomoBar can be controlled using `tomobar://` URLs. 
- use `open tomobar://startStop` to start or stop the timer from the command line 
- use `open tomobar://pauseResume` to pause or resume 
- use `open tomobar://skip` to skip 
- use `open tomobar://addMinute` to add a minute
- use `open tomobar://addFiveMinutes` to add a 5 minutes

### Older versions
Touch bar integration and older macOS versions (earlier than Big Sur) are supported by TomatoBar versions prior to 3.0

### Licenses
 - Based of TomatoBar fork https://github.com/AuroraWright/TomatoBar
 - Originally TomatoBar https://github.com/ivoronin/TomatoBar/
 - Timer sounds are licensed from buddhabeats
 - "macos-focus-mode.shortcut" is taken from the <a href="https://github.com/arodik/macos-focus-mode">macos-focus-mode</a> project under the MIT license.
 
