import KeyboardShortcuts
import SwiftUI

struct ControlsView: View {
    @EnvironmentObject var timer: TBTimer

    var body: some View {
        VStack {
            HStack {
                Text(NSLocalizedString("SettingsView.controls.rightclick.long.label",
                                       comment: "Icon long right click label"))
                    .frameInfinityLeading()
                RightClickActionPicker(value: $timer.longRightClickAction)
            }
            HStack {
                Text(NSLocalizedString("SettingsView.controls.rightclick.label",
                                       comment: "Icon right click label"))
                    .frameInfinityLeading()
                RightClickActionPicker(value: $timer.rightClickAction)
            }
            KeyboardShortcuts.Recorder(for: .startStopTimer) {
                Text(NSLocalizedString("SettingsView.controls.shortcuts.startStop.label",
                                       comment: "Start/stop shortcut label"))
                    .frameInfinityLeading()
            }
            KeyboardShortcuts.Recorder(for: .pauseResumeTimer) {
                Text(NSLocalizedString("SettingsView.controls.shortcuts.pauseResume.label",
                                       comment: "Pause/resume shortcut label"))
                    .frameInfinityLeading()
            }
            KeyboardShortcuts.Recorder(for: .addMinuteTimer) {
                Text(NSLocalizedString("SettingsView.controls.shortcuts.addMinute.label",
                                       comment: "Add a minute shortcut label"))
                    .frameInfinityLeading()
            }
            KeyboardShortcuts.Recorder(for: .addFiveMinutesTimer) {
                Text(NSLocalizedString("SettingsView.controls.shortcuts.addFiveMinutes.label",
                                       comment: "Add five minutes shortcut label"))
                    .frameInfinityLeading()
            }
            KeyboardShortcuts.Recorder(for: .skipTimer) {
                Text(NSLocalizedString("SettingsView.controls.shortcuts.skipInterval.label",
                                       comment: "Skip interval shortcut label"))
                    .frameInfinityLeading()
            }
            Spacer().frame(minHeight: 0)
        }
        .padding(4)
    }
}
