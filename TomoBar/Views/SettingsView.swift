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
                    .frameInfinityLeading()
                EnumSegmentedPicker(value: $timer.showTimerMode)
            }
            .onChange(of: timer.showTimerMode) { _ in
                timer.updateDisplay()
            }
            if timer.showTimerMode != .disabled {
                HStack {
                    Text(NSLocalizedString("SettingsView.timer.font.label",
                                           comment: "Timer font label"))
                        .frameInfinityLeading()
                    EnumSegmentedPicker(value: $timer.timerFontMode)
                }
                .onChange(of: timer.timerFontMode) { _ in
                    timer.updateDisplay()
                }
                Stepper(value: $timer.grayBackgroundOpacity, in: 0 ... 10) {
                    HStack {
                        Text(NSLocalizedString("SettingsView.timer.grayBackground.label",
                                               comment: "Gray background label"))
                            .frameInfinityLeading()
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
                    .frameInfinityLeading()
                EnumSegmentedPicker(value: $timer.alertMode)
            }
            switch timer.alertMode {
            case .notify:
                HStack {
                    Text(NSLocalizedString("SettingsView.alert.notifyStyle.label",
                                           comment: "Notify style label"))
                        .frameInfinityLeading()
                    EnumSegmentedPicker(value: $timer.notifyStyle)
                }
                .onChange(of: timer.notifyStyle) { newValue in
                    if newValue == .notifySystem {
                        timer.notify.system.needsPermission { needed in
                            if needed {
                                TBStatusItem.shared.closePopover(nil)
                                timer.notify.system.requestPermission()
                            }
                        }
                    }
                    timer.notify.preview()
                }
                if timer.notifyStyle == .small || timer.notifyStyle == .big {
                    Stepper(value: $timer.customBackgroundOpacity, in: 3 ... 10) {
                        HStack {
                            Text(NSLocalizedString("SettingsView.timer.backgroundOpacity.label",
                                                   comment: "Custom notification background label"))
                                .frameInfinityLeading()
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
                        .frameInfinityLeading()
                }
                .toggleStyle(.switch)
                Toggle(isOn: $timer.maskBlockActions) {
                    Text(NSLocalizedString("SettingsView.alert.maskMode.blockActions.label",
                                           comment: "Block actions label"))
                        .frameInfinityLeading()
                }.toggleStyle(.switch)
            case .disabled:
                EmptyView()
            }
            Toggle(isOn: $timer.startTimerOnLaunch) {
                Text(NSLocalizedString("SettingsView.app.startTimerOnLaunch.label",
                                       comment: "Start timer on launch label"))
                    .frameInfinityLeading()
            }.toggleStyle(.switch)
            Toggle(isOn: $launchAtLogin.isEnabled) {
                Text(NSLocalizedString("SettingsView.app.launchAtLogin.label",
                                       comment: "Launch at login label"))
                    .frameInfinityLeading()
            }.toggleStyle(.switch)
            HStack {
                Text(NSLocalizedString("SettingsView.app.language.label",
                                       comment: "Language label"))
                    .frameInfinityLeading()
                Picker("", selection: $timer.appLanguage) {
                    ForEach(getAvailableLanguages(), id: \.self) { languageCode in
                        Text(getLanguageName(for: languageCode))
                            .tag(languageCode)
                    }
                }
                .labelsHidden()
            }
            .onChange(of: timer.appLanguage) { newValue in
                LocalizationManager.shared.applyLanguageSettings(for: newValue)
                LocalizationManager.shared.showRestartAlert()
            }
            Spacer().frame(minHeight: 0)
        }
        .padding(4)
    }
}
