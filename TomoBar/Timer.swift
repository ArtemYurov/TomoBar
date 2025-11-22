import KeyboardShortcuts
import SwiftState
import SwiftUI

enum StartWithValues: String, CaseIterable, DropdownDescribable, Codable {
    case work, rest
}

enum SessionStopAfter: String, CaseIterable, DropdownDescribable, Codable {
    case disabled, work, shortRest, longRest
}

enum ShowTimerMode: String, CaseIterable, DropdownDescribable {
    case disabled, running, always
}

enum TimerFontMode: String, CaseIterable, DropdownDescribable {
    case fontSystem, ptMono, sfMono
}

enum RightClickAction: String, CaseIterable {
    case startStop, pauseResume, addMinute, addFiveMinutes, skipInterval
}

struct TimerPreset: Codable {
    var workIntervalLength: Int
    var shortRestIntervalLength: Int
    var longRestIntervalLength: Int
    var workIntervalsInSet: Int
    var startWith: StartWithValues
    var sessionStopAfter: SessionStopAfter
    var focusOnWork: Bool
}

class TBTimer: ObservableObject {
    @AppStorage("appLanguage") var appLanguage = Default.appLanguage
    @AppStorage("startTimerOnLaunch") var startTimerOnLaunch = Default.startTimerOnLaunch
    @AppStorage("showTimerMode") var showTimerMode = Default.showTimerMode
    @AppStorage("timerFontMode") var timerFontMode = Default.timerFontMode
    @AppStorage("grayBackgroundOpacity") var grayBackgroundOpacity = Default.grayBackgroundOpacity
    @AppStorage("longRightClickAction") var longRightClickAction = Default.longRightClickAction
    @AppStorage("rightClickAction") var rightClickAction = Default.rightClickAction
    @AppStorage("currentPreset") var currentPreset = Default.currentPreset

    #if DEBUG
    @AppStorage("useSecondsInsteadOfMinutes") var useSecondsInsteadOfMinutes = false
    var secondsMultiplier: Int { useSecondsInsteadOfMinutes ? 1 : 60 }
    #else
    var secondsMultiplier: Int { 60 }
    #endif

    @AppStorage("timerPresets") private var presetsData = Data()
    var presets: [TimerPreset] {
        get { (try? JSONDecoder().decode([TimerPreset].self, from: presetsData)) ?? Default.presets }
        set { presetsData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }
    let overrunTimeLimit: Double = -60

    public let player = TBPlayer()
    public lazy var notify = TBNotify(
        skipHandler: skipInterval,
        userChoiceHandler: handleUserChoiceAction
    )
    public var dnd = TBDoNotDisturb()
    public var currentWorkInterval: Int = 0

    var finishTime: Date!
    var timerFormatter = DateComponentsFormatter()
    var pausedTimeRemaining: TimeInterval = 0
    var startTime: Date!  // When the current interval started
    var pausedTimeElapsed: TimeInterval = 0  // Elapsed time when paused
    var adjustTimerWorkItem: DispatchWorkItem?  // For debouncing timer adjustments
    let appNapPrevent = AppNapPrevent()
    @Published var paused: Bool = false
    @Published var timeLeftString: String = ""
    @Published var timer: DispatchSourceTimer?
    @Published var stateMachine = TBStateMachine(state: .idle)

    var isIdle: Bool {
        stateMachine.state == .idle
    }

    var isWorking: Bool {
        stateMachine.state == .work
    }

    var isResting: Bool {
        stateMachine.state == .shortRest || stateMachine.state == .longRest
    }

    var isShortRest: Bool {
        stateMachine.state == .shortRest
    }

    var isLongRest: Bool {
        stateMachine.state == .longRest
    }

    init() {
        setupStateMachine()
        timerFormatter.unitsStyle = .positional

        KeyboardShortcuts.onKeyUp(for: .startStopTimer, action: startStop)
        KeyboardShortcuts.onKeyUp(for: .pauseResumeTimer, action: pauseResume)
        KeyboardShortcuts.onKeyUp(for: .addMinuteTimer) { [weak self] in
            self?.addMinutes(1)
        }
        KeyboardShortcuts.onKeyUp(for: .addFiveMinutesTimer) { [weak self] in
            self?.addMinutes(5)
        }
        KeyboardShortcuts.onKeyUp(for: .skipTimer, action: skipInterval)

        let aem: NSAppleEventManager = NSAppleEventManager.shared()
        aem.setEventHandler(self,
                            andSelector: #selector(handleURLEvent(_:withReplyEvent:)),
                            forEventClass: AEEventClass(kInternetEventClass),
                            andEventID: AEEventID(kAEGetURL))
    }

    func startStop() {
        notify.custom.hide()
        paused = false
        stateMachine <-! .startStop
    }

    func startOnLaunch() {
        if !startTimerOnLaunch {
            return
        }

        startStop()
    }

    func skipInterval() {
        guard timer != nil else { return }

        paused = false
        stateMachine <-! .skipEvent
    }

    func pauseResume() {
        guard timer != nil else { return }

        paused = !paused

        if currentPresetInstance.focusOnWork, isWorking {
            dnd.set(focus: !paused)
        }

        if paused {
            if isWorking {
                player.stopTicking()
            }
            setPauseIcon()
            pausedTimeRemaining = finishTime.timeIntervalSince(Date())
            pausedTimeElapsed = Date().timeIntervalSince(startTime)
            finishTime = Date.distantFuture
        } else {
            if isWorking {
                player.startTicking(isPaused: true)
            }
            setStateIcon()
            // Adjust startTime to account for pause duration
            startTime = Date().addingTimeInterval(-pausedTimeElapsed)
            finishTime = Date().addingTimeInterval(pausedTimeRemaining)
        }

        updateDisplay()
    }
}
