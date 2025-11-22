import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let startStopTimer = Self("startStopTimer")
    static let pauseResumeTimer = Self("pauseResumeTimer")
    static let skipTimer = Self("skipTimer")
    static let addMinuteTimer = Self("addMinuteTimer")
    static let addFiveMinutesTimer = Self("addFiveMinutesTimer")
}

extension TBTimer {
    /// Register keyboard shortcuts handlers
    func setupKeyboardShortcuts() {
        KeyboardShortcuts.onKeyUp(for: .startStopTimer, action: startStop)
        KeyboardShortcuts.onKeyUp(for: .pauseResumeTimer, action: pauseResume)
        KeyboardShortcuts.onKeyUp(for: .addMinuteTimer) { [weak self] in
            self?.addMinutes(1)
        }
        KeyboardShortcuts.onKeyUp(for: .addFiveMinutesTimer) { [weak self] in
            self?.addMinutes(5)
        }
        KeyboardShortcuts.onKeyUp(for: .skipTimer, action: skipInterval)
    }
}
