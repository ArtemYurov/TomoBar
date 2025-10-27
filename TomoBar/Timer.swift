import KeyboardShortcuts
import SwiftState
import SwiftUI

enum StartWithValues: String, CaseIterable, DropdownDescribable {
    case work, rest
}

enum SessionStopAfter: String, CaseIterable, DropdownDescribable {
    case disabled, work, shortRest, longRest
}

enum ShowTimerMode: String, CaseIterable, DropdownDescribable {
    case disabled, running, always
}

enum TimerFontMode: String, CaseIterable, DropdownDescribable {
    case system, ptMono, sfMono
}

struct TimerPreset: Codable {
    var workIntervalLength: Double = 25
    var shortRestIntervalLength: Double = 5
    var longRestIntervalLength: Double = 15
    var workIntervalsInSet = 4
}

class TBTimer: ObservableObject {
    @AppStorage("startTimerOnLaunch") var startTimerOnLaunch = false
    @AppStorage("startWith") var startWith = StartWithValues.work
    @AppStorage("sessionStopAfter") var sessionStopAfter = SessionStopAfter.disabled
    @AppStorage("showTimerMode") var showTimerMode = ShowTimerMode.running
    @AppStorage("timerFontMode") var timerFontMode = TimerFontMode.system
    @AppStorage("grayBackgroundOpacity") var grayBackgroundOpacity = 0
    @AppStorage("currentPreset") var currentPreset = 0
    @AppStorage("timerPresets") private var presetsData = Data()
    var presets: [TimerPreset] {
        get { (try? JSONDecoder().decode([TimerPreset].self, from: presetsData)) ?? Array(repeating: TimerPreset(), count: 4) }
        set { presetsData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }
    // This preference is "hidden"
    @AppStorage("overrunTimeLimit") var overrunTimeLimit = -60.0

    public let player = TBPlayer()
    public lazy var notify = TBNotify(
        skipHandler: skip,
        userChoiceHandler: handleUserChoiceAction
    )
    public var dnd = TBDoNotDisturb()
    public var currentWorkInterval: Int = 0

    var notifyAlertMode: AlertMode {
        get { notify.alertMode }
        set {
            notify.alertMode = newValue
            objectWillChange.send()
        }
    }
    public var currentPresetInstance: TimerPreset {
        get {
            return presets[currentPreset]
        }
        set(newValue) {
            presets[currentPreset] = newValue
        }
    }

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
        KeyboardShortcuts.onKeyUp(for: .skipTimer, action: skip)
        KeyboardShortcuts.onKeyUp(for: .addMinuteTimer) { [weak self] in
            self?.addMinutes(1)
        }
        KeyboardShortcuts.onKeyUp(for: .addFiveMinutesTimer) { [weak self] in
            self?.addMinutes(5)
        }

        dnd.onToggleChanged = { [self] in
            let shouldFocus = dnd.toggleDoNotDisturb && stateMachine.state == .work && !paused
            dnd.set(focus: shouldFocus)
        }

        let aem: NSAppleEventManager = NSAppleEventManager.shared()
        aem.setEventHandler(self,
                            andSelector: #selector(handleGetURLEvent(_:withReplyEvent:)),
                            forEventClass: AEEventClass(kInternetEventClass),
                            andEventID: AEEventID(kAEGetURL))

        let testMode = ProcessInfo.processInfo.environment["TEST_MODE"] == "1"
        if testMode {
            var testPresets = presets
            testPresets[0] = TimerPreset(
                workIntervalLength: 0.1,
                shortRestIntervalLength: 0.1,
                longRestIntervalLength: 0.2,
                workIntervalsInSet: 2
            )
            presets = testPresets
        }
    }

    @objc func handleGetURLEvent(_ event: NSAppleEventDescriptor,
                                 withReplyEvent: NSAppleEventDescriptor) {
        guard let urlString = event.forKeyword(AEKeyword(keyDirectObject))?.stringValue else {
            print("url handling error: cannot get url")
            return
        }
        let url = URL(string: urlString)
        guard url != nil,
              let scheme = url!.scheme,
              let host = url!.host else {
            print("url handling error: cannot parse url")
            return
        }
        guard scheme.caseInsensitiveCompare("tomobar") == .orderedSame else {
            print("url handling error: unknown scheme \(scheme)")
            return
        }
        switch host.lowercased() {
        case "startstop":
            startStop()
        case "pauseresume":
            pauseResume()
        case "skip":
            skip()
        case "addminute":
            addMinutes(1)
        case "addfiveminutes":
            addMinutes(5)
        default:
            print("url handling error: unknown command \(host)")
            return
        }
    }

    func startStop() {
        notify.choice.hide()
        paused = false
        stateMachine <-! .startStop
    }

    func startOnLaunch() {
        if !startTimerOnLaunch {
            return
        }

        startStop()
    }

    func skip() {
        guard timer != nil else { return }

        paused = false
        stateMachine <-! .skipEvent
    }

    func pauseResume() {
        guard timer != nil else { return }

        paused = !paused

        if dnd.toggleDoNotDisturb, isWorking {
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
