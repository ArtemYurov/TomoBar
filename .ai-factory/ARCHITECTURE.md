# Architecture: Layered Architecture

## Overview
TomoBar uses a layered architecture adapted for a macOS menu bar application. The app is organized into horizontal layers: Presentation (Views), Application Logic (Timer, Notifications), and Services (Player, DND, Logging). Each layer depends only on the layers below it, with shared state and configuration accessible across layers via `@AppStorage` and the `State` module.

This pattern was chosen because TomoBar is a single-developer desktop application with moderate complexity. Layered architecture provides clear separation of concerns without the overhead of strict dependency inversion or domain modeling that would be excessive for this project size.

## Decision Rationale
- **Project type:** macOS menu bar utility app
- **Tech stack:** Swift, SwiftUI, AppKit
- **Key factor:** Small codebase (~30 files) with clear functional boundaries; simple layers provide sufficient organization without over-engineering

## Folder Structure
```
TomoBar/
├── App.swift                    # [Entry] App lifecycle, menu bar status item
├── View.swift                   # [Presentation] Main popover view
├── Views/                       # [Presentation] Settings UI
│   ├── SettingsView.swift       #   Settings tab container
│   ├── IntervalsView.swift      #   Work/rest interval settings
│   ├── SoundsView.swift         #   Sound settings
│   ├── ControlsView.swift       #   Right-click action settings
│   └── ViewComponents.swift     #   Reusable UI components
├── Timer.swift                  # [Logic] Timer coordinator
├── Timer/                       # [Logic] Timer subsystem
│   ├── TimerCore.swift          #   Core tick/countdown logic
│   ├── TimerStateMachine.swift  #   State transitions
│   ├── TimerActions.swift       #   User action handlers
│   ├── TimerDisplay.swift       #   Menu bar display updates
│   ├── TimerShortcuts.swift     #   Global hotkey handling
│   ├── TimerSettingsBindings.swift # @AppStorage bindings
│   └── TimerUrl.swift           #   URL scheme handler
├── Notifications/               # [Logic] Notification subsystem
│   ├── System.swift             #   macOS system notifications
│   ├── Custom.swift             #   Custom overlay controller
│   ├── Custom/                  #   Custom notification views
│   │   ├── BaseLayout.swift
│   │   ├── Big.swift
│   │   ├── Small.swift
│   │   └── CustomComponents.swift
│   └── Mask.swift               #   Full-screen mask overlay
├── Notify.swift                 # [Logic] Notification coordinator
├── State.swift                  # [Shared] Enums, state types
├── Defaults.swift               # [Shared] Default setting values
├── Player.swift                 # [Service] Audio playback
├── DND.swift                    # [Service] Do Not Disturb toggle
├── Log.swift                    # [Service] Logging system
└── Utils/                       # [Service] Utilities
    ├── AppNapPrevent.swift       #   App Nap prevention
    └── LocalizationManager.swift #   i18n support
```

## Dependency Rules

Dependencies flow downward through layers:

```
┌─────────────────────────────┐
│   Presentation (Views/)     │  SwiftUI views, user interaction
├─────────────────────────────┤
│   Application Logic         │  Timer/, Notifications/, Notify
├─────────────────────────────┤
│   Services                  │  Player, DND, Log, Utils/
├─────────────────────────────┤
│   Shared (State, Defaults)  │  Enums, constants, configuration
└─────────────────────────────┘
```

- ✅ Views → Timer, Notifications (present state, call actions)
- ✅ Timer → Player, DND, Notify (trigger sounds, focus, notifications)
- ✅ Notify → System, Custom, Mask (dispatch to notification type)
- ✅ Any layer → State, Defaults (shared types and configuration)
- ✅ App.swift → all layers (composition root)
- ❌ Services → Timer or Views (services don't know about higher layers)
- ❌ State/Defaults → any other layer (shared types have zero dependencies)

## Layer/Module Communication
- **Views ↔ Timer:** Views hold a reference to `TBTimer` (ObservableObject), bind to `@Published` properties, and call action methods
- **Timer → Services:** Timer calls `Player.play()`, `DND.setImmediate()`, `Notify.send()` directly
- **Settings persistence:** All settings flow through `@AppStorage` (UserDefaults), not passed between layers explicitly
- **App.swift** acts as composition root: creates `TBStatusItem` → `TBPopoverView` → `TBTimer`

## Key Principles
1. **Keep layers thin** — Views should only display state and forward user actions. Business logic belongs in Timer/ and Notifications/
2. **State enums are the contract** — `TimerState`, notification types, and action enums in `State.swift` define the shared vocabulary between layers
3. **Timer is the coordinator** — `TBTimer` orchestrates all subsystems (display, sound, DND, notifications). New features should integrate through Timer, not bypass it
4. **Settings via @AppStorage** — All user preferences use `@AppStorage` with defaults from `Defaults.swift`. No custom settings stores
5. **Extend, don't restructure** — New features should fit into existing layers. Only create new subdirectories when a subsystem has 3+ files

## Code Examples

### Adding a new user action (Logic layer)
```swift
// In Timer/TimerActions.swift — add the action method
extension TBTimer {
    func resetToIdle() {
        stateMachine.transition(to: .idle)
        updateDisplay()
        logger.append(event: TBLogEventReset())
    }
}

// In State.swift — add to the action enum if needed
enum RightClickAction: Int {
    case off = 0
    case startStop
    case pauseResume
    case addMinute
    case addFiveMinutes
    case skipInterval
    case resetToIdle  // New action
}
```

### Adding a new settings view (Presentation layer)
```swift
// In Views/NewSettingsView.swift
struct NewSettingsView: View {
    @ObservedObject var timer: TBTimer

    var body: some View {
        // Read settings via @AppStorage
        // Call timer methods for actions
    }
}

// Register in Views/SettingsView.swift tab list
```

### Adding a new service (Service layer)
```swift
// In Utils/NewService.swift or a new file at TomoBar/ level
// Services should be self-contained with no upward dependencies
class TBNewService {
    func doWork() {
        // Service logic here
    }
}

// Integrate in Timer.swift:
// let newService = TBNewService()
```

## Anti-Patterns
- ❌ **Views calling services directly** — Views should go through Timer, not call Player or DND directly
- ❌ **Circular dependencies** — If A depends on B, B must not depend on A. Use delegation or callbacks if needed
- ❌ **Fat views** — Don't put timer logic, notification logic, or settings validation in SwiftUI views
- ❌ **Singleton abuse** — Only `TBStatusItem.shared` is a singleton by necessity (AppKit requirement). Don't add more
- ❌ **Bypassing Notify** — All notifications should go through `Notify.swift` coordinator, not call System/Custom/Mask directly from Timer
