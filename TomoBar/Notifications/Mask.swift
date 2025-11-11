import AppKit
import Carbon.HIToolbox
import Foundation
import SwiftUI

class MaskHelper {
    @AppStorage("maskBlockActions") var maskBlockActions = false
    @AppStorage("maskAutoResumeWork") var maskAutoResumeWork = false

    var windowControllers = [NSWindowController]()
    let skipEventHandler: () -> Void
    let userChoiceHandler: (UserChoiceAction) -> Void
    private var keyboardMonitor: Any?
    private var windowMonitorTimer: Timer?
    private var appDeactivateObserver: Any?

    init(skipHandler: @escaping () -> Void, userChoiceHandler: @escaping (UserChoiceAction) -> Void) {
        self.skipEventHandler = skipHandler
        self.userChoiceHandler = userChoiceHandler
    }

    func show(isLong: Bool, blockActions: Bool = false) {
        let desc = isLong
            ? NSLocalizedString("MaskNotification.restStarted.longBreak.title", comment: "Long break started")
            : NSLocalizedString("MaskNotification.restStarted.shortBreak.title", comment: "Short break started")

        createMaskWindows(desc: desc, blockActions: blockActions, requiresRestFinishedConfirmation: false)
    }

    func showRestFinished(state: TBStateMachineStates) {
        if !windowControllers.isEmpty {
            // Update existing windows instead of recreating
            updateForRestFinished(state: state)
        } else {
            // Fallback: create new windows if none exist
            let desc = state == .longRest
                ? NSLocalizedString("MaskNotification.restFinished.longBreak.title", comment: "Long break finished")
                : NSLocalizedString("MaskNotification.restFinished.shortBreak.title", comment: "Short break finished")
            createMaskWindows(desc: desc, blockActions: false, requiresRestFinishedConfirmation: !maskAutoResumeWork)
        }
    }

    private func createMaskWindows(desc: String, blockActions: Bool, requiresRestFinishedConfirmation: Bool) {
        let screens = NSScreen.screens
        for screen in screens {
            let window = NSWindow(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: true)
            window.level = .screenSaver
            window.collectionBehavior = .canJoinAllSpaces
            window.backgroundColor = NSColor.black.withAlphaComponent(0.2)
            let maskView = MaskView(
                desc: desc,
                blockActions: blockActions,
                requiresRestFinishedConfirmation: requiresRestFinishedConfirmation,
                frame: window.contentLayoutRect,
                hideHandler: hide,
                skipHandler: skipEventHandler,
                userChoiceHandler: userChoiceHandler,
                onAnimationComplete: { [weak self] in
                    if let windowControllers = self?.windowControllers, windowControllers.isEmpty == false {
                        for windowController in windowControllers {
                            windowController.close()
                        }
                        self?.windowControllers.removeAll()
                    }
                }
            )
            window.contentView = maskView

            let windowController = NSWindowController(window: window)
            windowController.window?.orderFront(nil)
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
        for windowController in windowControllers {
            guard let mask = windowController.window?.contentView as? MaskView else { continue }
            mask.updateTimeLeft(timeString)
        }
    }

    private func updateForRestFinished(state: TBStateMachineStates) {
        let desc = state == .longRest
            ? NSLocalizedString("MaskNotification.restFinished.longBreak.title", comment: "Long break finished")
            : NSLocalizedString("MaskNotification.restFinished.shortBreak.title", comment: "Short break finished")

        for windowController in windowControllers {
            guard let mask = windowController.window?.contentView as? MaskView else { continue }
            mask.updateForRestFinished(title: desc)
        }
    }

    func hide() {
        uninstallKeyboardMonitor()
        stopWindowMonitoring()

        for windowController in windowControllers {
            guard let mask = windowController.window?.contentView as? MaskView else { continue }
            mask.hide()
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
        for windowController in windowControllers {
            windowController.window?.orderFront(nil)
            windowController.window?.level = .screenSaver
        }

        NSApp.unhide(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

class MaskView: NSView {
    var onAnimationComplete: (() -> Void)?
    private var hideHandler: (() -> Void)?
    private var skipHandler: (() -> Void)?
    private var userChoiceHandler: ((UserChoiceAction) -> Void)?
    private var clickTimer: Timer?
    private var blockActions: Bool = false
    private var requiresRestFinishedConfirmation: Bool = false

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
        let text = requiresRestFinishedConfirmation
            ? NSLocalizedString("MaskNotification.restFinished.instruction", comment: "Rest finished instruction")
            : NSLocalizedString("MaskNotification.restStarted.instruction", comment: "Rest started instruction")
        let tipLabel = NSTextField(labelWithString: text)
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

    init(desc: String, blockActions: Bool = false, requiresRestFinishedConfirmation: Bool = false, frame: NSRect,
         hideHandler: @escaping () -> Void,
         skipHandler: @escaping () -> Void,
         userChoiceHandler: @escaping (UserChoiceAction) -> Void,
         onAnimationComplete: (() -> Void)? = nil) {
        self.onAnimationComplete = onAnimationComplete
        self.hideHandler = hideHandler
        self.skipHandler = skipHandler
        self.userChoiceHandler = userChoiceHandler
        self.blockActions = blockActions
        self.requiresRestFinishedConfirmation = requiresRestFinishedConfirmation
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

        // Hide timer when waiting for confirmation (after rest)
        if !requiresRestFinishedConfirmation {
            addSubview(timeLeftLabel)
        }

        // Show tip only if not blockActions
        if !blockActions {
            addSubview(tipLabel)
        }
    }

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)

        if blockActions {
            return
        }

        if requiresRestFinishedConfirmation {
            handleInteractiveClick(event)
        } else {
            handleNormalClick(event)
        }
    }

    private func handleInteractiveClick(_ event: NSEvent) {
        if event.clickCount == 1 {
            clickTimer?.invalidate()
            clickTimer = Timer.scheduledTimer(withTimeInterval: NSEvent.doubleClickInterval, repeats: false) { _ in
                self.userChoiceHandler?(.next)
            }
        } else if event.clickCount == 2 {
            clickTimer?.invalidate()
            self.userChoiceHandler?(.skip)
        }
    }

    private func handleNormalClick(_ event: NSEvent) {
        if event.clickCount == 1 {
            clickTimer?.invalidate()
            clickTimer = Timer.scheduledTimer(withTimeInterval: NSEvent.doubleClickInterval, repeats: false) { _ in
                self.hideHandler?()
            }
        } else if event.clickCount == 2 {
            clickTimer?.invalidate()
            self.hideHandler?()
            self.skipHandler?()
        }
    }

    public func updateTimeLeft(_ timeString: String) {
        timeLeftLabel.stringValue = timeString
    }

    public func updateForRestFinished(title: String) {
        // Update title
        titleLabel.stringValue = title

        // Update instruction
        let newTipText = NSLocalizedString("MaskNotification.restFinished.instruction", comment: "Rest finished instruction")
        tipLabel.stringValue = newTipText

        // Hide timer (not needed for confirmation)
        timeLeftLabel.removeFromSuperview()

        // Show tip if not already visible
        if !subviews.contains(tipLabel) {
            addSubview(tipLabel)
        }

        // Update click behavior
        requiresRestFinishedConfirmation = true
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
