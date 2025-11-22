import SwiftUI
import AppKit

struct NotificationContent {
    let title: String
    let subtitle: String
    let nextActionTitle: String
    let skipActionTitle: String
}

enum UserChoiceAction {
    case nextInterval      // transition to the next interval
    case skipInterval      // skip the next interval
    case addMinute         // add 1 minute
    case addTwoMinutes     // add 2 minutes
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
    private var autoHideNotifyPreviewTimer: Timer?
    private var isPreviewMode: Bool = false
    @AppStorage("customBackgroundOpacity") var customBackgroundOpacity = Default.customBackgroundOpacity

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
        case .notifySystem:
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
        case .notifySystem:
            return
        }

        show(style: style, isSessionCompleted: true)
    }

    func showPreview(notifyStyle: NotifyStyle) {
        // Show work complete notification to demonstrate buttons
        showIntervalComplete(state: .work, nextIsLongRest: false, notifyStyle: notifyStyle)
        isPreviewMode = true

        // Auto-hide after 4 seconds
        autoHideNotifyPreviewTimer?.invalidate()
        autoHideNotifyPreviewTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { [weak self] _ in
            self?.exitPreviewMode()
            self?.hide()
        }
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
        guard let window = window, let style = currentStyle else {
            return
        }

        exitPreviewMode()

        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }

            let currentFrame = window.frame
            let animationDuration: CGFloat = 0.3
            let animationOffset: CGFloat = BaseLayout.animationStartOffset

            // Determine the end position based on notification type
            let endFrame: NSRect
            switch style {
            case .big:
                // Big notification slides up
                endFrame = NSRect(
                    x: currentFrame.origin.x,
                    y: NSScreen.main?.visibleFrame.maxY ?? currentFrame.origin.y + animationOffset,
                    width: currentFrame.width,
                    height: currentFrame.height
                )
            case .small:
                // Small notification slides right
                endFrame = NSRect(
                    x: NSScreen.main?.visibleFrame.maxX ?? currentFrame.origin.x + animationOffset,
                    y: currentFrame.origin.y,
                    width: currentFrame.width,
                    height: currentFrame.height
                )
            }

            // Animate slide-out
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = animationDuration
                context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                window.animator().setFrame(endFrame, display: true)
            }, completionHandler: {
                // Close window after animation
                window.orderOut(nil)

                if let controller = self.hostingController {
                    controller.view.removeFromSuperview()
                    controller.removeFromParent()
                    self.hostingController = nil
                }

                window.contentViewController = nil
                window.close()
                self.window = nil
                self.currentStyle = nil
            })
        }
    }

    func handleAction(_ action: UserChoiceAction) {
        // Ignore actions in preview mode
        if isPreviewMode {
            exitPreviewMode()
            hide()
            return
        }

        guard let callback = actionCallback else {
            return
        }
        callback(action)
    }

    private func exitPreviewMode() {
        autoHideNotifyPreviewTimer?.invalidate()
        autoHideNotifyPreviewTimer = nil
        isPreviewMode = false
    }

    private func cleanupExistingWindow() {
        exitPreviewMode()

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
        case .notifySystem:
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
