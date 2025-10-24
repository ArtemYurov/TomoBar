
import AppKit
import Carbon.HIToolbox

class MaskHelper {
    var windowControllers = [NSWindowController]()
    var skipHandler: (() -> Void)?
    private var keyboardMonitor: Any?
    private var windowMonitorTimer: Timer?
    private var appDeactivateObserver: Any?

    static let shared = MaskHelper()

    private init() {}

    func setSkipHandler(_ handler: @escaping () -> Void) {
        skipHandler = handler
    }

    func show(desc: String, blockActions: Bool = false) {
        let screens = NSScreen.screens
        for screen in screens {
            let window = NSWindow(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: true)
            window.level = .screenSaver
            window.collectionBehavior = .canJoinAllSpaces
            window.backgroundColor = NSColor.black.withAlphaComponent(0.2)
            let maskView = MaskView(desc: desc, blockActions: blockActions, frame: window.contentLayoutRect) { [weak self] in
                if let windowControllers = self?.windowControllers, windowControllers.isEmpty == false {
                    for wc in windowControllers {
                        wc.close()
                    }
                    self?.windowControllers.removeAll()
                }
            }
            window.contentView = maskView

            let windowController = NSWindowController(window: window)
            windowController.loadWindow()
            windowController.showWindow(nil)
            windowControllers.append(windowController)
            maskView.show()
            NSApp.activate(ignoringOtherApps: true)
        }

        if blockActions {
            installKeyboardMonitor()
            startWindowMonitoring()
        }
    }

    func updateTimeLeft(_ timeString: String) {
        for wc in windowControllers {
            guard let mask = wc.window?.contentView as? MaskView else { continue }
            mask.updateTimeLeft(timeString)
        }
    }

    func hide(skip: Bool = false) {
        uninstallKeyboardMonitor()
        stopWindowMonitoring()

        for wc in windowControllers {
            guard let mask = wc.window?.contentView as? MaskView else { continue }
            mask.hide()
        }
        if skip {
            self.skipHandler?()
        }
    }

    private func installKeyboardMonitor() {
        keyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.modifierFlags.contains(.command) {
                let keyCode = event.keyCode

                // CMD+Q
                if keyCode == kVK_ANSI_Q {
                    return nil
                }

                // CMD+W
                if keyCode == kVK_ANSI_W {
                    return nil
                }

                // CMD+H
                if keyCode == kVK_ANSI_H {
                    return nil
                }

                // CMD+M
                if keyCode == kVK_ANSI_M {
                    return nil
                }

                // CMD+Tab
                if keyCode == kVK_Tab {
                    return nil
                }
            }

            return event
        }
    }

    private func uninstallKeyboardMonitor() {
        if let monitor = keyboardMonitor {
            NSEvent.removeMonitor(monitor)
            keyboardMonitor = nil
        }
    }

    private func startWindowMonitoring() {
        appDeactivateObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.bringWindowsToFront()
        }

        windowMonitorTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] _ in
            self?.bringWindowsToFront()
        }
    }

    private func stopWindowMonitoring() {
        if let observer = appDeactivateObserver {
            NotificationCenter.default.removeObserver(observer)
            appDeactivateObserver = nil
        }

        windowMonitorTimer?.invalidate()
        windowMonitorTimer = nil
    }

    private func bringWindowsToFront() {
        for wc in windowControllers {
            wc.window?.makeKeyAndOrderFront(nil)
            wc.window?.level = .screenSaver
        }

        NSApp.unhide(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

class MaskView: NSView {
    var onAnimationComplete: (() -> Void)? = nil
    private var clickTimer: Timer?
    private var blockActions: Bool = false

    lazy var titleLabel = {
        let titleLabel = NSTextField(labelWithString: "")
        titleLabel.textColor = .white.withAlphaComponent(0.8)
        titleLabel.font = NSFont.boldSystemFont(ofSize: 28)
        titleLabel.alignment = .center
        titleLabel.frame = CGRect(x: 0, y: self.bounds.midY - 30, width: self.bounds.width, height: 50)
        return titleLabel
    }()

    lazy var timeLeftLabel = {
        let timeLeftLabel = NSTextField(labelWithString: "")
        timeLeftLabel.textColor = .white.withAlphaComponent(0.9)
        timeLeftLabel.font = NSFont.monospacedSystemFont(ofSize: 48, weight: .medium)
        timeLeftLabel.alignment = .center
        timeLeftLabel.frame = CGRect(x: 0, y: self.bounds.midY - 90, width: self.bounds.width, height: 60)
        return timeLeftLabel
    }()

    lazy var tipLabel = {
        let tipLabel = NSTextField(labelWithString: NSLocalizedString("TBMask.skip.label", comment: "Skip label"))
        tipLabel.textColor = .white.withAlphaComponent(0.8)
        tipLabel.font = NSFont.systemFont(ofSize: 18)
        tipLabel.alignment = .center
        tipLabel.frame = CGRect(x: 0, y: self.bounds.midY, width: self.bounds.width, height: 50)
        return tipLabel
    }()

    lazy var blurEffect = {
        let blurEffect = NSVisualEffectView(frame: self.bounds)
        blurEffect.alphaValue = 0.9
        blurEffect.appearance = NSAppearance(named: .vibrantDark)
        blurEffect.blendingMode = .behindWindow
        blurEffect.state = .inactive
        return blurEffect
    }()

    init(desc: String, blockActions: Bool = false, frame: NSRect, onAnimationComplete: (() -> Void)? = nil) {
        self.onAnimationComplete = onAnimationComplete
        self.blockActions = blockActions
        super.init(frame: frame)
        self.wantsLayer = true
        layer?.backgroundColor = NSColor.black.withAlphaComponent(0.3).cgColor
        titleLabel.stringValue = desc
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        addSubview(blurEffect)
        addSubview(titleLabel)
        addSubview(timeLeftLabel)
        if !blockActions {
            addSubview(tipLabel)
        }
    }

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)

        if blockActions {
            return
        }

        if event.clickCount == 1 {
            clickTimer?.invalidate()
            clickTimer = Timer.scheduledTimer(withTimeInterval: NSEvent.doubleClickInterval, repeats: false) { _ in
                MaskHelper.shared.hide()
            }
        }
        else if event.clickCount == 2 {
            clickTimer?.invalidate()
            MaskHelper.shared.hide(skip: true)
        }
    }

    public func updateTimeLeft(_ timeString: String) {
        timeLeftLabel.stringValue = timeString
    }

    public func show() {
        layer?.removeAllAnimations()
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 0
        animation.toValue = 1
        animation.duration = 1.0
        layer?.add(animation, forKey: "opacity")
    }

    public func hide() {
        layer?.removeAllAnimations()
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 1
        animation.toValue = 0
        animation.duration = 0.25
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        animation.delegate = self
        layer?.add(animation, forKey: "opacity")
    }
}

extension MaskView: CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        onAnimationComplete?()
    }
}
