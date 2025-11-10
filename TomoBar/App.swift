import SwiftUI
import LaunchAtLogin
import Sparkle

extension NSImage.Name {
    static let idle = Self("BarIconIdle")
    static let work = Self("BarIconWork")
    static let shortRest = Self("BarIconShortRest")
    static let longRest = Self("BarIconLongRest")
    static let pause = Self("BarIconPause")
}

private enum UIConstants {
    static let fontSizeIncrement: CGFloat = 2
    static let ptMonoFontName = "PT Mono"
    static let ptMonoFontSizeIncrement: CGFloat = 1
    static let sfMonoFontName = "SF Mono"
    static let sfMonoFontSizeIncrement: CGFloat = 1
    static let buttonCornerRadius: CGFloat = 4
    static let grayBackgroundMaxAlpha: CGFloat = 10.0  // Divider for opacity calculation
}

@main
struct TBApp: App {
    @NSApplicationDelegateAdaptor(TBStatusItem.self) var appDelegate

    init() {
        TBStatusItem.shared = appDelegate
        LaunchAtLogin.migrateIfNeeded()
        logger.append(event: TBLogEventAppStart())
    }

    var body: some Scene {
        Settings {}
    }
}

class TBStatusItem: NSObject, NSApplicationDelegate {
    private var popover = NSPopover()
    var statusBarItem: NSStatusItem?
    static var shared: TBStatusItem!
    private var view: TBPopoverView!
    private let updaterController: SPUStandardUpdaterController
    private let userDriverDelegate = TBStatusItemUserDriverDelegate()

    // Read display settings directly from AppStorage
    @AppStorage("timerFontMode") private var timerFontMode = TimerFontMode.fontSystem
    @AppStorage("grayBackgroundOpacity") private var grayBackgroundOpacity = 0

    override init() {
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: userDriverDelegate)
        super.init()
    }

    func applicationDidFinishLaunching(_: Notification) {
        view = TBPopoverView()

        popover.behavior = .transient
        popover.contentViewController = NSViewController()
        popover.contentViewController?.view = NSHostingView(rootView: view)
        if let contentViewController = popover.contentViewController {
            popover.contentSize.height = contentViewController.view.intrinsicContentSize.height
            popover.contentSize.width = contentViewController.view.intrinsicContentSize.width
        }

        statusBarItem = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.variableLength
        )
        statusBarItem?.button?.imagePosition = .imageLeft
        statusBarItem?.button?.wantsLayer = true
        statusBarItem?.button?.layer?.cornerRadius = UIConstants.buttonCornerRadius
        setIcon(name: .idle)
        statusBarItem?.button?.action = #selector(TBStatusItem.togglePopover(_:))
        view.timer.updateDisplay()
        view.timer.startOnLaunch()
    }

    func applicationWillTerminate(_: Notification) {
        _ = view.timer.dnd.setImmediate(focus: false)
    }

    func setTitle(title: String?) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = NSTextAlignment.center

        let font: NSFont
        switch timerFontMode {
        case .fontSystem:
            // System monospaced digit font
            font = NSFont.monospacedDigitSystemFont(ofSize: 0, weight: .regular)
        case .ptMono:
            // PT Mono font
            let fontSize = NSFont.systemFontSize + UIConstants.ptMonoFontSizeIncrement
            font = NSFont(name: UIConstants.ptMonoFontName, size: fontSize) ?? NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        case .sfMono:
            // SF Mono font
            let fontSize = NSFont.systemFontSize + UIConstants.sfMonoFontSizeIncrement
            font = NSFont(name: UIConstants.sfMonoFontName, size: fontSize) ?? NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        }

        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
            NSAttributedString.Key.baselineOffset: 0
        ]

        // Update button background: only show gray background when title is shown
        if title == nil || grayBackgroundOpacity == 0 {
            statusBarItem?.button?.layer?.backgroundColor = NSColor.clear.cgColor
        } else {
            let alpha = CGFloat(grayBackgroundOpacity) / UIConstants.grayBackgroundMaxAlpha  // Convert 0-10 to 0.0-1.0
            statusBarItem?.button?.layer?.backgroundColor = NSColor.systemGray.withAlphaComponent(alpha).cgColor
        }

        let attributedTitle = NSAttributedString(
            string: title != nil ? " \(title!)" : "",
            attributes: attributes
        )
        statusBarItem?.button?.attributedTitle = attributedTitle
    }

    func setIcon(name: NSImage.Name) {
        statusBarItem?.button?.image = NSImage(named: name)
    }

    func showPopover(_: AnyObject?) {
        if let button = statusBarItem?.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            popover.contentViewController?.view.window?.makeKey()
            NSApp.keyWindow?.makeFirstResponder(nil)
        }
    }

    func closePopover(_ sender: AnyObject?) {
        popover.performClose(sender)
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        if popover.isShown {
            closePopover(sender)
        } else {
            showPopover(sender)
        }
    }

    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }
}

class TBStatusItemUserDriverDelegate: NSObject, SPUStandardUserDriverDelegate {
    var supportsGentleScheduledUpdateReminders: Bool {
        return true
    }
}
