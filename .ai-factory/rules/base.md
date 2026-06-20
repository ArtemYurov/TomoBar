# TomoBar — Base Project Rules

> Auto-detected conventions from codebase analysis. Edit as needed.

## Naming Conventions

- Files: `PascalCase` matching the primary type (`App.swift`, `TimerCore.swift`, `View.swift`)
- Types (classes/structs/enums/protocols): `PascalCase` with the `TB` project prefix (`TBApp`, `TBTimer`, `TBStatusItem`, `TBLogger`, `TBStateMachine`, `TBLogEvent`)
- Variables and properties: `camelCase` (`logFileName`, `fromState`, `logHandle`)
- Functions/methods: `camelCase`
- Enum cases: `camelCase` (`idle`, `work`, `shortRest`, `longRest`, `startStop`)
- Constants: `camelCase` (`let`), module-private constants marked `private let`

## Module Structure

Feature-oriented directories under `TomoBar/`:

- `Timer/` — timer subsystem (core loop, state machine, actions, display, shortcuts, settings bindings, URL scheme)
- `Notifications/` — notification subsystem (System, Custom overlay, full-screen Mask) with `Custom/` for view variants
- `Views/` — settings UI (SwiftUI views and reusable components)
- `Utils/` — cross-cutting helpers (App Nap prevention, localization)
- Root-level single-responsibility files: `State.swift`, `Defaults.swift`, `Player.swift`, `DND.swift`, `Log.swift`, `Notify.swift`

Keep new code aligned to these boundaries; do not collapse subsystems into root-level files.

## Error Handling

- Use Swift-native patterns: optionals, `guard`/`if let` unwrapping, and `do/try/catch` for throwing APIs
- Timer flow is modeled explicitly via a `SwiftState` state machine (`TBStateMachine`) — prefer state transitions over ad-hoc boolean flags
- File and system I/O (e.g. `FileHandle`) must be treated as failable and guarded

## Logging

- Use the custom `TBLogger` (global `logger`) — do not use bare `print`/`NSLog` for app events
- Events conform to `TBLogEvent` (`Encodable`, `type` + `timestamp`) and are JSON-encoded to `TomoBar.log`
- Add a new `TBLogEvent*` type for each distinct loggable event rather than logging free-form strings

## Conventions

- All code comments MUST be written in English only (see CLAUDE.local.md)
- All user-facing strings MUST be wrapped with `NSLocalizedString` for i18n
- Settings persistence goes through `@AppStorage` (UserDefaults); centralize defaults in `Defaults.swift`
- Sparkle auto-update code is guarded by `#if SPARKLE` conditional compilation — keep App Store and direct-distribution paths separated
- Lint with SwiftLint (`.swiftlint.yml`) before committing
