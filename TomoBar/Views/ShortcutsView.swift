import KeyboardShortcuts
import SwiftUI

extension KeyboardShortcuts.Name {
    static let startStopTimer = Self("startStopTimer")
    static let pauseResumeTimer = Self("pauseResumeTimer")
    static let skipTimer = Self("skipTimer")
    static let addMinuteTimer = Self("addMinuteTimer")
    static let addFiveMinutesTimer = Self("addFiveMinutesTimer")
}

struct ShortcutsView: View {
    var body: some View {
        VStack {
            KeyboardShortcuts.Recorder(for: .startStopTimer) {
                Text(NSLocalizedString("SettingsView.shortcut.label",
                                       comment: "Shortcut label"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            KeyboardShortcuts.Recorder(for: .pauseResumeTimer) {
                Text(NSLocalizedString("SettingsView.pauseShortcut.label",
                                       comment: "Pause shortcut label"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            KeyboardShortcuts.Recorder(for: .skipTimer) {
                Text(NSLocalizedString("SettingsView.skipShortcut.label",
                                       comment: "Skip shortcut label"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            KeyboardShortcuts.Recorder(for: .addMinuteTimer) {
                Text(NSLocalizedString("SettingsView.addMinuteShortcut.label",
                                       comment: "Add a minute label"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            KeyboardShortcuts.Recorder(for: .addFiveMinutesTimer) {
                Text(NSLocalizedString("SettingsView.addFiveMinutesShortcut.label",
                                       comment: "Add five minutes label"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Spacer().frame(minHeight: 0)
        }
        .padding(4)
    }
}
