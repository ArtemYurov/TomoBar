import KeyboardShortcuts
import SwiftState
import SwiftUI

enum startWithValues: String, CaseIterable, DropdownDescribable {
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
    @AppStorage("startWith") var startWith = startWithValues.work
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

    private var finishTime: Date!
    private var timerFormatter = DateComponentsFormatter()
    private var pausedTimeRemaining: TimeInterval = 0
    private var startTime: Date!  // When the current interval started
    private var pausedTimeElapsed: TimeInterval = 0  // Elapsed time when paused
    private var adjustTimerWorkItem: DispatchWorkItem?  // For debouncing timer adjustments
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

    private func nextIntervalIsShortRest() -> Bool {
        return !nextIntervalIsLongRest()
    }

    private func nextIntervalIsLongRest() -> Bool {
        return currentPresetInstance.workIntervalsInSet > 1
            && currentWorkInterval >= currentPresetInstance.workIntervalsInSet
    }

    private func isSessionCompleted(for state: TBStateMachineStates) -> Bool {
        switch state {
        case .work:
            return sessionStopAfter == .work
        case .shortRest:
            return sessionStopAfter == .shortRest
        case .longRest:
            return sessionStopAfter == .longRest
        case .idle:
            return false
        }
    }

    init() {
        /*
         * State Machine Transition Table
         *
         * Events:
         *   - startStop: start/stop timer
         *   - confirmedNext: user confirmed transition to next interval
         *   - skipEvent: skip current interval
         *   - intervalCompleted: timer reached 0 (fact)
         *       → auto-transition if shouldAutoTransition() == true
         *       → stay in state if shouldAutoTransition() == false (pause for user choice)
         *   - sessionCompleted: session finished (based on stopAfter setting)
         *
         * From: idle
         *   → work (startStop, if startWith = work)
         *   → shortRest (startStop, if startWith = rest)
         *
         * From: work
         *   → shortRest (intervalCompleted/confirmedNext, if currentWorkInterval < workIntervalsInSet)
         *   → longRest (intervalCompleted/confirmedNext, if currentWorkInterval >= workIntervalsInSet)
         *   → idle (sessionCompleted if sessionStopAfter = work, OR startStop)
         *
         * From: shortRest
         *   → work (intervalCompleted/confirmedNext)
         *   → idle (sessionCompleted if sessionStopAfter = shortRest, OR startStop)
         *
         * From: longRest
         *   → work (intervalCompleted/confirmedNext resets currentWorkInterval)
         *   → idle (sessionCompleted if sessionStopAfter = longRest, OR startStop)
         */

        // startStop transitions
        stateMachine.addRoutes(event: .startStop, transitions: [
            .work => .idle,
            .shortRest => .idle,
            .longRest => .idle
        ])

        stateMachine.addRoutes(event: .startStop, transitions: [.idle => .work]) { _ in
            self.startWith == .work
        }

        stateMachine.addRoutes(event: .startStop, transitions: [.idle => .shortRest]) { _ in
            self.startWith != .work
        }

        // sessionCompleted transitions (all completion paths go to idle)
        stateMachine.addRoutes(event: .sessionCompleted, transitions: [
            .work => .idle,
            .shortRest => .idle,
            .longRest => .idle
        ])

        // intervalCompleted transitions (auto-transition only if shouldAutoTransition)
        stateMachine.addRoutes(event: .intervalCompleted, transitions: [.work => .shortRest]) { [self] _ in
            nextIntervalIsShortRest()
            && notify.shouldAutoTransition
        }

        stateMachine.addRoutes(event: .intervalCompleted, transitions: [.work => .longRest]) { [self] _ in
            nextIntervalIsLongRest()
            && notify.shouldAutoTransition
        }

        stateMachine.addRoutes(event: .intervalCompleted, transitions: [
            .shortRest => .work,
            .longRest => .work
        ]) { [self] _ in
            notify.shouldAutoTransition
        }

        // Pause routes when user choice is required
        stateMachine.addRoutes(event: .intervalCompleted, transitions: [
            .work => .work,
            .shortRest => .shortRest,
            .longRest => .longRest
        ]) { [self] _ in
            !notify.shouldAutoTransition
        }

        // confirmedNext transitions (always transition, no shouldAutoTransition check)
        stateMachine.addRoutes(event: .confirmedNext, transitions: [.work => .shortRest]) { [self] _ in
            nextIntervalIsShortRest()
        }

        stateMachine.addRoutes(event: .confirmedNext, transitions: [.work => .longRest]) { [self] _ in
            nextIntervalIsLongRest()
        }

        stateMachine.addRoutes(event: .confirmedNext, transitions: [
            .shortRest => .work,
            .longRest => .work
        ])

        // skipEvent transitions (skip current interval and go to next)
        stateMachine.addRoutes(event: .skipEvent, transitions: [.work => .shortRest]) { [self] _ in
            nextIntervalIsShortRest()
        }

        stateMachine.addRoutes(event: .skipEvent, transitions: [.work => .longRest]) { [self] _ in
            nextIntervalIsLongRest()
        }

        stateMachine.addRoutes(event: .skipEvent, transitions: [
            .shortRest => .work,
            .longRest => .work
        ])

        // State transition handlers (ordered by state: idle -> work -> shortRest -> longRest)
        stateMachine.addAnyHandler(.any => .idle, handler: onIdleStart)
        stateMachine.addAnyHandler(.idle => .any, handler: onIdleEnd)

        // Work handlers - only for real transitions, not pause routes
        stateMachine.addAnyHandler(.idle => .work, handler: onWorkStart)
        stateMachine.addAnyHandler(.shortRest => .work, handler: onWorkStart)
        stateMachine.addAnyHandler(.longRest => .work, handler: onWorkStart)
        stateMachine.addAnyHandler(.work => .any, handler: onWorkEnd)

        // Rest handlers - only for real transitions, not pause routes
        stateMachine.addAnyHandler(.work => .shortRest, handler: onRestStart)
        stateMachine.addAnyHandler(.shortRest => .work, handler: onRestEnd)
        stateMachine.addAnyHandler(.work => .longRest, handler: onRestStart)
        stateMachine.addAnyHandler(.longRest => .work, handler: onRestEnd)

        // Event handlers
        stateMachine.addHandler(event: .intervalCompleted, handler: onIntervalCompleted)
        stateMachine.addHandler(event: .sessionCompleted, handler: onSessionCompleted)
        stateMachine.addHandler(event: .skipEvent, handler: onSkipEvent)

        stateMachine.addAnyHandler(.any => .any, handler: { ctx in
            logger.append(event: TBLogEventTransition(fromContext: ctx))
        })

        stateMachine.addErrorHandler { ctx in fatalError("state machine context: <\(ctx)>") }

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

        let TEST_MODE = ProcessInfo.processInfo.environment["TEST_MODE"] == "1"
        if TEST_MODE {
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
        }
        else {
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

    private func getNextIntervalDuration() -> TimeInterval {
        // Return the duration of the next interval when timer is idle
        if startWith == .work {
            return TimeInterval(currentPresetInstance.workIntervalLength * 60)
        } else {
            // Determine if it's a long rest or short rest
            if nextIntervalIsLongRest() {
                return TimeInterval(currentPresetInstance.longRestIntervalLength * 60)
            } else {
                return TimeInterval(currentPresetInstance.shortRestIntervalLength * 60)
            }
        }
    }

    private func updateTimeLeft() {
        // Calculate and format time (always needed for popover display)
        let timeLeft: TimeInterval
        if timer == nil {
            // Timer is idle - show the duration of the next interval
            timeLeft = getNextIntervalDuration()
        } else {
            // Timer is running or paused
            timeLeft = paused ? pausedTimeRemaining : finishTime.timeIntervalSince(Date())
        }

        // Format the time
        if timeLeft >= 3600 {
            timerFormatter.allowedUnits = [.hour, .minute, .second]
            timerFormatter.zeroFormattingBehavior = .dropLeading
        } else {
            timerFormatter.allowedUnits = [.minute, .second]
            timerFormatter.zeroFormattingBehavior = .pad
        }

        timeLeftString = timerFormatter.string(from: timeLeft)!
    }

    private func updateStatusBar() {
        // Handle different show timer modes for status bar display
        switch showTimerMode {
        case .disabled:
            // Never show timer in status bar
            setTitle(nil)

        case .running:
            // Show timer only when running and not paused
            if timer == nil || paused {
                setTitle(nil)
            } else {
                setTitle(timeLeftString)
            }

        case .always:
            // Show timer always (including idle and paused states)
            setTitle(timeLeftString)
        }
    }
    
    private func setTitle(_ title: String?) {
        TBStatusItem.shared.setTitle(title: title)
    }


    private func updateMask() {
        guard timer != nil else { return }
        if notify.alertMode == .fullScreen && !paused {
            notify.mask.updateTimeLeft(timeLeftString)
        }
    }

    func updateDisplay() {
        updateTimeLeft()
        updateStatusBar()
        updateMask()
    }

    func addMinutes(_ minutes: Int = 1) {
        guard timer != nil else { return }

        let seconds = TimeInterval(minutes * 60)
        let timeLeft = paused ? pausedTimeRemaining : max(0, finishTime.timeIntervalSince(Date()))
        var newTimeLeft = timeLeft + seconds
        if newTimeLeft > 7200 {
            newTimeLeft = TimeInterval(7200)
        }

        if paused {
            pausedTimeRemaining = newTimeLeft
            pausedTimeElapsed = pausedTimeElapsed - seconds
        }
        else
        {
            startTime = startTime.addingTimeInterval(seconds)
            finishTime = Date().addingTimeInterval(newTimeLeft)
        }
        updateDisplay()
    }

    func adjustTimer(state: TBStateMachineStates) {
        // Only adjust if timer is running
        guard timer != nil else {
            updateDisplay()
            return
        }

        guard state != .idle else {
            updateDisplay()
            return
        }

        let shouldAdjust: Bool

        switch state {
        case .idle:
            return
        case .work:
            shouldAdjust = isWorking
        case .shortRest:
            shouldAdjust = isShortRest
        case .longRest:
            shouldAdjust = isLongRest
        }

        guard shouldAdjust else {
            updateDisplay()
            return
        }

        let newIntervalMinutes = getIntervalMinutes(for: state)

        // Calculate elapsed time from timer start
        let elapsedTime: TimeInterval
        if paused {
            elapsedTime = pausedTimeElapsed
        } else {
            elapsedTime = Date().timeIntervalSince(startTime)

        }

        // Calculate new time left with new interval duration
        let newIntervalDuration = TimeInterval(newIntervalMinutes * 60)
        let newTimeLeft = newIntervalDuration - elapsedTime

        // Only update if newTimeLeft is at least 1 second
        // This prevents timer corruption during rapid onChange events (e.g., typing in TextField)
        if newTimeLeft >= 1.0 {
            if paused {
                pausedTimeRemaining = newTimeLeft
            } else {
                finishTime = Date().addingTimeInterval(newTimeLeft)
            }
        } else if newTimeLeft < 0 {
            // If new interval is shorter than elapsed time, keep minimal time to allow user to finish editing
            if paused {
                pausedTimeRemaining = 1.0
            } else {
                finishTime = Date().addingTimeInterval(1.0)
            }
        }
        // If 0 <= newTimeLeft < 1, don't update finishTime - keep old value

        updateDisplay()
    }

    func adjustTimerDebounced(state: TBStateMachineStates) {
        // Cancel previous debounce task if exists
        adjustTimerWorkItem?.cancel()

        // Create new debounce task with 0.3 second delay
        let workItem = DispatchWorkItem { [self] in
            DispatchQueue.main.async {
                self.adjustTimer(state: state)
            }
        }
        adjustTimerWorkItem = workItem

        // Execute after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
    }

    private func getIntervalMinutes(for state: TBStateMachineStates) -> Double {
        switch state {
        case .idle:
            return 0
        case .work:
            return currentPresetInstance.workIntervalLength
        case .shortRest:
            return currentPresetInstance.shortRestIntervalLength
        case .longRest:
            return currentPresetInstance.longRestIntervalLength
        }
    }

    private func startStateTimer() {
        guard stateMachine.state != .idle else { return }
        let minutes = getIntervalMinutes(for: stateMachine.state)
        startTimer(seconds: Int(minutes * 60))
    }

    private func startTimer(seconds: Int) {
        finishTime = Date().addingTimeInterval(TimeInterval(seconds))
        startTime = Date()  // Save when timer started
        pausedTimeElapsed = 0  // Reset paused elapsed time

        let queue = DispatchQueue(label: "Timer")
        timer = DispatchSource.makeTimerSource(flags: .strict, queue: queue)
        timer!.schedule(deadline: .now(), repeating: .seconds(1), leeway: .never)
        timer!.setEventHandler(handler: onTimerTick)
        timer!.setCancelHandler(handler: onTimerCancel)
        timer!.resume()
    }

    private func stopTimer() {
        guard let timer else { return }
        timer.cancel()
        self.timer = nil
    }

    private func onTimerTick() {
        /* Cannot publish updates from background thread */
        DispatchQueue.main.async { [self] in
            if paused {
                return
            }

            updateDisplay()
            let timeLeft = finishTime.timeIntervalSince(Date())
            if timeLeft <= 0 {
                /*
                 Ticks can be missed during the machine sleep.
                 Stop the timer if it goes beyond an overrun time limit.
                 */
                if timeLeft < overrunTimeLimit {
                    stateMachine <-! .startStop
                } else {
                    // Check if this should be a session completion
                    let isSessionCompleted = isSessionCompleted(for: stateMachine.state)
                    stateMachine <-! (isSessionCompleted ? .sessionCompleted : .intervalCompleted)
                }
            }
        }
    }

    private func onTimerCancel() {
        DispatchQueue.main.async { [self] in
            updateDisplay()
        }
    }

    private func handleUserChoiceAction(_ action: UserChoiceAction) {
        notify.choice.hide()

        switch action {
        case .next:
            paused = false
            stateMachine <-! .confirmedNext

        case .skip:
            paused = false
            stateMachine <-! .confirmedNext
            stateMachine <-! .skipEvent

        case .addMinute:
            addMinutes(1)
            pauseResume()

        case .addFiveMinutes:
            addMinutes(5)
            pauseResume()

        case .stop:
            paused = false
            stateMachine <-! .startStop

        case .restart:
            paused = false
            stateMachine <-! .startStop
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
                self.stateMachine <-! .startStop
            }
        }
    }

    private func onIdleStart(context ctx: TBStateMachine.Context) {
        notify.mask.hide()
        player.deinitPlayers()
        stopTimer()
        setStateIcon()
        currentWorkInterval = 0
        updateDisplay()
    }

    private func onIdleEnd(context _: TBStateMachine.Context) {
        player.initPlayers()
    }

    private func onWorkStart(context _: TBStateMachine.Context) {
        // Reset counter if we've completed a set (reached or exceeded workIntervalsInSet)
        if currentWorkInterval >= currentPresetInstance.workIntervalsInSet {
            currentWorkInterval = 1
        }
        else {
            currentWorkInterval += 1
        }
        setStateIcon()
        player.playWindup()
        player.startTicking()
        startStateTimer()
        if dnd.toggleDoNotDisturb {
            dnd.set(focus: true) { [self] success in
                if !success {
                    self.stateMachine <-! .startStop
                }
            }
        }
    }

    private func onWorkEnd(context _: TBStateMachine.Context) {
        dnd.set(focus: false)
    }

    private func onRestStart(context ctx: TBStateMachine.Context) {
        let isAutoTransition = ctx.event == .intervalCompleted
        if isAutoTransition {
            notify.showRestStarted(isLong: isLongRest)
        }
        setStateIcon()
        startStateTimer()
    }

    private func onRestEnd(context ctx: TBStateMachine.Context) {
        if ctx.event == .skipEvent { return }
        notify.showRestFinished()
    }

    private func pauseForUserChoice() {
        // Pause timer
        paused = true
        pausedTimeRemaining = 0
        updateDisplay()  // Show 00:00
    }

    private func onIntervalCompleted(context ctx: TBStateMachine.Context) {
        // Stop ticking and play completion sound for work interval
        if isWorking {
            player.stopTicking()
            player.playDing()
        }

        // Check if not auto-transition
        if ctx.fromState == ctx.toState {
            pauseForUserChoice()

            // Show notification for user to choose next action
            notify.showUserChoice(
                for: stateMachine.state,
                nextIsLongRest: nextIntervalIsLongRest()
            )
        }
    }

    private func onSessionCompleted(context ctx: TBStateMachine.Context) {
        notify.showSessionCompleted()
    }

    private func onSkipEvent(context ctx: TBStateMachine.Context) {
        if isSessionCompleted(for: ctx.fromState) {
            stateMachine <-! .sessionCompleted
        }
    }

    private func setStateIcon() {
        let iconName: NSImage.Name
        switch stateMachine.state {
        case .idle:
            iconName = .idle
        case .work:
            iconName = .work
        case .shortRest:
            iconName = .shortRest
        case .longRest:
            iconName = .longRest
        }
        TBStatusItem.shared.setIcon(name: iconName)
    }

    private func setPauseIcon() {
        TBStatusItem.shared.setIcon(name: .pause)
    }
}
