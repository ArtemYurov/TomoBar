import SwiftUI

enum AlertMode: String, CaseIterable, DropdownDescribable {
    case disabled, notify, fullScreen
}

enum NotifyStyle: String, CaseIterable, DropdownDescribable {
    case notifySystem, small, big
}

class TBNotify: ObservableObject {
    @AppStorage("alertMode") var alertMode = AlertMode.notify
    @AppStorage("notifyStyle") var notifyStyle = NotifyStyle.big

    let system: SystemNotifyHelper
    let custom: CustomNotifyHelper
    let mask: MaskHelper

    init(skipHandler: @escaping () -> Void, userChoiceHandler: @escaping (UserChoiceAction) -> Void) {
        self.system = SystemNotifyHelper(skipHandler: skipHandler)
        self.custom = CustomNotifyHelper(userChoiceHandler: userChoiceHandler)
        self.mask = MaskHelper(skipHandler: skipHandler, userChoiceHandler: userChoiceHandler)
    }

    func shouldAutoTransition(from state: TBStateMachineStates) -> Bool {
        switch alertMode {
        case .disabled:
            return true
        case .notify:
            return notifyStyle == .notifySystem
        case .fullScreen:
            // Always auto-transition from Work to Rest, from Rest depends on setting
            return state == .work ? true : mask.maskAutoResumeWork
        }
    }

    func showUserChoice(for state: TBStateMachineStates, nextIsLongRest: Bool) {
        // Called only when shouldAutoTransition == false
        switch alertMode {
        case .notify:
            // small/big windows
            custom.showIntervalComplete(state: state, nextIsLongRest: nextIsLongRest, notifyStyle: notifyStyle)

        case .fullScreen:
            mask.show(isLong: state == .longRest, isRestStarted: false)

        case .disabled:
            return
        }
    }

    func showRestStarted(isLong: Bool) {
        switch alertMode {

        case .notify where notifyStyle == .notifySystem:
            system.restStarted(isLong: isLong)

        case .fullScreen:
            mask.show(isLong: isLong, isRestStarted: true, blockActions: mask.maskBlockActions)

        default:
            return
        }
    }

    func showRestFinished() {
        if alertMode == .notify && notifyStyle == .notifySystem {
            system.restFinished()
        }
    }

    func showSessionCompleted() {
        switch alertMode {
        case .disabled:
            return

        case .notify:
            switch notifyStyle {
            case .notifySystem:
                system.sessionComplete()
            case .small, .big:
                custom.showSessionComplete(notifyStyle: notifyStyle)
            }

        case .fullScreen:
            system.sessionComplete()
        }
    }

    func preview() {

        switch alertMode {
        case .disabled:
            custom.hide()
            return

        case .notify:
            switch notifyStyle {
            case .notifySystem:
                custom.hide()
                system.sessionComplete()
            case .small, .big:
                custom.showSessionComplete(notifyStyle: notifyStyle)
            }

        case .fullScreen:
            custom.hide()
        }
    }
}
