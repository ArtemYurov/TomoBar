import LaunchAtLogin
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var timer: TBTimer
    @ObservedObject private var launchAtLogin = LaunchAtLogin.observable

    var body: some View {
        VStack {
            HStack {
                Text(NSLocalizedString("SettingsView.timer.show.label",
                                       comment: "Show timer label"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                StartStopDropdown(value: $timer.showTimerMode)
            }
            .onChange(of: timer.showTimerMode) { _ in
                timer.updateDisplay()
            }
            if timer.showTimerMode != .disabled {
                HStack {
                    Text(NSLocalizedString("SettingsView.timer.font.label",
                                           comment: "Timer font label"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    StartStopDropdown(value: $timer.timerFontMode)
                }
                .onChange(of: timer.timerFontMode) { _ in
                    timer.updateDisplay()
                }
                Stepper(value: $timer.grayBackgroundOpacity, in: 0 ... 10) {
                    HStack {
                        Text(NSLocalizedString("SettingsView.timer.grayBackground.label",
                                               comment: "Gray background label"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        TextField("", value: $timer.grayBackgroundOpacity, formatter: clampedNumberFormatter(min: 0, max: 10))
                            .frame(width: 36, alignment: .trailing)
                            .multilineTextAlignment(.trailing)
                    }
                }
                .onChange(of: timer.grayBackgroundOpacity) { _ in
                    timer.updateDisplay()
                }
            }
            HStack {
                Text(NSLocalizedString("SettingsView.alert.mode.label",
                                       comment: "Alert mode label"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                StartStopDropdown(value: $timer.alertMode)
            }
            .onChange(of: timer.alertMode) { _ in
                timer.notify.preview()
            }
            switch timer.alertMode {
            case .notify:
                HStack {
                    Text(NSLocalizedString("SettingsView.alert.notifyStyle.label",
                                           comment: "Notify style label"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    StartStopDropdown(value: $timer.notifyStyle)
                }
                .onChange(of: timer.notifyStyle) { _ in
                    timer.notify.preview()
                }
                if timer.notifyStyle == .small || timer.notifyStyle == .big {
                    Stepper(value: $timer.customBackgroundOpacity, in: 3 ... 10) {
                        HStack {
                            Text(NSLocalizedString("SettingsView.timer.backgroundOpacity.label",
                                                   comment: "Custom notification background label"))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            TextField("", value: $timer.customBackgroundOpacity, formatter: clampedNumberFormatter(min: 3, max: 10))
                                .frame(width: 36, alignment: .trailing)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    .onChange(of: timer.customBackgroundOpacity) { _ in
                        timer.notify.preview()
                    }
                }
            case .fullScreen:
                Toggle(isOn: $timer.maskAutoResumeWork) {
                    Text(NSLocalizedString("SettingsView.alert.autoResumeWork.label",
                                           comment: "Resume work automatically label"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .toggleStyle(.switch)
                HStack {
                    Text(NSLocalizedString("SettingsView.alert.maskMode.label",
                                           comment: "Mask mode label"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    StartStopDropdown(value: $timer.maskMode)
                }
            case .disabled:
                EmptyView()
            }
            Toggle(isOn: $timer.startTimerOnLaunch) {
                Text(NSLocalizedString("SettingsView.app.startTimerOnLaunch.label",
                                       comment: "Start timer on launch label"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }.toggleStyle(.switch)
            Toggle(isOn: $launchAtLogin.isEnabled) {
                Text(NSLocalizedString("SettingsView.app.launchAtLogin.label",
                                       comment: "Launch at login label"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }.toggleStyle(.switch)
            #if DEBUG
            Toggle(isOn: $timer.useSecondsInsteadOfMinutes) {
                Text("Use sec instead of min (for testing)")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .toggleStyle(.switch)
            .onChange(of: timer.useSecondsInsteadOfMinutes) { _ in
                timer.updateDisplay()
            }
            #endif
            Spacer().frame(minHeight: 0)
        }
        .padding(4)
    }
}
