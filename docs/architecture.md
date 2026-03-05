[Back to README](../README.md)

# Architecture

TomoBar is a macOS menu bar Pomodoro timer built with SwiftUI and AppKit. The app lives in the system menu bar as an `NSStatusItem` with an `NSPopover` for the main UI.

## High-Level Overview

```
┌─────────────────────────────────────────────────────┐
│                    App.swift                        │
│              TBApp + TBStatusItem                   │
│         (menu bar icon, popover, clicks)            │
└──────────────────────┬──────────────────────────────┘
                       │ creates
┌──────────────────────▼──────────────────────────────┐
│                  View.swift                         │
│               TBPopoverView                         │
│    (start/stop button, tabs, settings panels)       │
└──────────────────────┬──────────────────────────────┘
                       │ owns
┌──────────────────────▼──────────────────────────────┐
│                  Timer.swift                        │
│              TBTimer (coordinator)                  │
│                                                     │
│  ┌─────────────┐ ┌──────────┐ ┌──────────────────┐ │
│  │ StateMachine│ │ Display  │ │    Actions       │ │
│  │ (SwiftState)│ │ (icon,   │ │ (start, pause,   │ │
│  │             │ │  title)  │ │  skip, add time) │ │
│  └─────────────┘ └──────────┘ └──────────────────┘ │
│  ┌─────────────┐ ┌──────────┐ ┌──────────────────┐ │
│  │  Shortcuts  │ │ URL      │ │ Settings         │ │
│  │ (hotkeys)   │ │ (scheme) │ │ (@AppStorage)    │ │
│  └─────────────┘ └──────────┘ └──────────────────┘ │
└────────┬───────────────┬────────────────┬───────────┘
         │               │                │
    ┌────▼────┐   ┌──────▼──────┐   ┌─────▼─────┐
    │ Player  │   │   Notify    │   │    DND    │
    │ (sound) │   │ (alerts)    │   │  (focus)  │
    └─────────┘   └──────┬──────┘   └───────────┘
                         │
              ┌──────────┼──────────┐
              │          │          │
        ┌─────▼───┐ ┌───▼────┐ ┌──▼───┐
        │ System  │ │ Custom │ │ Mask │
        │(UNUser) │ │(window)│ │(full)│
        └─────────┘ └────────┘ └──────┘
```

## State Machine

The timer is driven by a finite state machine (via [SwiftState](https://github.com/ReactKit/SwiftState)) with 4 states and 5 events:

```
         startStop          intervalCompleted / confirmedNext
  ┌────► idle ─────────► work ──────────────────► shortRest ─┐
  │       ▲                │                         │       │
  │       │                │ intervalCompleted /     │       │
  │       │                │ confirmedNext           │       │
  │       │                ▼                         │       │
  │       │            longRest ◄────────────────────┘       │
  │       │                │    (when workIntervalsInSet      │
  │       │                │     reached)                     │
  │       └────────────────┘                                  │
  │         startStop / sessionCompleted                      │
  │                                                           │
  └───────────────────────────────────────────────────────────┘
                  intervalCompleted / confirmedNext
```

**States:** `idle` → `work` → `shortRest` → `work` → ... → `longRest` → `work` (cycle)

**Events:**
| Event | Trigger |
|-------|---------|
| `startStop` | User clicks start/stop |
| `intervalCompleted` | Timer countdown reaches zero |
| `confirmedNext` | User confirms transition to next interval |
| `skipEvent` | User skips current interval |
| `sessionCompleted` | Session ends (based on `stopAfter` setting) |

When `intervalCompleted` fires, the app either auto-transitions to the next state or pauses for user choice — depending on the notification mode (`shouldAutoTransition`).

## Directory Structure

```
TomoBar/
├── App.swift                 # Entry point: TBApp (@main), TBStatusItem (menu bar)
├── View.swift                # TBPopoverView — main popover UI
├── Timer.swift               # TBTimer — central coordinator (ObservableObject)
├── Timer/                    # Timer subsystem (extensions of TBTimer)
│   ├── TimerCore.swift       # DispatchSourceTimer management, tick logic
│   ├── TimerStateMachine.swift # State transitions and handlers
│   ├── TimerActions.swift    # User actions: startStop, pauseResume, skip, addMinutes
│   ├── TimerDisplay.swift    # Updates menu bar icon and title text
│   ├── TimerShortcuts.swift  # Global keyboard shortcut registration
│   ├── TimerSettingsBindings.swift # Computed properties for current preset
│   └── TimerUrl.swift        # tomobar:// URL scheme handler
├── Notify.swift              # TBNotify — notification coordinator
├── Notifications/            # Notification implementations
│   ├── System.swift          # macOS system notifications (UNUserNotificationCenter)
│   ├── Custom.swift          # Custom floating window notifications
│   ├── Custom/               # Custom notification view variants
│   │   ├── BaseLayout.swift  # Shared layout for custom notifications
│   │   ├── Big.swift         # Large notification window
│   │   ├── Small.swift       # Compact notification window
│   │   └── CustomComponents.swift # Reusable notification UI elements
│   └── Mask.swift            # Full-screen overlay mask
├── Views/                    # Settings tab views
│   ├── SettingsView.swift    # General settings (language, appearance, launch)
│   ├── IntervalsView.swift   # Work/rest interval configuration + presets
│   ├── SoundsView.swift      # Sound volume sliders
│   ├── ControlsView.swift    # Right-click action configuration
│   └── ViewComponents.swift  # Shared UI components and modifiers
├── State.swift               # Core enums: TBStateMachineStates, TBStateMachineEvents
├── Defaults.swift            # Default values for all @AppStorage settings
├── Player.swift              # TBPlayer — AVAudioPlayer wrapper for sounds
├── DND.swift                 # TBDoNotDisturb — Focus mode toggle via Shortcuts.app
├── Log.swift                 # TBLog — JSON event logging
└── Utils/
    ├── AppNapPrevent.swift   # Prevents App Nap during active timer
    └── LocalizationManager.swift # Runtime language switching
```

## Key Components

### TBStatusItem (App.swift)
The app delegate that manages the menu bar presence. Creates an `NSStatusItem`, handles left-click (toggle popover) and right-click (configurable actions: start/stop, pause, skip, add time). Supports single click, double click, and long press.

### TBTimer (Timer.swift + Timer/)
The central coordinator. An `ObservableObject` that owns the state machine, player, notifier, and DND controller. Split across multiple files via extensions:

- **TimerCore** — creates and manages the `DispatchSourceTimer` that fires every 0.5 seconds
- **TimerStateMachine** — defines all state transitions and their side-effect handlers
- **TimerActions** — public methods called by the UI (`startStop()`, `pauseResume()`, etc.)
- **TimerDisplay** — updates the menu bar icon and countdown text

### TBNotify (Notify.swift)
Routes notifications to the appropriate implementation based on user settings:

| `alertMode` | `notifyStyle` | Implementation |
|-------------|---------------|----------------|
| `disabled` | — | No notifications |
| `notify` | `notifySystem` | macOS system notifications |
| `notify` | `small` / `big` | Custom floating window |
| `fullScreen` | — | Full-screen mask overlay |

### TBPlayer (Player.swift)
Manages three audio players: windup (work start), ding (work end), ticking (continuous during work). Sounds load from the app bundle by default but can be overridden with files in `~/Documents/TomoBar/`.

### TBDoNotDisturb (DND.swift)
Toggles macOS Focus mode by running a Shortcuts.app shortcut (`macos-focus-mode`) via ScriptingBridge.

## Settings & Persistence

All settings use `@AppStorage` (UserDefaults). Default values are centralized in `Defaults.swift`. Timer presets are stored as JSON-encoded `[TimerPreset]` in a single `@AppStorage` key.

## Conditional Compilation

The app uses `#if SPARKLE` for auto-update features (Sparkle framework). The App Store build excludes Sparkle; the direct distribution build includes it. Debug builds (`#if DEBUG`) add a seconds-instead-of-minutes toggle for testing.

## See Also

- [README](../README.md) — Project overview and installation
- [CHANGELOG](../CHANGELOG.md) — Version history
