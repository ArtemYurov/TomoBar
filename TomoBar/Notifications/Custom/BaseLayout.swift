import Foundation
import CoreGraphics

enum BaseLayout {
    // Element sizes
    static let titleFontSize: CGFloat = 14
    static let subtitleFontSize: CGFloat = 12
    static let buttonFontSize: CGFloat = 13
    static let buttonHeight: CGFloat = 36

    // Colors and transparency
    static let separatorOpacity: CGFloat = 0.3
    static let backgroundOpacity: CGFloat = 0.7

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
