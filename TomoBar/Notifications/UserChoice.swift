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
    case small(
        title: String,
        subtitle: String,
        nextActionTitle: String,
        skipActionTitle: String
    )
    case big(
        title: String,
        subtitle: String,
        addMinuteTitle: String,
        addFiveMinutesTitle: String,
        stopTitle: String,
        nextActionTitle: String,
        skipActionTitle: String
    )
}

enum BaseLayout {
    // Element sizes
    static let iconSize: CGFloat = 40
    static let titleFontSize: CGFloat = 14
    static let subtitleFontSize: CGFloat = 12
    static let buttonFontSize: CGFloat = 13
    static let buttonHeight: CGFloat = 36

    // Colors and transparency
    static let separatorOpacity: CGFloat = 0.3
    static let backgroundOpacity: CGFloat = 0.8

    // Corner radius and shadows
    static let cornerRadius: CGFloat = 12
    static let shadowRadius: CGFloat = 12

    // Spacing between elements
    static let spacing: CGFloat = 12
    static let contentPadding: CGFloat = 12
    static let textSpacing: CGFloat = 2
    static let iconTextSpacing: CGFloat = 6

    // Animation (common for all notifications)
    static let animationDuration: CGFloat = 0.4
    static let animationStartOffset: CGFloat = 50

    // Window positioning (common)
    static let screenEdgeOffset: CGFloat = 10
    static let menuBarOffset: CGFloat = 5

    // Window width (same for all notifications)
    static let windowWidth: CGFloat = 360
}

final class UserChoiceHelper: NSObject {

    private var window: NSWindow?
    private var hostingController: NSHostingController<AnyView>?
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
            style = .small(
                title: content.title,
                subtitle: content.subtitle,
                nextActionTitle: content.nextActionTitle,
                skipActionTitle: content.skipActionTitle
            )
        case .big:
            style = .big(
                title: content.title,
                subtitle: content.subtitle,
                addMinuteTitle: NSLocalizedString("CustomNotification.control.addMinute", comment: "+1 min"),
                addFiveMinutesTitle: NSLocalizedString("CustomNotification.control.addFiveMinutes", comment: "+5 min"),
                stopTitle: NSLocalizedString("CustomNotification.control.stop", comment: "Stop"),
                nextActionTitle: content.nextActionTitle,
                skipActionTitle: content.skipActionTitle
            )
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
            style = .small(
                title: content.title,
                subtitle: content.subtitle,
                nextActionTitle: content.nextActionTitle,
                skipActionTitle: content.skipActionTitle
            )
        case .big:
            style = .big(
                title: content.title,
                subtitle: content.subtitle,
                addMinuteTitle: NSLocalizedString("CustomNotification.control.addMinute", comment: "+1 min"),
                addFiveMinutesTitle: NSLocalizedString("CustomNotification.control.addFiveMinutes", comment: "+5 min"),
                stopTitle: NSLocalizedString("CustomNotification.control.stop", comment: "Stop"),
                nextActionTitle: content.nextActionTitle,
                skipActionTitle: content.skipActionTitle
            )
        case .system:
            return
        }

        show(style: style, isSessionCompleted: true)
    }

    func show(style: NotificationStyle, isSessionCompleted: Bool = false) {
        currentStyle = style

        cleanupExistingWindow()

        switch style {
        case .small(let title, let subtitle, let next, let skip):
            showSmall(title: title, subtitle: subtitle,
                     nextActionTitle: next, skipActionTitle: skip,
                     isSessionCompleted: isSessionCompleted)
        case .big(let title, let subtitle, let addMinute, let addFive, let stop, let next, let skip):
            showBig(title: title, subtitle: subtitle,
                   addMinuteTitle: addMinute, addFiveMinutesTitle: addFive,
                   stopTitle: stop, nextActionTitle: next,
                   skipActionTitle: skip, isSessionCompleted: isSessionCompleted)
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

    private func handleAction(_ action: UserChoiceAction) {
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

    private func showSmall(title: String, subtitle: String,
                          nextActionTitle: String, skipActionTitle: String,
                          isSessionCompleted: Bool) {
        let view = SmallNotificationView(
            title: title,
            subtitle: subtitle,
            nextActionTitle: nextActionTitle,
            skipActionTitle: skipActionTitle,
            isSessionCompleted: isSessionCompleted,
            onAction: self.handleAction
        )

        hostingController = NSHostingController(rootView: AnyView(view))

        // Small notification constants
        let windowWidth: CGFloat = BaseLayout.windowWidth
        let windowHeight: CGFloat = 72
        let screenRightOffset: CGFloat = BaseLayout.screenEdgeOffset
        let screenTopOffset: CGFloat = 15
        let animationDuration: CGFloat = BaseLayout.animationDuration
        let animationStartOffset: CGFloat = BaseLayout.animationStartOffset

        window = BigNotificationWindow(contentViewController: hostingController!)
        window?.styleMask = [.borderless, .fullSizeContentView]
        window?.level = .screenSaver
        window?.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        window?.backgroundColor = .clear
        window?.isOpaque = false
        window?.hasShadow = true

        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let finalX = screenFrame.maxX - windowWidth - screenRightOffset
            let y = screenFrame.maxY - windowHeight - screenTopOffset
            let startX = screenFrame.maxX + animationStartOffset

            window?.setFrame(
                NSRect(x: startX, y: y, width: windowWidth, height: windowHeight),
                display: true
            )

            window?.orderFront(nil)

            NSAnimationContext.runAnimationGroup({ context in
                context.duration = animationDuration
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                window?.animator().setFrame(
                    NSRect(x: finalX, y: y, width: windowWidth, height: windowHeight),
                    display: true
                )
            })
        } else {
            window?.orderFront(nil)
        }
    }

    private func showBig(title: String, subtitle: String,
                        addMinuteTitle: String, addFiveMinutesTitle: String,
                        stopTitle: String, nextActionTitle: String,
                        skipActionTitle: String, isSessionCompleted: Bool) {
        let contentView = BigNotificationView(
            title: title,
            subtitle: subtitle,
            addMinuteTitle: addMinuteTitle,
            addFiveMinutesTitle: addFiveMinutesTitle,
            stopTitle: stopTitle,
            nextActionTitle: nextActionTitle,
            skipActionTitle: skipActionTitle,
            isSessionCompleted: isSessionCompleted,
            onAction: self.handleAction
        )

        hostingController = NSHostingController(rootView: AnyView(contentView))

        // Big notification constants
        let windowWidth: CGFloat = BaseLayout.windowWidth
        let windowHeight: CGFloat = isSessionCompleted ? 146 : 190  // 146 = 110 (base) + 36 (button height)
        let menuBarOffset: CGFloat = BaseLayout.menuBarOffset
        let animationDuration: CGFloat = 0.6
        let animationStartOffset: CGFloat = BaseLayout.animationStartOffset

        window = BigNotificationWindow(contentViewController: hostingController!)
        window?.styleMask = [.borderless, .fullSizeContentView]
        window?.level = .screenSaver
        window?.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        window?.backgroundColor = .clear
        window?.isOpaque = false
        window?.hasShadow = true

        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        let xPos = (screenFrame.width - windowWidth) / 2
        let yPos = screenFrame.maxY - windowHeight - menuBarOffset
        let startY = screenFrame.maxY + animationStartOffset

        window?.setFrame(NSRect(x: xPos, y: startY, width: windowWidth, height: windowHeight), display: true)
        window?.orderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = animationDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window?.animator().setFrame(NSRect(x: xPos, y: yPos, width: windowWidth, height: windowHeight), display: true)
        })
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

class BigNotificationWindow: NSWindow {
    override var canBecomeKey: Bool {
        return false
    }

    override var canBecomeMain: Bool {
        return false
    }
}

struct NotificationButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: BaseLayout.buttonFontSize))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NotificationSeparator: View {
    enum Orientation {
        case horizontal
        case vertical
    }

    let orientation: Orientation
    let length: CGFloat?

    init(orientation: Orientation = .horizontal, length: CGFloat? = nil) {
        self.orientation = orientation
        self.length = length
    }

    var body: some View {
        Rectangle()
            .fill(Color.gray.opacity(BaseLayout.separatorOpacity))
            .frame(
                width: orientation == .vertical ? 1 : length,
                height: orientation == .horizontal ? 1 : length
            )
    }
}

struct NotificationBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: BaseLayout.cornerRadius)
                    .fill(Color(NSColor.windowBackgroundColor).opacity(BaseLayout.backgroundOpacity))
                    .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 2)
            )
    }
}

extension View {
    func notificationBackground() -> some View {
        modifier(NotificationBackgroundModifier())
    }
}
