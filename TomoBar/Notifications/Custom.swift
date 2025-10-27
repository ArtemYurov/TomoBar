import SwiftUI
import AppKit

struct NotificationContent {
    let title: String
    let subtitle: String
    let nextActionTitle: String
    let skipActionTitle: String
}

enum UserChoiceAction {
    case next              // transition to the next interval
    case skip              // skip the next interval
    case addMinute         // add 1 minute
    case addFiveMinutes    // add 5 minutes
    case stop              // stop the timer
    case close             // close window
    case restart           // restart the session
}

enum NotificationStyle {
    case small(content: NotificationContent)
    case big(content: NotificationContent)
}

final class CustomNotifyHelper: NSObject {

    var window: NSWindow?
    var hostingController: NSHostingController<AnyView>?
    private var actionCallback: ((UserChoiceAction) -> Void)?
    private var currentStyle: NotificationStyle?

    init(userChoiceHandler: @escaping (UserChoiceAction) -> Void) {
        self.actionCallback = userChoiceHandler
        super.init()
    }

    func showIntervalComplete(state: TBStateMachineStates, nextIsLongRest: Bool, notifyStyle: NotifyStyle) {
        let content = buildIntervalContent(state: state, nextIsLongRest: nextIsLongRest)

        let style: NotificationStyle
        switch notifyStyle {
        case .small:
            style = .small(content: content)
        case .big:
            style = .big(content: content)
        case .system:
            return
        }

        show(style: style, isSessionCompleted: false)
    }

    func showSessionComplete(notifyStyle: NotifyStyle) {
        let content = buildSessionCompletedContent(notifyStyle: notifyStyle)

        let style: NotificationStyle
        switch notifyStyle {
        case .small:
            style = .small(content: content)
        case .big:
            style = .big(content: content)
        case .system:
            return
        }

        show(style: style, isSessionCompleted: true)
    }

    func show(style: NotificationStyle, isSessionCompleted: Bool = false) {
        currentStyle = style

        cleanupExistingWindow()

        switch style {
        case .small:
            showSmall(style: style, isSessionCompleted: isSessionCompleted)
        case .big:
            showBig(style: style, isSessionCompleted: isSessionCompleted)
        }
    }

    func hide() {
        guard window != nil else {
            return
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }

            if let window = self.window {
                window.orderOut(nil)

                if let controller = self.hostingController {
                    controller.view.removeFromSuperview()
                    controller.removeFromParent()
                    self.hostingController = nil
                }

                window.contentViewController = nil
                window.close()
                self.window = nil
            }
        }
    }

    func handleAction(_ action: UserChoiceAction) {
        guard let callback = actionCallback else {
            return
        }
        callback(action)
    }

    private func cleanupExistingWindow() {
        if let existingWindow = window {
            existingWindow.orderOut(nil)
            if let existingController = hostingController {
                existingController.view.removeFromSuperview()
                existingController.removeFromParent()
            }
            existingWindow.contentViewController = nil
            existingWindow.close()
            window = nil
            hostingController = nil
        }
    }

    // MARK: - Content Building

    private func buildIntervalContent(state: TBStateMachineStates, nextIsLongRest: Bool) -> NotificationContent {
        switch state {
        case .work:
            return NotificationContent(
                title: NSLocalizedString("CustomNotification.workComplete.title", comment: "Work session complete"),
                subtitle: nextIsLongRest
                    ? NSLocalizedString("CustomNotification.workComplete.longBreak.subtitle", comment: "Time for a long break")
                    : NSLocalizedString("CustomNotification.workComplete.shortBreak.subtitle", comment: "Time for a short break"),
                nextActionTitle: NSLocalizedString("CustomNotification.workComplete.takeBreak.action", comment: "Take Break"),
                skipActionTitle: NSLocalizedString("CustomNotification.workComplete.skipBreak.action", comment: "Skip Break")
            )

        case .shortRest:
            return NotificationContent(
                title: NSLocalizedString("CustomNotification.shortBreakComplete.title", comment: "Short break is over"),
                subtitle: NSLocalizedString("CustomNotification.breakComplete.subtitle", comment: "Ready to work?"),
                nextActionTitle: NSLocalizedString("CustomNotification.breakComplete.startWork.action", comment: "Start Work"),
                skipActionTitle: NSLocalizedString("CustomNotification.breakComplete.skipWork.action", comment: "Skip Work")
            )

        case .longRest:
            return NotificationContent(
                title: NSLocalizedString("CustomNotification.longBreakComplete.title", comment: "Long break is over"),
                subtitle: NSLocalizedString("CustomNotification.breakComplete.subtitle", comment: "Ready to work?"),
                nextActionTitle: NSLocalizedString("CustomNotification.breakComplete.startWork.action", comment: "Start Work"),
                skipActionTitle: NSLocalizedString("CustomNotification.breakComplete.skipWork.action", comment: "Skip Work")
            )

        case .idle:
            return NotificationContent(
                title: "",
                subtitle: "",
                nextActionTitle: "",
                skipActionTitle: ""
            )
        }
    }

    private func buildSessionCompletedContent(notifyStyle: NotifyStyle) -> NotificationContent {
        let restartTitle: String
        switch notifyStyle {
        case .small:
            restartTitle = NSLocalizedString("CustomNotification.control.restart.small", comment: "Restart")
        case .big:
            restartTitle = NSLocalizedString("CustomNotification.control.restart.big", comment: "Restart Session")
        case .system:
            restartTitle = ""
        }

        return NotificationContent(
            title: NSLocalizedString("CustomNotification.sessionComplete.title", comment: "Timer completed"),
            subtitle: NSLocalizedString("CustomNotification.sessionComplete.subtitle", comment: "Session finished"),
            nextActionTitle: restartTitle,
            skipActionTitle: NSLocalizedString("CustomNotification.control.close", comment: "Close")
        )
    }
}
