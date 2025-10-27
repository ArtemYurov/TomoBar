# Changelog

## [v4.1.0] - 2025-10-28

### Added
- Custom notification system with two styles: Small and Big notifications.
  - Small notification: Compact notification in the top-right corner with 2 action buttons (Next/Skip for intervals, Restart/Close for completed sessions). Features horizontal slide-in/slide-out animation.
  - Big notification: Centered notification below the menu bar with enhanced controls. For active intervals: 5 buttons (Add 1 Minute, Add 5 Minutes, Stop, Next, Skip). For completed sessions: 2 buttons (Restart Session, Close). Features vertical slide-in/slide-out animation.
- Background opacity setting (0-10 scale) for both Small and Big notification styles, allowing users to customize notification transparency.
- Notification preview feature in settings to test notification appearance before applying.
- Improved window level management for better notification visibility across different macOS spaces and full-screen apps.
- Full localization support for all notification messages and button labels.
- macOS Tahoe 26 compatibility (contributed by tan9).
- Session start/stop settings now configurable per preset.

### Changed
- Updated KeyboardShortcuts dependency to version 2.4.0.
- Updated Sparkle framework for auto-updates.

### Refactored
- Applied SwiftLint recommendations across the entire codebase for better code quality.
- Simplified notification system architecture.
- Enhanced state machine with improved event handling and state transitions.

## [v4.0.0] - 2025-10-17

### 🚀 Added
- Timer visibility options — choose when to display the timer: Off, Only when active, or Always visible.
- Timer font options — select between System, PT Mono, or SF Mono fonts.
- Gray background option for better visual contrast in the menu bar.
- Live interval editing — change Pomodoro or break durations even while the timer is running.
- Shortcuts settings page for customizing keyboard shortcuts.
- Updated button icons with refreshed visuals.
- "+5 Minutes" button and URL scheme for quickly extending the current session.

### 🔧 Changed
- Forked from TomatoBar 3.5.0-fork (by https://github.com/AuroraWright/TomatoBar).
- Fully rebranded as TomoBar, including updated name, icons, and assets.
