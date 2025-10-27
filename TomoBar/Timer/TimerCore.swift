import Foundation

extension TBTimer {
    func getNextIntervalDuration() -> TimeInterval {
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

    func getIntervalMinutes(for state: TBStateMachineStates) -> Double {
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

    func startStateTimer() {
        guard stateMachine.state != .idle else { return }
        let minutes = getIntervalMinutes(for: stateMachine.state)
        startTimer(seconds: Int(minutes * 60))
    }

    func startTimer(seconds: Int) {
        finishTime = Date().addingTimeInterval(TimeInterval(seconds))
        startTime = Date()  // Save when timer started
        pausedTimeElapsed = 0  // Reset paused elapsed time

        // Prevent App Nap while timer is running
        appNapPrevent.startActivity()

        let queue = DispatchQueue(label: "Timer")
        timer = DispatchSource.makeTimerSource(flags: .strict, queue: queue)
        timer!.schedule(deadline: .now(), repeating: .seconds(1), leeway: .never)
        timer!.setEventHandler(handler: onTimerTick)
        timer!.setCancelHandler(handler: onTimerCancel)
        timer!.resume()
    }

    func stopTimer() {
        guard let timer else { return }
        timer.cancel()
        self.timer = nil

        // End App Nap prevention
        appNapPrevent.endActivity()
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
            pausedTimeElapsed -= seconds
        } else {
            startTime = startTime.addingTimeInterval(seconds)
            finishTime = Date().addingTimeInterval(newTimeLeft)
        }
        updateDisplay()
    }
}
