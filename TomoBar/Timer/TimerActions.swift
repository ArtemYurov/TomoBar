import Foundation
import SwiftState

extension TBTimer {
    func startStop() {
        notify.custom.hide()
        paused = false
        stateMachine <-! .startStop
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

    func skipInterval() {
        guard timer != nil else { return }

        paused = false
        stateMachine <-! .skipEvent
    }
}
