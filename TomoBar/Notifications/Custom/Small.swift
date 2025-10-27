import SwiftUI
import AppKit

private enum Layout {
    static let windowWidth = BaseLayout.windowWidth
    static let windowHeight: CGFloat = 72
    static let animationDuration = BaseLayout.animationDuration
    static let animationStartOffset = BaseLayout.animationStartOffset
    static let screenRightOffset = BaseLayout.screenEdgeOffset
    static let screenTopOffset: CGFloat = 15
    static let iconSize = BaseLayout.iconSize
    static let titleFontSize = BaseLayout.titleFontSize
    static let subtitleFontSize = BaseLayout.subtitleFontSize
    static let spacing = BaseLayout.spacing
    static let contentPadding = BaseLayout.contentPadding
    static let textSpacing = BaseLayout.textSpacing
    static let buttonWidth: CGFloat = 100
    static let buttonHeight: CGFloat = 30
}

struct SmallNotificationView: View {
    let title: String
    let subtitle: String
    let nextActionTitle: String
    let skipActionTitle: String
    let isSessionCompleted: Bool
    let opacity: CGFloat
    let onAction: (UserChoiceAction) -> Void

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: Layout.spacing) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: Layout.iconSize, height: Layout.iconSize)

                VStack(alignment: .leading, spacing: Layout.textSpacing) {
                    Text(title)
                        .font(.system(size: Layout.titleFontSize, weight: .medium))
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.system(size: Layout.subtitleFontSize))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.leading, Layout.contentPadding)
            .padding(.vertical, Layout.contentPadding)

            Spacer()

            NotificationSeparator(orientation: .vertical)

            if isSessionCompleted {
                VStack(spacing: 0) {
                    NotificationButton(title: nextActionTitle, action: { onAction(.restart) })

                    NotificationSeparator(orientation: .horizontal)

                    NotificationButton(title: skipActionTitle, action: { onAction(.close) })
                }
                .frame(width: Layout.buttonWidth, height: Layout.windowHeight)
            } else {
                VStack(spacing: 0) {
                    NotificationButton(title: skipActionTitle, action: { onAction(.skip) })

                    NotificationSeparator(orientation: .horizontal)

                    NotificationButton(title: nextActionTitle, action: { onAction(.next) })
                }
                .frame(width: Layout.buttonWidth, height: Layout.windowHeight)
            }
        }
        .frame(width: Layout.windowWidth, height: Layout.windowHeight)
        .notificationBackground(opacity: opacity)
    }
}

extension CustomNotifyHelper {
    func showSmall(style: NotificationStyle, isSessionCompleted: Bool) {
        guard case .small(let content) = style else { return }

        let view = SmallNotificationView(
            title: content.title,
            subtitle: content.subtitle,
            nextActionTitle: content.nextActionTitle,
            skipActionTitle: content.skipActionTitle,
            isSessionCompleted: isSessionCompleted,
            opacity: CGFloat(customBackgroundOpacity),
            onAction: self.handleAction
        )

        let hostingController = NSHostingController(rootView: AnyView(view))
        self.hostingController = hostingController

        let windowWidth: CGFloat = Layout.windowWidth
        let windowHeight: CGFloat = Layout.windowHeight
        let screenRightOffset: CGFloat = Layout.screenRightOffset
        let screenTopOffset: CGFloat = Layout.screenTopOffset
        let animationDuration: CGFloat = Layout.animationDuration
        let animationStartOffset: CGFloat = Layout.animationStartOffset

        let window = BigNotificationWindow(contentViewController: hostingController)
        window.styleMask = [.borderless, .fullSizeContentView]
        window.level = .popUpMenu
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true

        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let finalX = screenFrame.maxX - windowWidth - screenRightOffset
            let yPosition = screenFrame.maxY - windowHeight - screenTopOffset
            let startX = screenFrame.maxX + animationStartOffset

            window.setFrame(
                NSRect(x: startX, y: yPosition, width: windowWidth, height: windowHeight),
                display: true
            )

            window.orderFront(nil)

            NSAnimationContext.runAnimationGroup({ context in
                context.duration = animationDuration
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                window.animator().setFrame(
                    NSRect(x: finalX, y: yPosition, width: windowWidth, height: windowHeight),
                    display: true
                )
            })
        } else {
            window.orderFront(nil)
        }

        self.window = window
    }
}
