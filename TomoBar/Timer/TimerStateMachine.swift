import Foundation
import SwiftState

extension TBTimer {
    func setupStateMachine() {
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

        setupTransitions()
        setupHandlers()
    }

    private func setupTransitions() {
        setupBasicTransitions()
        setupIntervalCompletedTransitions()
        setupUserActionTransitions()
    }

    private func setupBasicTransitions() {
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
    }

    private func setupIntervalCompletedTransitions() {
        // intervalCompleted transitions (auto-transition only if shouldAutoTransition)
        stateMachine.addRoutes(event: .intervalCompleted, transitions: [.work => .shortRest]) { [self] _ in
            nextIntervalIsShortRest() && notify.shouldAutoTransition(from: .work)
        }

        stateMachine.addRoutes(event: .intervalCompleted, transitions: [.work => .longRest]) { [self] _ in
            nextIntervalIsLongRest() && notify.shouldAutoTransition(from: .work)
        }

        stateMachine.addRoutes(event: .intervalCompleted, transitions: [
            .shortRest => .work,
            .longRest => .work
        ]) { [self] _ in
            notify.shouldAutoTransition(from: .shortRest)
        }

        // Pause routes when user choice is required
        stateMachine.addRoutes(event: .intervalCompleted, transitions: [
            .work => .work
        ]) { [self] _ in
            !notify.shouldAutoTransition(from: .work)
        }

        stateMachine.addRoutes(event: .intervalCompleted, transitions: [
            .shortRest => .shortRest,
            .longRest => .longRest
        ]) { [self] _ in
            !notify.shouldAutoTransition(from: .shortRest)
        }
    }

    private func setupUserActionTransitions() {
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
    }

    private func setupHandlers() {
        // State transition handlers (ordered by state: idle -> work -> shortRest -> longRest)
        stateMachine.addAnyHandler(.any => .idle, handler: onIdleStart)
        stateMachine.addAnyHandler(.idle => .any, handler: onIdleEnd)

        // Work handlers - only for real transitions, not pause routes
        stateMachine.addAnyHandler(.idle => .work, handler: onWorkStart)
        stateMachine.addAnyHandler(.shortRest => .work, handler: onWorkStart)
        stateMachine.addAnyHandler(.longRest => .work, handler: onWorkStart)
        stateMachine.addAnyHandler(.work => .idle, handler: onWorkEnd)
        stateMachine.addAnyHandler(.work => .shortRest, handler: onWorkEnd)
        stateMachine.addAnyHandler(.work => .longRest, handler: onWorkEnd)

        // Rest handlers - only for real transitions, not pause routes
        stateMachine.addAnyHandler(.idle => .shortRest, handler: onRestStart)
        stateMachine.addAnyHandler(.work => .shortRest, handler: onRestStart)
        stateMachine.addAnyHandler(.work => .longRest, handler: onRestStart)
        stateMachine.addAnyHandler(.shortRest => .work, handler: onRestEnd)
        stateMachine.addAnyHandler(.longRest => .work, handler: onRestEnd)

        // Event handlers
        stateMachine.addHandler(event: .skipEvent, handler: onSkipEvent)
        stateMachine.addHandler(event: .intervalCompleted, handler: onIntervalCompleted)
        stateMachine.addHandler(event: .sessionCompleted, handler: onSessionCompleted)

        stateMachine.addAnyHandler(.any => .any, handler: { ctx in
            logger.append(event: TBLogEventTransition(fromContext: ctx))
        })

        stateMachine.addErrorHandler { ctx in fatalError("state machine context: <\(ctx)>") }
    }

    func nextIntervalIsShortRest() -> Bool {
        return !nextIntervalIsLongRest()
    }

    func nextIntervalIsLongRest() -> Bool {
        return currentPresetInstance.workIntervalsInSet > 1
            && currentWorkInterval >= currentPresetInstance.workIntervalsInSet
    }

    func isSessionCompleted(for state: TBStateMachineStates) -> Bool {
        switch state {
        case .work:
            return sessionStopAfter == .work
        case .shortRest:
            // Don't end session if this is the initial rest (currentWorkInterval == 0)
            if currentWorkInterval == 0 {
                return false
            }
            // Special case: workIntervalsInSet == 1 && stopAfter == longRest
            if currentPresetInstance.workIntervalsInSet == 1 && sessionStopAfter == .longRest {
                return true
            }
            // Regular case: stopAfter == shortRest
            return sessionStopAfter == .shortRest
        case .longRest:
            return sessionStopAfter == .longRest
        case .idle:
            return false
        }
    }

    private func pauseForUserChoice() {
        // Pause timer
        paused = true
        pausedTimeRemaining = 0
        updateDisplay()  // Show 00:00
    }

    func onTimerTick() {
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

    func onTimerCancel() {
        DispatchQueue.main.async { [self] in
            updateDisplay()
        }
    }

    func handleUserChoiceAction(_ action: UserChoiceAction) {
        notify.custom.hide()

        switch action {
        // for current state (not switched to next)
        case .nextInterval:
            paused = false
            // Hide mask when user confirms next (not skip - skip will update seamlessly)
            if notify.alertMode == .fullScreen {
                notify.mask.hide()
            }
            stateMachine <-! .confirmedNext

        case .skipInterval:
            paused = false
            // Don't hide mask - it will be updated seamlessly
            stateMachine <-! .confirmedNext
            stateMachine <-! .skipEvent

        case .addMinute:
            addMinutes(1)
            pauseResume()

        case .addTwoMinutes:
            addMinutes(2)
            pauseResume()

        case .addFiveMinutes:
            addMinutes(5)
            pauseResume()

        case .stop:
            paused = false
            stateMachine <-! .startStop

        // sessionCompleted - already switched to idle
        case .close:
            break

        case .restart:
            stateMachine <-! .startStop
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
        } else {
            currentWorkInterval += 1
        }
        setStateIcon()
        player.playWindup()
        player.startTicking()
        startStateTimer()
        if currentPresetInstance.focusOnWork {
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
        // Show mask when skipping work in fullScreen mode
        let shouldShowMask = notify.alertMode == .fullScreen &&
                            ctx.event == .skipEvent &&
                            ctx.fromState == .work

        if isAutoTransition || shouldShowMask {
            notify.showRestStarted(isLong: isLongRest)
        }
        setStateIcon()
        startStateTimer()
    }

    private func onRestEnd(context ctx: TBStateMachine.Context) {
        if ctx.event == .skipEvent { return }
        notify.showRestFinished()
    }

    private func onIntervalCompleted(context ctx: TBStateMachine.Context) {
        // Stop ticking and play completion sound for work interval
        if ctx.fromState == .work {
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
        player.stopTicking()

        if isSessionCompleted(for: ctx.fromState) {
            stateMachine <-! .sessionCompleted
        }
    }
}
