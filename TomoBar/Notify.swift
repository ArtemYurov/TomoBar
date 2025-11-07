import SwiftUI

enum AlertMode: String, CaseIterable, DropdownDescribable {
    case disabled, notify, fullScreen
}

enum NotifyStyle: String, CaseIterable, DropdownDescribable {
    case system, small, big
}

enum MaskMode: String, CaseIterable, DropdownDescribable {
    case normal, blockActions
}

class TBNotify: ObservableObject {
    @AppStorage("alertMode") var alertMode = AlertMode.notify
    @AppStorage("notifyStyle") var notifyStyle = NotifyStyle.system

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
            return notifyStyle == .system
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
            mask.showRestFinished(state: state)

        case .disabled:
            return
        }
    }

    func showRestStarted(isLong: Bool) {
        switch alertMode {

        case .notify where notifyStyle == .system:
            system.restStarted(isLong: isLong)

        case .fullScreen:
            mask.show(isLong: isLong, blockActions: (mask.maskMode == .blockActions))

        default:
            return
        }
    }

    func showRestFinished() {
        if alertMode == .fullScreen {
            mask.hide()
        }

        if alertMode == .notify && notifyStyle == .system {
            system.restFinished()
        }
    }

    func showSessionCompleted() {
        switch alertMode {
        case .disabled:
            return

        case .notify:
            switch notifyStyle {
            case .system:
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
            case .system:
                custom.hide()
            case .small, .big:
                custom.showSessionComplete(notifyStyle: notifyStyle)
            }

        case .fullScreen:
            custom.hide()
        }
    }
}
