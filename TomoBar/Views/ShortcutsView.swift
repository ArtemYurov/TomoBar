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
                Text(NSLocalizedString("SettingsView.shortcuts.startStop.label",
                                       comment: "Shortcut label"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            KeyboardShortcuts.Recorder(for: .pauseResumeTimer) {
                Text(NSLocalizedString("SettingsView.shortcuts.pauseResume.label",
                                       comment: "Pause shortcut label"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            KeyboardShortcuts.Recorder(for: .skipTimer) {
                Text(NSLocalizedString("SettingsView.shortcuts.skip.label",
                                       comment: "Skip shortcut label"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            KeyboardShortcuts.Recorder(for: .addMinuteTimer) {
                Text(NSLocalizedString("SettingsView.shortcuts.addMinute.label",
                                       comment: "Add a minute label"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            KeyboardShortcuts.Recorder(for: .addFiveMinutesTimer) {
                Text(NSLocalizedString("SettingsView.shortcuts.addFiveMinutes.label",
                                       comment: "Add five minutes label"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Spacer().frame(minHeight: 0)
        }
        .padding(4)
    }
}
