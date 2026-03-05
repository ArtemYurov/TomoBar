# AGENTS.md

> Project map for AI agents. Keep this file up-to-date as the project evolves.

## Project Overview
TomoBar is a macOS menu bar Pomodoro timer built with SwiftUI. Available on Mac App Store, GitHub Releases, and Homebrew.

## Tech Stack
- **Language:** Swift
- **UI Framework:** SwiftUI
- **Platform:** macOS (menu bar app)
- **Build System:** Xcode
- **Linting:** SwiftLint
- **Auto-Update:** Sparkle (non-App Store builds)

## Project Structure
```
TomoBar/
├── TomoBar/                    # Main app source code
│   ├── App.swift               # Entry point, TBStatusItem (menu bar management)
│   ├── View.swift              # Main popover view (TBPopoverView)
│   ├── Timer.swift             # TBTimer - main timer class
│   ├── Timer/                  # Timer subsystem
│   │   ├── TimerCore.swift     # Core timer logic, tick handling
│   │   ├── TimerStateMachine.swift # State transitions (idle/work/rest)
│   │   ├── TimerActions.swift  # User actions (start/stop, pause, skip)
│   │   ├── TimerDisplay.swift  # Menu bar display updates
│   │   ├── TimerShortcuts.swift # Global hotkey handling
│   │   ├── TimerSettingsBindings.swift # @AppStorage bindings
│   │   └── TimerUrl.swift      # URL scheme handler (tomobar://)
│   ├── Notifications/          # Notification subsystem
│   │   ├── System.swift        # macOS system notifications
│   │   ├── Custom.swift        # Custom overlay notification controller
│   │   ├── Custom/             # Custom notification views
│   │   │   ├── BaseLayout.swift
│   │   │   ├── Big.swift
│   │   │   ├── Small.swift
│   │   │   └── CustomComponents.swift
│   │   └── Mask.swift          # Full-screen mask overlay
│   ├── Views/                  # Settings UI views
│   │   ├── SettingsView.swift  # Settings tabs container
│   │   ├── IntervalsView.swift # Work/rest interval settings
│   │   ├── SoundsView.swift    # Sound settings
│   │   ├── ControlsView.swift  # Right-click action settings
│   │   └── ViewComponents.swift # Reusable UI components
│   ├── Utils/                  # Utilities
│   │   ├── AppNapPrevent.swift # Prevents App Nap during timer
│   │   └── LocalizationManager.swift # i18n support
│   ├── State.swift             # App state enums (TimerState, etc.)
│   ├── Defaults.swift          # Default settings values
│   ├── Notify.swift            # Notification coordinator
│   ├── Player.swift            # Sound playback (AVAudioPlayer)
│   ├── DND.swift               # Do Not Disturb toggle
│   ├── Log.swift               # Logging system
│   └── Info.plist              # App configuration
├── Icons/                      # App icon source files
├── TomoBar.xcodeproj/          # Xcode project
├── .github/workflows/          # CI/CD
│   ├── release.yml             # GitHub Releases workflow
│   └── release-appstore.yml    # App Store release workflow
├── Makefile                    # Release management commands
├── .swiftlint.yml              # SwiftLint configuration
└── CHANGELOG.md                # Version history
```

## Key Entry Points
| File | Purpose |
|------|---------|
| `TomoBar/App.swift` | App entry point (`@main TBApp`), menu bar setup |
| `TomoBar/Timer.swift` | Central timer class coordinating all subsystems |
| `TomoBar/State.swift` | Core enums: `TimerState`, notification types, actions |
| `TomoBar/Defaults.swift` | All default settings values |
| `TomoBar/Info.plist` | Bundle config, URL scheme, Sparkle settings |

## Documentation
| Document | Path | Description |
|----------|------|-------------|
| README | `README.md` | Project landing page |
| Architecture | `docs/architecture.md` | App structure, state machine, components |
| Changelog | `CHANGELOG.md` | Version history |

## AI Context Files
| File | Purpose |
|------|---------|
| `AGENTS.md` | This file — project structure map |
| `.ai-factory/DESCRIPTION.md` | Project specification and tech stack |
| `.ai-factory/ARCHITECTURE.md` | Architecture decisions and guidelines |
| `CLAUDE.md` | Agent instructions and preferences |
| `.claude/CLAUDE.local.md` | Detailed build commands and project guidelines |
