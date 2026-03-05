# Project: TomoBar

## Overview
TomoBar is a macOS menu bar Pomodoro timer application built with SwiftUI. It's a fork of TomatoBar with enhanced features for productivity tracking. Available on Mac App Store, GitHub Releases, and Homebrew.

## Core Features
- Configurable work and rest intervals (Pomodoro technique)
- Menu bar timer display with multiple font options
- System and custom notifications (including full-screen mask overlay)
- Sound effects for interval transitions
- Do Not Disturb integration via Apple Events
- Global hotkey support
- Launch at Login
- Right-click actions (start/stop, pause/resume, skip, add time)
- Auto-update via Sparkle framework (non-App Store builds)
- URL scheme support (`tomobar://`)

## Tech Stack
- **Language:** Swift
- **UI Framework:** SwiftUI
- **Platform:** macOS (menu bar app, NSPopover-based)
- **Build System:** Xcode (xcodebuild)
- **Linting:** SwiftLint
- **Auto-Update:** Sparkle (conditional compilation with `#if SPARKLE`)
- **Dependencies:** LaunchAtLogin
- **CI/CD:** GitHub Actions (release workflows for GitHub and App Store)
- **Distribution:** Mac App Store, GitHub Releases (DMG), Homebrew Cask

## Architecture Notes
- App entry point: `TBApp` (@main SwiftUI App)
- Menu bar management via `TBStatusItem` (NSApplicationDelegate + NSStatusItem)
- Timer logic separated into Timer/ directory (state machine, actions, display, shortcuts)
- Notification system with multiple types: System, Custom overlay, Full-screen Mask
- Settings stored via @AppStorage (UserDefaults)
- Logging via custom `TBLog` system
- Conditional Sparkle compilation for App Store vs direct distribution builds

## Architecture
See `.ai-factory/ARCHITECTURE.md` for detailed architecture guidelines.
Pattern: Layered Architecture

## Non-Functional Requirements
- Fully sandboxed with minimal entitlements
- Universal binary (arm64 + x86_64)
- Localization support via NSLocalizedString
