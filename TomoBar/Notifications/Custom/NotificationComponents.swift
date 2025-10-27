import AppKit
import SwiftUI

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
