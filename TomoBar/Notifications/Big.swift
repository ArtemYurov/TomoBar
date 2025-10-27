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
    let onAddMinute: () -> Void
    let onAddFiveMinutes: () -> Void
    let onStop: () -> Void
    let onNext: () -> Void
    let onSkip: () -> Void
    let onRestart: () -> Void

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
                        NotificationButton(title: "Close", action: onStop)

                        NotificationSeparator(orientation: .vertical, length: Layout.buttonHeight)

                        NotificationButton(title: "Restart Session", action: onRestart)
                    }
                    .frame(height: Layout.buttonHeight)
                }
                .background(Color.clear)
            } else {
                VStack(spacing: 0) {
                    NotificationSeparator(orientation: .horizontal, length: Layout.windowWidth)

                    HStack(spacing: 0) {
                        NotificationButton(title: addMinuteTitle, action: onAddMinute)

                        NotificationSeparator(orientation: .vertical, length: Layout.buttonHeight)

                        NotificationButton(title: addFiveMinutesTitle, action: onAddFiveMinutes)
                    }
                    .frame(height: Layout.buttonHeight)

                    NotificationSeparator(orientation: .horizontal, length: Layout.windowWidth)

                    HStack(spacing: 0) {
                        NotificationButton(title: stopTitle, action: onStop)

                        NotificationSeparator(orientation: .vertical, length: Layout.buttonHeight)

                        NotificationButton(title: nextActionTitle, action: onNext)

                        NotificationSeparator(orientation: .vertical, length: Layout.buttonHeight)

                        NotificationButton(title: skipActionTitle, action: onSkip)
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
