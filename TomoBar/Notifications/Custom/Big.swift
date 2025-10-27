import SwiftUI
import AppKit

private enum Layout {
    static let windowWidth = BaseLayout.windowWidth
    static let windowHeight: CGFloat = 190
    static let iconSize = BaseLayout.iconSize
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
    let addMinuteTitle: String
    let addFiveMinutesTitle: String
    let stopTitle: String
    let nextActionTitle: String
    let skipActionTitle: String
    let isSessionCompleted: Bool
    let onAction: (UserChoiceAction) -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: Layout.iconTextSpacing) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: Layout.iconSize, height: Layout.iconSize)

                VStack(alignment: .center, spacing: Layout.textSpacing) {
                    Text(title)
                        .font(.system(size: Layout.titleFontSize, weight: .medium))
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.system(size: Layout.subtitleFontSize))
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, Layout.topPadding)
            .padding(.bottom, Layout.bottomPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.clear)

            Spacer()

            if isSessionCompleted {
                VStack(spacing: 0) {
                    NotificationSeparator(orientation: .horizontal, length: Layout.windowWidth)

                    HStack(spacing: 0) {
                        NotificationButton(title: skipActionTitle, action: { onAction(.close) })

                        NotificationSeparator(orientation: .vertical, length: Layout.buttonHeight)

                        NotificationButton(title: nextActionTitle, action: { onAction(.restart) })
                    }
                    .frame(height: Layout.buttonHeight)
                }
                .background(Color.clear)
            } else {
                VStack(spacing: 0) {
                    NotificationSeparator(orientation: .horizontal, length: Layout.windowWidth)

                    HStack(spacing: 0) {
                        NotificationButton(title: addMinuteTitle, action: { onAction(.addMinute) })

                        NotificationSeparator(orientation: .vertical, length: Layout.buttonHeight)

                        NotificationButton(title: addFiveMinutesTitle, action: { onAction(.addFiveMinutes) })
                    }
                    .frame(height: Layout.buttonHeight)

                    NotificationSeparator(orientation: .horizontal, length: Layout.windowWidth)

                    HStack(spacing: 0) {
                        NotificationButton(title: stopTitle, action: { onAction(.stop) })

                        NotificationSeparator(orientation: .vertical, length: Layout.buttonHeight)

                        NotificationButton(title: nextActionTitle, action: { onAction(.next) })

                        NotificationSeparator(orientation: .vertical, length: Layout.buttonHeight)

                        NotificationButton(title: skipActionTitle, action: { onAction(.skip) })
                    }
                    .frame(height: Layout.buttonHeight)
                }
                .background(Color.clear)
            }
        }
        .frame(width: Layout.windowWidth, height: Layout.windowHeight)
        .notificationBackground()
    }
}

extension CustomNotifyHelper {
    func showBig(style: NotificationStyle, isSessionCompleted: Bool) {
        guard case .big(let content) = style else { return }

        // Генерируем дополнительные локализованные строки для Big notification
        let addMinuteTitle = NSLocalizedString(
            "CustomNotification.control.addMinute",
            comment: "Add 1 minute"
        )
        let addFiveMinutesTitle = NSLocalizedString(
            "CustomNotification.control.addFiveMinutes",
            comment: "Add 5 minutes"
        )
        let stopTitle = NSLocalizedString(
            "CustomNotification.control.stop",
            comment: "Stop"
        )

        let view = BigNotificationView(
            title: content.title,
            subtitle: content.subtitle,
            addMinuteTitle: addMinuteTitle,
            addFiveMinutesTitle: addFiveMinutesTitle,
            stopTitle: stopTitle,
            nextActionTitle: content.nextActionTitle,
            skipActionTitle: content.skipActionTitle,
            isSessionCompleted: isSessionCompleted,
            onAction: handleAction
        )

        let window = BigNotificationWindow(
            contentRect: NSRect(x: 0, y: 0, width: Layout.windowWidth, height: Layout.windowHeight),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.level = .statusBar
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true

        let hostingController = NSHostingController(rootView: AnyView(view))
        window.contentViewController = hostingController

        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let originX = (screenFrame.width - Layout.windowWidth) / 2 + screenFrame.origin.x
            let originY = (screenFrame.height - Layout.windowHeight) / 2 + screenFrame.origin.y
            window.setFrameOrigin(NSPoint(x: originX, y: originY))
        }

        self.window = window
        self.hostingController = hostingController

        window.alphaValue = 0
        window.makeKeyAndOrderFront(nil)

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = BaseLayout.animationDuration
            window.animator().alphaValue = 1
        })
    }
}
