import AppKit

extension TBTimer {
    func updateDisplay() {
        updateTimeLeft()
        updateStatusBar()
        updateMask()
    }

    func updateTimeLeft() {
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

    func updateStatusBar() {
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

    func updateMask() {
        guard timer != nil else { return }
        if notify.alertMode == .fullScreen && !paused {
            notify.mask.updateTimeLeft(timeLeftString)
        }
    }

    func setTitle(_ title: String?) {
        TBStatusItem.shared.setTitle(title: title)
    }

    func setStateIcon() {
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

    func setPauseIcon() {
        TBStatusItem.shared.setIcon(name: .pause)
    }
}
