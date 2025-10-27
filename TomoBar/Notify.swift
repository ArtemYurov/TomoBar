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
    @AppStorage("maskMode") var maskMode = MaskMode.normal

    let system: SystemNotifyHelper
    let choice: CustomNotifyHelper
    let mask: MaskHelper

    init(skipHandler: @escaping () -> Void, userChoiceHandler: @escaping (UserChoiceAction) -> Void) {
        self.system = SystemNotifyHelper(skipHandler: skipHandler)
        self.choice = CustomNotifyHelper(userChoiceHandler: userChoiceHandler)
        self.mask = MaskHelper(skipHandler: skipHandler)
    }

    var shouldAutoTransition: Bool {
        switch alertMode {
        case .disabled:
            return true
        case .notify:
            return notifyStyle == .system
        case .fullScreen:
            return true
        }
    }

    func showUserChoice(for state: TBStateMachineStates, nextIsLongRest: Bool) {
        // Called only when shouldAutoTransition == false (small/big)
        choice.showIntervalComplete(state: state, nextIsLongRest: nextIsLongRest, notifyStyle: notifyStyle)
    }

    func showRestStarted(isLong: Bool) {
        switch alertMode {

        case .notify where notifyStyle == .system:
            system.restStarted(isLong: isLong)

        case .fullScreen:
            mask.show(isLong: isLong, blockActions: (maskMode == .blockActions))

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
                choice.showSessionComplete(notifyStyle: notifyStyle)
            }

        case .fullScreen:
            system.sessionComplete()
        }
    }
}
