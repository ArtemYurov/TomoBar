import Foundation
import AppKit

class LocalizationManager {
    static let shared = LocalizationManager()

    private init() {}

    func applyLanguageSettings(for language: String) {
        if language == "system" {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.set([language], forKey: "AppleLanguages")
        }
        UserDefaults.standard.synchronize()
    }

    func showRestartAlert() {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("SettingsView.language.restart.title",
                                             comment: "Restart required title")
        alert.informativeText = NSLocalizedString("SettingsView.language.restart.message",
                                                  comment: "Restart required message")

        alert.addButton(withTitle: NSLocalizedString("SettingsView.language.restart.restart",
                                                     comment: "Restart button"))
        alert.addButton(withTitle: NSLocalizedString("SettingsView.language.restart.later",
                                                     comment: "Later button"))
        alert.alertStyle = .critical

        let alertRestartButtonReturn: NSApplication.ModalResponse = .alertFirstButtonReturn

        if alert.runModal() == alertRestartButtonReturn {
            restartApplication()
        }
    }

    private func restartApplication() {
        let bundlePath = Bundle.main.bundlePath

        // Save all data before restart
        UserDefaults.standard.synchronize()

        // Use Process with shell command for restart.
        // NSWorkspace.openApplication DOES NOT work if the app is already running -
        // it just returns a reference to the existing process.
        // Therefore, we use a separate shell process that waits for the current
        // app to terminate (sleep 0.5) and then launches a new instance (open).
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/sh")
        task.arguments = ["-c", "sleep 0.5; open \"\(bundlePath)\""]

        do {
            try task.run()
            // Immediately terminate the app
            exit(0)
        } catch {
            print("Failed to relaunch: \(error)")
            // Fallback: at least terminate the app
            NSApplication.shared.terminate(nil)
        }
    }
}
