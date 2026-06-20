# Architecture: Layered Architecture

## Overview
TomoBar uses a layered architecture adapted for a macOS menu bar application. The app is organized into horizontal layers: Presentation (SwiftUI Views), Application Logic (Timer, Notifications), and Services (Player, DND, Logging), on top of a dependency-free Shared layer (`State`, `Defaults`). Each layer depends only on the layers below it; shared state and user configuration are accessed across layers via `@AppStorage` (UserDefaults) and the `State` module.

This pattern was chosen because TomoBar is a single-developer desktop application of moderate complexity (~30 source files). Layered architecture gives clear separation of concerns without the overhead of strict dependency inversion, ports/adapters, or domain modeling that would be over-engineering at this size.

## Decision Rationale
- **Project type:** macOS menu bar utility app (NSPopover-based, sandboxed)
- **Tech stack:** Swift, SwiftUI, AppKit, SwiftState (state machine)
- **Key factor:** Small codebase with clear functional boundaries and a single deployment target — simple horizontal layers provide sufficient organization. Per the decision matrix (team size 1, low domain complexity, low scale, single deploy), Layered is the correct fit.

## Folder Structure
```
TomoBar/
├── App.swift                    # [Entry] App lifecycle, NSStatusItem, composition root (TBStatusItem)
├── View.swift                   # [Presentation] Main popover view (TBPopoverView)
├── Views/                       # [Presentation] Settings UI
│   ├── SettingsView.swift       #   Settings tab container
│   ├── IntervalsView.swift      #   Work/rest interval settings
│   ├── SoundsView.swift         #   Sound settings
│   ├── ControlsView.swift       #   Right-click action settings
│   └── ViewComponents.swift     #   Reusable UI components
├── Timer.swift                  # [Logic] TBTimer coordinator (ObservableObject)
├── Timer/                       # [Logic] Timer subsystem
│   ├── TimerCore.swift          #   Core tick/countdown logic
│   ├── TimerStateMachine.swift  #   State transitions (SwiftState)
│   ├── TimerActions.swift       #   User action handlers
│   ├── TimerDisplay.swift       #   Menu bar display updates
│   ├── TimerShortcuts.swift     #   Global hotkey handling
│   ├── TimerSettingsBindings.swift # @AppStorage bindings
│   └── TimerUrl.swift           #   URL scheme handler (tomobar://)
├── Notifications/               # [Logic] Notification subsystem
│   ├── System.swift             #   macOS system notifications
│   ├── Custom.swift             #   Custom overlay controller
│   ├── Custom/                  #   Custom notification views
│   │   ├── BaseLayout.swift
│   │   ├── Big.swift
│   │   ├── Small.swift
│   │   └── CustomComponents.swift
│   └── Mask.swift               #   Full-screen mask overlay
├── Notify.swift                 # [Logic] Notification coordinator (TBNotify)
├── State.swift                  # [Shared] State machine events/states, typealiases
├── Defaults.swift               # [Shared] Default setting values (Default.*)
├── Player.swift                 # [Service] Audio playback (TBPlayer)
├── DND.swift                    # [Service] Do Not Disturb toggle (TBDoNotDisturb)
├── Log.swift                    # [Service] Logging system (TBLogger)
└── Utils/                       # [Service] Utilities
    ├── AppNapPrevent.swift       #   App Nap prevention
    └── LocalizationManager.swift #   i18n support (LocalizationManager.shared)
```

## Dependency Rules

Dependencies flow downward through layers:

```
┌─────────────────────────────┐
│   Presentation (View/, Views/) │  SwiftUI views, user interaction
├─────────────────────────────┤
│   Application Logic         │  Timer/, Notifications/, Notify
├─────────────────────────────┤
│   Services                  │  Player, DND, Log, Utils/
├─────────────────────────────┤
│   Shared (State, Defaults)  │  Enums, constants, configuration
└─────────────────────────────┘
```

- ✅ Views → Timer, Notifications (observe state, call actions)
- ✅ Timer → Player, DND, Notify (trigger sounds, focus, notifications)
- ✅ Notify → System, Custom, Mask (dispatch to notification type)
- ✅ Any layer → State, Defaults (shared types and configuration)
- ✅ App.swift → all layers (composition root)
- ❌ Services → Timer or Views (services do not know about higher layers)
- ❌ State/Defaults → any other layer (shared types have zero dependencies)
- ❌ No layer skipping that bypasses the Timer coordinator for subsystem work

## Layer/Module Communication
- **Views ↔ Timer:** `TBTimer` is an `ObservableObject` exposing `@Published` properties (`paused`, `timeLeftString`, `stateMachine`). Views bind to it via `@ObservedObject` (root) and `@EnvironmentObject` (child settings views), and call action methods on it.
- **Timer → Services:** Timer calls services directly — `TBPlayer.play*()`, `TBDoNotDisturb` toggles, `TBNotify.send()`.
- **Settings persistence:** All user preferences flow through `@AppStorage` (UserDefaults) with defaults from `Defaults.swift`. State is not threaded manually between layers.
- **State machine:** Timer transitions are modeled explicitly via `SwiftState` (`TBStateMachine` over `TBStateMachineStates`/`TBStateMachineEvents`) rather than ad-hoc boolean flags.
- **Composition root:** `App.swift` wires `TBStatusItem` → `TBPopoverView` → `TBTimer`.

## Key Principles
1. **Keep layers thin** — Views only display state and forward user actions. Business logic belongs in `Timer/` and `Notifications/`.
2. **State enums are the contract** — The `SwiftState` events/states in `State.swift` and the action enums in `Timer.swift` (e.g. `RightClickAction`) define the shared vocabulary between layers.
3. **Timer is the coordinator** — `TBTimer` orchestrates all subsystems (display, sound, DND, notifications). New features integrate through Timer, not by bypassing it.
4. **Settings via @AppStorage** — All preferences use `@AppStorage` with defaults from `Defaults.swift`. No custom settings stores.
5. **Extend, don't restructure** — New code fits existing layers. Create a new subdirectory only when a subsystem reaches 3+ files (as `Timer/`, `Notifications/`, `Views/` already do).
6. **Localize all user-facing text** — Wrap strings with `NSLocalizedString`; comments stay in English (project convention).

## Code Examples

### Adding a new user action (Logic layer)
```swift
// In Timer/TimerActions.swift — add the action method
extension TBTimer {
    func resetToIdle() {
        stateMachine <-! .startStop // fire a state-machine event via SwiftState's operator
        updateTimeLeft()
        logger.append(event: TBLogEventReset())
    }
}

// In Timer.swift — extend the action enum (String-backed, CaseIterable)
enum RightClickAction: String, CaseIterable {
    case off, startStop, pauseResume, addMinute, addFiveMinutes, skipInterval
    case resetToIdle // New action
}
```

### Adding a new settings view (Presentation layer)
```swift
// In Views/NewSettingsView.swift
struct NewSettingsView: View {
    @EnvironmentObject var timer: TBTimer // child settings views receive TBTimer via the environment

    var body: some View {
        // Read settings via @AppStorage on TBTimer, call timer methods for actions
    }
}

// Register the tab in Views/SettingsView.swift
```

### Adding a new service (Service layer)
```swift
// In a new file at TomoBar/ level (or Utils/ for cross-cutting helpers).
// Services are self-contained with no upward dependencies on Timer or Views.
class TBNewService: ObservableObject {
    func doWork() {
        // Service logic here
    }
}

// Integrate from the Timer coordinator (Timer.swift):
// private let newService = TBNewService()
```

## Anti-Patterns
- ❌ **Views calling services directly** — Views go through `TBTimer`, not directly to `TBPlayer` or `TBDoNotDisturb`.
- ❌ **Circular dependencies** — If A depends on B, B must not depend on A. Use delegation or callbacks.
- ❌ **Fat views** — Don't put timer logic, notification logic, or settings validation inside SwiftUI views.
- ❌ **Bypassing Notify** — Notifications go through `TBNotify`, not by calling `System`/`Custom`/`Mask` directly from Timer.
- ❌ **Singleton abuse** — Only `TBStatusItem.shared` (AppKit requirement) and `LocalizationManager.shared` (global i18n access) are singletons by necessity. Don't introduce more; prefer injection through the Timer coordinator.
- ❌ **Boolean flags instead of the state machine** — Model timer phase changes through `TBStateMachine`, not scattered `Bool`s.
```
