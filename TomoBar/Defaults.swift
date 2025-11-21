import Foundation

enum Default {
    // Timer display
    static let showTimerMode = ShowTimerMode.always
    static let timerFontMode = TimerFontMode.fontSystem
    static let grayBackgroundOpacity = 6

    // App behavior
    static let appLanguage = "system"
    static let startTimerOnLaunch = false
    static let currentPreset = 0
    static let rightClickAction = RightClickAction.pause
    static let longRightClickAction = RightClickAction.play

    // Alerts
    static let alertMode = AlertMode.notify
    static let notifyStyle = NotifyStyle.big
    static let customBackgroundOpacity = 7
    static let maskBlockActions = false
    static let maskAutoResumeWork = false

    // Sounds
    static let windupVolume = 1.0
    static let dingVolume = 1.0
    static let tickingVolume = 1.0

    // Timer presets
    static let presets: [TimerPreset] = [
        TimerPreset(workIntervalLength: 25, shortRestIntervalLength: 5, longRestIntervalLength: 15,
                    workIntervalsInSet: 4, startWith: .work, sessionStopAfter: .disabled, focusOnWork: false),
        TimerPreset(workIntervalLength: 52, shortRestIntervalLength: 17, longRestIntervalLength: 17,
                    workIntervalsInSet: 1, startWith: .work, sessionStopAfter: .disabled, focusOnWork: false),
        TimerPreset(workIntervalLength: 20, shortRestIntervalLength: 5, longRestIntervalLength: 15,
                    workIntervalsInSet: 4, startWith: .work, sessionStopAfter: .disabled, focusOnWork: false),
        TimerPreset(workIntervalLength: 30, shortRestIntervalLength: 5, longRestIntervalLength: 20,
                    workIntervalsInSet: 4, startWith: .work, sessionStopAfter: .disabled, focusOnWork: false)
    ]
}
