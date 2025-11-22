# Changelog

## [v4.1.0] - 2025-11-22

### Added
- Right-click actions on menu bar icon - single click, double-click, and long press (fully configurable in settings)
- +2 minutes button in big notification for quick time extension

### Fixed
- DND (Do Not Disturb) now stays enabled during work pause
- Localization improvements
- UI improvements in notifications

## [v4.0.1] - 2025-11-15

### Fixed
- Fixed click handling after rest finished in block actions mode - clicks are now properly processed when mask shows "click once to start work"
- Fixed mask not appearing when using double-click skip action - implemented seamless transition without animation flicker
- Improved mask update logic with consolidated codebase for better maintainability

## [v4.0.0] - 2025-11-11

### Added
- macOS Tahoe 26 compatibility (contributed by tan9).
- Updated UI design for macOS Tahoe 26 with improved visual consistency.
- Custom notification system with two styles: Small and Big notifications.
  - Small notification: Compact notification in the top-right corner with 2 action buttons (Next/Skip for intervals, Restart/Close for completed sessions). Features horizontal slide-in/slide-out animation.
  - Big notification: Centered notification below the menu bar with enhanced controls. For active intervals: 5 buttons (Add 1 Minute, Add 5 Minutes, Stop, Next, Skip). For completed sessions: 2 buttons (Restart Session, Close). Features vertical slide-in/slide-out animation.
- Background opacity setting (0-10 scale) for both Small and Big notification styles, allowing users to customize notification transparency.
- Notification preview feature in settings to test notification appearance before applying.
- Improved window level management for better notification visibility across different macOS spaces and full-screen apps.
- Timer visibility options — choose when to display the timer: Off, Only when active, or Always visible.
- Timer font options — select between System, PT Mono, or SF Mono fonts.
- Gray background option for better visual contrast in the menu bar.
- Live interval editing — change Pomodoro or break durations even while the timer is running.
- Shortcuts settings page for customizing keyboard shortcuts.
- Updated button icons with refreshed visuals.
- "+5 Minutes" button and URL scheme for quickly extending the current session.
- Language selection in settings — choose your preferred interface language directly from the app without changing system settings.
- Session start/stop settings now configurable per preset.
- Moved Do Not Disturb (DND) setting from global to per-preset configuration with DND control in Intervals tab.
- Improved mask notification handling with enhanced user interaction controls.

### Changed
- Forked and refactored from TomatoBar 3.5.0-fork (by https://github.com/AuroraWright/TomatoBar).
- Fully rebranded as TomoBar, including updated name, icons, and assets.
- Updated KeyboardShortcuts dependency to version 2.4.0.
- Updated Sparkle framework for auto-updates.
