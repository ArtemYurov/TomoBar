import ScriptingBridge
import Cocoa

@objc protocol ShortcutsEvents {
    @objc optional var shortcuts: SBElementArray { get }
}
@objc protocol Shortcut {
    @objc optional var name: String { get }
    @objc optional func run(withInput: Any?) -> Any?
}

extension SBApplication: ShortcutsEvents {}
extension SBObject: Shortcut {}

class DoNotDisturbHelper {
    var currentState: Bool = false

    static let shared = DoNotDisturbHelper()

    private init() {}

    func set(state: Bool) -> Bool {
        if currentState == state {
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

        let input = state ? "on" : "off"
        _ = shortcut.run?(withInput: input)
        currentState = state

        return true
    }
}