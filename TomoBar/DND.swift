import ScriptingBridge
import AppKit
import SwiftUI

@objc protocol ShortcutsEvents {
    @objc optional var shortcuts: SBElementArray { get }
}
@objc protocol Shortcut {
    @objc optional var name: String { get }
    @objc optional func run(withInput: Any?) -> Any?
}

extension SBApplication: ShortcutsEvents {}
extension SBObject: Shortcut {}

class TBDoNotDisturb: ObservableObject {
    var currentFocusState: Bool = false

    func set(focus: Bool, completion: ((Bool) -> Void)? = nil) {
        DispatchQueue.main.async { [self] in
            let result = updateFocusMode(focus: focus)
            completion?(result)
        }
    }

    func setImmediate(focus: Bool) -> Bool {
        return updateFocusMode(focus: focus)
    }

    private func updateFocusMode(focus: Bool) -> Bool {
        if currentFocusState == focus {
            return true
        }

        guard
            let app: ShortcutsEvents = SBApplication(bundleIdentifier: "com.apple.shortcuts.events"),
            let shortcuts = app.shortcuts else {
            fatalError("Couldn't access shortcuts")
        }

        guard
            let shortcut = shortcuts.object(withName: "macos-focus-mode") as? Shortcut,
            shortcut.name == "macos-focus-mode" else {
            if let shortcutURL = Bundle.main.url(forResource: "macos-focus-mode", withExtension: "shortcut") {
                NSWorkspace.shared.open(shortcutURL)
            }
            return false
        }

        let input = focus ? "on" : "off"
        _ = shortcut.run?(withInput: input)
        currentFocusState = focus

        return true
    }
}
