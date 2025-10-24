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

enum AlertMode: String, CaseIterable, DropdownDescribable {
    case disabled, notify, fullScreen
}

enum NotifyStyle: String, CaseIterable, DropdownDescribable {
    case system, small, big
}

enum MaskMode: String, CaseIterable, DropdownDescribable {
    case normal, blockActions
}

struct TimerPreset: Codable {
    var workIntervalLength = 25
    var shortRestIntervalLength = 5
    var longRestIntervalLength = 15
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
    @AppStorage("alertMode") var alertMode = AlertMode.notify
    @AppStorage("notifyStyle") var notifyStyle = NotifyStyle.system
    @AppStorage("maskMode") var maskMode = MaskMode.normal
    @AppStorage("toggleDoNotDisturb") var toggleDoNotDisturb = false {
        didSet {
            let state = toggleDoNotDisturb && stateMachine.state == .work && !paused
            DispatchQueue.main.async(group: notificationGroup) { 
                _ = DoNotDisturbHelper.shared.set(state: state)
            }
        }
    }
    // This preference is "hidden"
    @AppStorage("overrunTimeLimit") var overrunTimeLimit = -60.0

    public let player = TBPlayer()
    public var currentWorkInterval: Int = 0
    public var currentPresetInstance: TimerPreset {
        get {
            return presets[currentPreset]
        }
        set(newValue) {
            presets[currentPreset] = newValue
        }
    }
    private var notificationGroup = DispatchGroup()
    private var finishTime: Date!
    private var timerFormatter = DateComponentsFormatter()
    private var pausedTimeRemaining: TimeInterval = 0
    private var pausedPrevImage: NSImage?
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

    private func wasCompletion(for state: TBStateMachineStates) -> Bool {
        switch state {
        case .work:
            return sessionStopAfter == .work
        case .shortRest:
            return sessionStopAfter == .shortRest
        case .longRest:
            return sessionStopAfter == .shortRest || sessionStopAfter == .longRest
        case .idle:
            return false
        }
    }

    init() {
        /*
         * State Machine Transition Table
         *
         * Events:
         *   - timerFired: timer completed (auto or user clicked next)
         *   - waitChoice: pause and show notification, wait for user
         *   - skipEvent: skip current interval
         *
         * From: idle
         *   → work (startStop, if startWith = work)
         *   → shortRest (startStop, if startWith = rest)
         *
         * From: work
         *   → shortRest (timerFired, if currentWorkInterval < workIntervalsInSet)
         *   → longRest (timerFired, if currentWorkInterval >= workIntervalsInSet)
         *   → idle (timerFired if sessionStopAfter = work, OR startStop)
         *
         * From: shortRest
         *   → work (timerFired)
         *   → idle (timerFired if sessionStopAfter = rest, OR startStop)
         *
         * From: longRest
         *   → work (timerFired, resets currentWorkInterval)
         *   → idle (timerFired if sessionStopAfter = longRest, OR startStop)
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

        // timerFired transitions from work (non-completion paths)
        stateMachine.addRoutes(event: .timerFired, transitions: [.work => .shortRest]) { [self] _ in
            currentWorkInterval < currentPresetInstance.workIntervalsInSet
        }

        stateMachine.addRoutes(event: .timerFired, transitions: [.work => .longRest]) { [self] _ in
            currentWorkInterval >= currentPresetInstance.workIntervalsInSet
        }

        // timerFired transitions from rest (always back to work for non-completion)
        stateMachine.addRoutes(event: .timerFired, transitions: [
            .shortRest => .work,
            .longRest => .work
        ])

        stateMachine.addAnyHandler(.idle => .any, handler: onIdleEnd)
        stateMachine.addAnyHandler(.shortRest => .work, handler: onRestEnd)
        stateMachine.addAnyHandler(.longRest => .work, handler: onRestEnd)
        stateMachine.addAnyHandler(.any => .work, handler: onWorkStart)
        stateMachine.addAnyHandler(.work => .any, handler: onWorkEnd)
        stateMachine.addAnyHandler(.any => .shortRest, handler: onShortRestStart)
        stateMachine.addAnyHandler(.any => .longRest, handler: onLongRestStart)
        stateMachine.addAnyHandler(.any => .idle, handler: onIdleStart)
        stateMachine.addHandler(event: .waitChoice, handler: onWaitChoice)
        stateMachine.addHandler(event: .sessionCompleted, handler: onSessionCompleted)

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

        SystemNotifyHelper.shared.setDispatchGroup(notificationGroup)
        SystemNotifyHelper.shared.setSkipHandler(skip)
        MaskHelper.shared.setSkipHandler(skip)

        let aem: NSAppleEventManager = NSAppleEventManager.shared()
        aem.setEventHandler(self,
                            andSelector: #selector(handleGetURLEvent(_:withReplyEvent:)),
                            forEventClass: AEEventClass(kInternetEventClass),
                            andEventID: AEEventID(kAEGetURL))
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
        if timer == nil {
            return
        }

        paused = false
        stateMachine <-! .skipEvent
    }
    
    func pauseResume() {
        if timer == nil {
            return
        }

        paused = !paused

        if toggleDoNotDisturb, isWorking {
            DispatchQueue.main.async(group: notificationGroup) { [self] in
                _ = DoNotDisturbHelper.shared.set(state: !paused)
            }
        }

        if paused {
            if isWorking {
                player.stopTicking()
            }
            pausedPrevImage = TBStatusItem.shared.statusBarItem?.button?.image
            TBStatusItem.shared.setIcon(name: .pause)
            pausedTimeRemaining = finishTime.timeIntervalSince(Date())
            pausedTimeElapsed = Date().timeIntervalSince(startTime)
            finishTime = Date.distantFuture
        }
        else {
            if isWorking {
                player.startTicking(isPaused: true)
            }
            if pausedPrevImage != nil {
                TBStatusItem.shared.statusBarItem?.button?.image = pausedPrevImage
            }
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
            if currentWorkInterval >= currentPresetInstance.workIntervalsInSet {
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
            TBStatusItem.shared.setTitle(title: nil)

        case .running:
            // Show timer only when running and not paused
            if timer == nil || paused {
                TBStatusItem.shared.setTitle(title: nil)
            } else {
                TBStatusItem.shared.setTitle(title: timeLeftString)
            }

        case .always:
            // Show timer always (including idle and paused states)
            TBStatusItem.shared.setTitle(title: timeLeftString)
        }
    }

    private func updateMask() {
        if alertMode == .fullScreen && timer != nil && !paused {
            MaskHelper.shared.updateTimeLeft(timeLeftString)
        }
    }

    func updateDisplay() {
        updateTimeLeft()
        updateStatusBar()
        updateMask()
    }

    func addMinutes(_ minutes: Int = 1) {
        if timer == nil {
            return
        }

        let seconds = TimeInterval(minutes * 60)
        let timeLeft = paused ? pausedTimeRemaining : finishTime.timeIntervalSince(Date())
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

    enum IntervalType {
        case work
        case shortRest
        case longRest
    }

    func adjustTimer(intervalType: IntervalType) {
        // Only adjust if timer is running
        guard timer != nil else {
            updateDisplay()
            return
        }

        // Determine current interval duration and if we should adjust
        let newIntervalMinutes: Int
        let shouldAdjust: Bool

        switch intervalType {
        case .work:
            shouldAdjust = isWorking
            newIntervalMinutes = currentPresetInstance.workIntervalLength
        case .shortRest:
            shouldAdjust = isShortRest
            newIntervalMinutes = currentPresetInstance.shortRestIntervalLength
        case .longRest:
            shouldAdjust = isLongRest
            newIntervalMinutes = currentPresetInstance.longRestIntervalLength
        }

        guard shouldAdjust else {
            updateDisplay()
            return
        }

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

    func adjustTimerDebounced(intervalType: IntervalType) {
        // Cancel previous debounce task if exists
        adjustTimerWorkItem?.cancel()

        // Create new debounce task with 0.3 second delay
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.adjustTimer(intervalType: intervalType)
            }
        }
        adjustTimerWorkItem = workItem

        // Execute after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
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
        timer!.cancel()
        timer = nil
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
                    let isCompletion = wasCompletion(for: stateMachine.state)
                    stateMachine <-! (isCompletion ? .sessionCompleted : .timerFired)
                }
            }
        }
    }

    private func onTimerCancel() {
        DispatchQueue.main.async { [self] in
            updateDisplay()
        }
    }

    private func onWorkStart(context _: TBStateMachine.Context) {
        if currentWorkInterval >= currentPresetInstance.workIntervalsInSet {
            currentWorkInterval = 1
        }
        else {
            currentWorkInterval += 1
        }
        TBStatusItem.shared.setIcon(name: .work)
        player.playWindup()
        player.startTicking()
        startTimer(seconds: currentPresetInstance.workIntervalLength * 60)
        if toggleDoNotDisturb {
            DispatchQueue.main.async(group: notificationGroup) { [self] in
                let res = DoNotDisturbHelper.shared.set(state: true)
                if !res {
                    stateMachine <-! .startStop
                }
            }
        }
    }

    private func onWorkEnd(context _: TBStateMachine.Context) {
        player.stopTicking()
        player.playDing()
        DispatchQueue.main.async(group: notificationGroup) {
            _ = DoNotDisturbHelper.shared.set(state: false)
        }
    }

    private func onShortRestStart(context ctx: TBStateMachine.Context) {
        onRestStart(context: ctx, isLong: false, length: currentPresetInstance.shortRestIntervalLength, imgName: .shortRest)
    }

    private func onLongRestStart(context ctx: TBStateMachine.Context) {
        onRestStart(context: ctx, isLong: true, length: currentPresetInstance.longRestIntervalLength, imgName: .longRest)
    }

    private func onRestStart(context ctx: TBStateMachine.Context, isLong: Bool, length: Int, imgName: NSImage.Name) {
        if alertMode == .fullScreen {
            MaskHelper.shared.show(isLong: isLong)
        } else if ctx.event == .timerFired {
            if alertMode == .notify && notifyStyle == .system {
                SystemNotifyHelper.shared.restStarted(isLong: isLong)
            }
        }
        TBStatusItem.shared.setIcon(name: imgName)
        startTimer(seconds: length * 60)
    }

    private func onRestEnd(context ctx: TBStateMachine.Context) {
        MaskHelper.shared.hide()
        if ctx.event == .skipEvent {
            return
        }
        if alertMode == .notify && notifyStyle == .system {
            SystemNotifyHelper.shared.restFinished()
        }
    }

    private func onIdleEnd(context _: TBStateMachine.Context) {
        player.initPlayers()
    }

    private func onIdleStart(context ctx: TBStateMachine.Context) {
        MaskHelper.shared.hide()
        player.deinitPlayers()
        stopTimer()
        TBStatusItem.shared.setIcon(name: .idle)
        currentWorkInterval = 0
        updateDisplay()
    }

    private func onWaitChoice(context ctx: TBStateMachine.Context) {
        // Stop ticking sound if in work state
        if stateMachine.state == .work {
            player.stopTicking()
        }

        // Play completion sound
        player.playDing()

        // Pause timer
        paused = true
        pausedTimeRemaining = 0
        updateDisplay()  // Show 00:00

        // Show notification for user to choose next action
        // showActionChoiceNotification(...)
    }

    private func onSessionCompleted(context ctx: TBStateMachine.Context) {
        // Show system notification for system and fullScreen alert modes
        if (alertMode == .notify && notifyStyle == .system) || alertMode == .fullScreen {
            SystemNotifyHelper.shared.sessionComplete()
        }
    }
}
