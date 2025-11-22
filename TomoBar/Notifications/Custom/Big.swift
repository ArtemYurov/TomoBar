import SwiftUI
import AppKit

private enum Layout {
    static let windowWidth = BaseLayout.windowWidth
    static let iconSize: CGFloat = 64
    static let titleFontSize = BaseLayout.titleFontSize
    static let subtitleFontSize = BaseLayout.subtitleFontSize
    static let buttonHeight = BaseLayout.buttonHeight
    static let topPadding: CGFloat = 10
    static let bottomPadding: CGFloat = 10
    static let iconTextSpacing = BaseLayout.iconTextSpacing
    static let textSpacing = BaseLayout.textSpacing
}

struct BigNotificationView: View {
    let title: String
    let subtitle: String
    let nextActionTitle: String
    let skipActionTitle: String
    let isSessionCompleted: Bool
    let windowHeight: CGFloat
    let opacity: CGFloat
    let onAction: (UserChoiceAction) -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: Layout.iconTextSpacing) {
                Image("TomoIcon")
                    .resizable()
                    .frame(width: Layout.iconSize, height: Layout.iconSize)

                VStack(alignment: .center, spacing: Layout.textSpacing) {
                    Text(title)
                        .font(.system(size: Layout.titleFontSize, weight: .medium))
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.system(size: Layout.subtitleFontSize))
                        .foregroundColor(.primary.opacity(0.8))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, Layout.topPadding)
            .padding(.bottom, Layout.bottomPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.clear)

            Spacer()

            VStack(spacing: 0) {
                NotificationSeparator(orientation: .horizontal, length: Layout.windowWidth)

                if !isSessionCompleted {
                    timeAddingButtons
                    NotificationSeparator(orientation: .horizontal, length: Layout.windowWidth)
                }

                HStack(spacing: 0) {
                    NotificationButton(
                        title: skipActionTitle,
                        action: { onAction(!isSessionCompleted ? .skipInterval : .restart) }
                    )

                    NotificationSeparator(orientation: .vertical, length: Layout.buttonHeight)

                    NotificationButton(
                        title: nextActionTitle,
                        action: { onAction(!isSessionCompleted ? .nextInterval : .close) }
                    )
                }
                .frame(height: Layout.buttonHeight)
            }
            .background(Color.clear)
        }
        .frame(width: Layout.windowWidth, height: windowHeight)
        .notificationBackground(opacity: opacity)
    }

    private var timeAddingButtons: some View {
        HStack(spacing: 0) {
            NotificationButton(
                title: NSLocalizedString("CustomNotification.control.addMinute", comment: "Add 1 minute"),
                action: { onAction(.addMinute) }
            )

            NotificationSeparator(orientation: .vertical, length: Layout.buttonHeight)

            NotificationButton(
                title: NSLocalizedString("CustomNotification.control.addTwoMinutes", comment: "Add 2 minutes"),
                action: { onAction(.addTwoMinutes) }
            )

            NotificationSeparator(orientation: .vertical, length: Layout.buttonHeight)

            NotificationButton(
                title: NSLocalizedString("CustomNotification.control.addFiveMinutes", comment: "Add 5 minutes"),
                action: { onAction(.addFiveMinutes) }
            )
        }
        .frame(height: Layout.buttonHeight)
    }
}

private struct BigWindowConfig {
    let windowWidth: CGFloat
    let windowHeight: CGFloat
    let menuBarOffset: CGFloat
    let animationDuration: CGFloat
    let animationStartOffset: CGFloat
}

extension CustomNotifyHelper {
    func showBig(style: NotificationStyle, isSessionCompleted: Bool) {
        guard case .big(let content) = style else { return }

        let windowWidth: CGFloat = Layout.windowWidth
        let windowHeight: CGFloat = !isSessionCompleted ? 214 : 170
        let menuBarOffset: CGFloat = BaseLayout.menuBarOffset
        let animationDuration: CGFloat = 0.6
        let animationStartOffset: CGFloat = BaseLayout.animationStartOffset

        let view = BigNotificationView(
            title: content.title,
            subtitle: content.subtitle,
            nextActionTitle: content.nextActionTitle,
            skipActionTitle: content.skipActionTitle,
            isSessionCompleted: isSessionCompleted,
            windowHeight: windowHeight,
            opacity: CGFloat(customBackgroundOpacity),
            onAction: self.handleAction
        )

        let hostingController = NSHostingController(rootView: AnyView(view))
        self.hostingController = hostingController

        let config = BigWindowConfig(
            windowWidth: windowWidth,
            windowHeight: windowHeight,
            menuBarOffset: menuBarOffset,
            animationDuration: animationDuration,
            animationStartOffset: animationStartOffset
        )

        configureAndAnimateBigWindow(hostingController: hostingController, config: config)
    }

    private func configureAndAnimateBigWindow(
        hostingController: NSHostingController<AnyView>,
        config: BigWindowConfig
    ) {
        let window = BigNotificationWindow(contentViewController: hostingController)
        window.styleMask = [.borderless, .fullSizeContentView]
        window.level = .popUpMenu
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true

        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        let xPos = (screenFrame.width - config.windowWidth) / 2
        let yPos = screenFrame.maxY - config.windowHeight - config.menuBarOffset
        let startY = screenFrame.maxY + config.animationStartOffset

        window.setFrame(NSRect(x: xPos, y: startY, width: config.windowWidth, height: config.windowHeight), display: true)
        window.orderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        self.window = window

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = config.animationDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().setFrame(NSRect(x: xPos, y: yPos, width: config.windowWidth, height: config.windowHeight), display: true)
        })
    }
}
