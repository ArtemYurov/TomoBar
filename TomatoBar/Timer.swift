import KeyboardShortcuts
import SwiftState
import SwiftUI

enum startWithValues: String, CaseIterable, DropdownDescribable {
    case work, rest
}

enum stopAfterValues: String, CaseIterable, DropdownDescribable {
    case disabled, work, rest, longRest
}

class TBTimer: ObservableObject {
    @AppStorage("startTimerOnLaunch") var startTimerOnLaunch = false
    @AppStorage("startWith") var startWith = startWithValues.work
    @AppStorage("stopAfter") var stopAfter = stopAfterValues.disabled
    @AppStorage("showTimerInMenuBar") var showTimerInMenuBar = true
    @AppStorage("workIntervalLength") var workIntervalLength = 25
    @AppStorage("shortRestIntervalLength") var shortRestIntervalLength = 5
    @AppStorage("longRestIntervalLength") var longRestIntervalLength = 15
    @AppStorage("workIntervalsInSet") var workIntervalsInSet = 4
    @AppStorage("showFullScreenMask") var showFullScreenMask = false
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
    private var notificationGroup = DispatchGroup()
    private var notificationCenter = TBNotificationCenter()
    private var finishTime: Date!
    private var timerFormatter = DateComponentsFormatter()
    private var pausedTimeRemaining: TimeInterval = 0
    private var pausedPrevImage: NSImage?
    @Published var paused: Bool = false
    @Published var timeLeftString: String = ""
    @Published var timer: DispatchSourceTimer?
    @Published var stateMachine = TBStateMachine(state: .idle)

    init() {
        /*
         * State diagram
         *
         *                 start/stop
         *       +--------------+-------------+
         *       |              |             |
         *       |  start/stop  |  timerFired |
         *       V    |         |    |        |
         * +--------+ |  +--------+  | +--------+
         * | idle   |--->| work   |--->| rest   |
         * +--------+    +--------+    +--------+
         *   A                  A        |    |
         *   |                  |        |    |
         *   |                  +--------+    |
         *   |  timerFired (!stopAfter)  |
         *   |             skipRest           |
         *   |                                |
         *   +--------------------------------+
         *      timerFired (stopAfter)
         *
         */
        stateMachine.addRoutes(event: .startStop, transitions: [
            .work => .idle, .rest => .idle
        ])
        stateMachine.addRoutes(event: .startStop, transitions: [.idle => .work]) { _ in
            self.startWith == .work
        }
        stateMachine.addRoutes(event: .startStop, transitions: [.idle => .rest]) { _ in
            self.startWith != .work
        }
        stateMachine.addRoutes(event: .any, transitions: [.work => .idle]) { _ in
            self.stopAfter == .work
        }
        stateMachine.addRoutes(event: .any, transitions: [.work => .rest]) { _ in
            self.stopAfter != .work
        }
        stateMachine.addRoutes(event: .any, transitions: [.rest => .idle]) { _ in
            self.stopAfter == .rest || (self.stopAfter == .longRest && self.currentWorkInterval >= self.workIntervalsInSet)
        }
        stateMachine.addRoutes(event: .any, transitions: [.rest => .work]) { _ in
            self.stopAfter != .rest && (self.stopAfter != .longRest || self.currentWorkInterval < self.workIntervalsInSet)
        }

        /*
         * "Finish" handlers are called when time interval ended
         * "End"    handlers are called when time interval ended or was cancelled
         */
        stateMachine.addAnyHandler(.rest => .work, handler: onRestFinish)
        stateMachine.addAnyHandler(.any => .work, handler: onWorkStart)
        stateMachine.addAnyHandler(.work => .rest, order: 0, handler: onWorkFinish)
        stateMachine.addAnyHandler(.work => .any, order: 1, handler: onWorkEnd)
        stateMachine.addAnyHandler(.any => .rest, handler: onRestStart)
        stateMachine.addAnyHandler(.any => .idle, handler: onIdleStart)
        stateMachine.addAnyHandler(.any => .any, handler: { ctx in
            logger.append(event: TBLogEventTransition(fromContext: ctx))
        })

        stateMachine.addErrorHandler { ctx in fatalError("state machine context: <\(ctx)>") }

        timerFormatter.unitsStyle = .positional

        KeyboardShortcuts.onKeyUp(for: .startStopTimer, action: startStop)
        KeyboardShortcuts.onKeyUp(for: .pauseResumeTimer, action: pauseResume)
        KeyboardShortcuts.onKeyUp(for: .skipTimer, action: skip)
        KeyboardShortcuts.onKeyUp(for: .addMinuteTimer, action: addMinute)
        notificationCenter.setActionHandler(handler: onNotificationAction)

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
        guard scheme.caseInsensitiveCompare("tomatobar") == .orderedSame else {
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
            addMinute()
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

        if toggleDoNotDisturb, stateMachine.state == .work {
            DispatchQueue.main.async(group: notificationGroup) { [self] in
                _ = DoNotDisturbHelper.shared.set(state: !paused)
            }
        }

        if paused {
            if stateMachine.state == .work {
                player.stopTicking()
            }
            pausedPrevImage = TBStatusItem.shared.statusBarItem?.button?.image
            TBStatusItem.shared.setIcon(name: .pause)
            pausedTimeRemaining = finishTime.timeIntervalSince(Date())
            finishTime = Date.distantFuture
        }
        else {
            if stateMachine.state == .work {
                player.startTicking(isPaused: true)
            }
            if pausedPrevImage != nil {
                TBStatusItem.shared.statusBarItem?.button?.image = pausedPrevImage
            }
            finishTime = Date().addingTimeInterval(pausedTimeRemaining)
        }

        updateTimeLeft()
    }

    func updateTimeLeft() {
        let timeLeft = paused ? pausedTimeRemaining : finishTime.timeIntervalSince(Date())

        if timeLeft >= 3600 {
            timerFormatter.allowedUnits = [.hour, .minute, .second]
            timerFormatter.zeroFormattingBehavior = .dropLeading
        }
        else {
            timerFormatter.allowedUnits = [.minute, .second]
            timerFormatter.zeroFormattingBehavior = .pad
        }

        timeLeftString = timerFormatter.string(from: timeLeft)!
        if timer != nil, !paused, showTimerInMenuBar {
            TBStatusItem.shared.setTitle(title: timeLeftString)
        } else {
            TBStatusItem.shared.setTitle(title: nil)
        }
    }

    func addMinute() {
        if timer == nil {
            return
        }

        let timeLeft = paused ? pausedTimeRemaining : finishTime.timeIntervalSince(Date())
        var newTimeLeft = timeLeft + TimeInterval(60)
        if newTimeLeft > 7200 {
            newTimeLeft = TimeInterval(7200)
        }

        if paused {
            pausedTimeRemaining = newTimeLeft
        }
        else
        {
            finishTime = Date().addingTimeInterval(newTimeLeft)
        }
        updateTimeLeft()
    }

    private func startTimer(seconds: Int) {
        finishTime = Date().addingTimeInterval(TimeInterval(seconds))

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
            
            updateTimeLeft()
            let timeLeft = finishTime.timeIntervalSince(Date())
            if timeLeft <= 0 {
                /*
                 Ticks can be missed during the machine sleep.
                 Stop the timer if it goes beyond an overrun time limit.
                 */
                if timeLeft < overrunTimeLimit {
                    stateMachine <-! .startStop
                } else {
                    stateMachine <-! .timerFired
                }
            }
        }
    }

    private func onTimerCancel() {
        DispatchQueue.main.async { [self] in
            updateTimeLeft()
        }
    }

    private func onNotificationAction(action: TBNotification.Action) {
        if action == .skipRest, stateMachine.state == .rest {
            skip()
        }
    }

    private func onWorkStart(context _: TBStateMachine.Context) {
        if currentWorkInterval >= workIntervalsInSet {
            currentWorkInterval = 1
        }
        else {
            currentWorkInterval += 1
        }
        TBStatusItem.shared.setIcon(name: .work)
        player.playWindup()
        player.startTicking()
        startTimer(seconds: workIntervalLength * 60)
        if toggleDoNotDisturb {
            DispatchQueue.main.async(group: notificationGroup) { [self] in
                let res = DoNotDisturbHelper.shared.set(state: true)
                if !res {
                    stateMachine <-! .startStop
                }
            }
        }
    }

    private func onWorkFinish(context _: TBStateMachine.Context) {
        player.playDing()
    }

    private func onWorkEnd(context _: TBStateMachine.Context) {
        player.stopTicking()
        DispatchQueue.main.async(group: notificationGroup) {
            _ = DoNotDisturbHelper.shared.set(state: false)
        }
    }

    private func onRestStart(context ctx: TBStateMachine.Context) {
        var body = NSLocalizedString("TBTimer.onRestStart.short.body", comment: "Short break body")
        var length = shortRestIntervalLength
        var imgName = NSImage.Name.shortRest
        if currentWorkInterval >= workIntervalsInSet {
            body = NSLocalizedString("TBTimer.onRestStart.long.body", comment: "Long break body")
            length = longRestIntervalLength
            imgName = .longRest
        }
        if showFullScreenMask {
            MaskHelper.shared.showMaskWindow(desc: body) { [self] in
                onNotificationAction(action: .skipRest)
            }
        } else if ctx.event == .timerFired {
            DispatchQueue.main.async(group: notificationGroup) { [self] in
                notificationCenter.send(
                    title: NSLocalizedString("TBTimer.onRestStart.title", comment: "Time's up title"),
                    body: body,
                    category: .restStarted
                )
            }
        }
        TBStatusItem.shared.setIcon(name: imgName)
        startTimer(seconds: length * 60)
    }

    private func onRestFinish(context ctx: TBStateMachine.Context) {
        MaskHelper.shared.hideMaskWindow()
        if ctx.event == .skipEvent {
            return
        }
        DispatchQueue.main.async(group: notificationGroup) { [self] in
            notificationCenter.send(
                title: NSLocalizedString("TBTimer.onRestFinish.title", comment: "Break is over title"),
                body: NSLocalizedString("TBTimer.onRestFinish.body", comment: "Break is over body"),
                category: .restFinished
            )
        }
    }

    private func onIdleStart(context _: TBStateMachine.Context) {
        player.stopPlayers()
        stopTimer()
        MaskHelper.shared.hideMaskWindow()
        TBStatusItem.shared.setIcon(name: .idle)
        currentWorkInterval = 0
    }
}
