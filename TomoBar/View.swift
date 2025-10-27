import KeyboardShortcuts
import LaunchAtLogin
import SwiftUI

extension KeyboardShortcuts.Name {
    static let startStopTimer = Self("startStopTimer")
    static let pauseResumeTimer = Self("pauseResumeTimer")
    static let skipTimer = Self("skipTimer")
    static let addMinuteTimer = Self("addMinuteTimer")
    static let addFiveMinutesTimer = Self("addFiveMinutesTimer")
}

private func ClampedNumberFormatter(min: Int, max: Int) -> NumberFormatter {
    let formatter = NumberFormatter()
    formatter.minimum = NSNumber(value: min)
    formatter.maximum = NSNumber(value: max)
    formatter.generatesDecimalNumbers = false
    formatter.maximumFractionDigits = 0
    return formatter
}

private struct IntervalsView: View {
    @EnvironmentObject var timer: TBTimer
    private var minStr = NSLocalizedString("IntervalsView.min", comment: "min")

    enum IntervalField: Hashable {
        case workIntervalLength
        case shortRestIntervalLength
        case longRestIntervalLength
        case workIntervalsInSet
    }

    @FocusState private var focusedField: IntervalField?

    var body: some View {
        VStack {
            Stepper(value: $timer.currentPresetInstance.workIntervalLength, in: 1 ... 120) {
                HStack {
                    Text(NSLocalizedString("IntervalsView.workIntervalLength.label",
                                           comment: "Work interval label"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    TextField("", value: $timer.currentPresetInstance.workIntervalLength, formatter: ClampedNumberFormatter(min: 1, max: 120))
                        .frame(width: 36, alignment: .trailing)
                        .multilineTextAlignment(.trailing)
                        .focused($focusedField, equals: .workIntervalLength)
                        .onSubmit({ focusedField = .shortRestIntervalLength })
                    Text(minStr)
                }
            }
            .onChange(of: timer.currentPresetInstance.workIntervalLength) { _ in
                timer.adjustTimerDebounced(state: .work)
            }
            Stepper(value: $timer.currentPresetInstance.shortRestIntervalLength, in: 1 ... 120) {
                HStack {
                    Text(NSLocalizedString("IntervalsView.shortRestIntervalLength.label",
                                           comment: "Short rest interval label"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    TextField("", value: $timer.currentPresetInstance.shortRestIntervalLength, formatter: ClampedNumberFormatter(min: 1, max: 120))
                        .frame(width: 36, alignment: .trailing)
                        .multilineTextAlignment(.trailing)
                        .focused($focusedField, equals: .shortRestIntervalLength)
                        .onSubmit({ focusedField = .longRestIntervalLength })
                    Text(minStr)
                }
            }
            .onChange(of: timer.currentPresetInstance.shortRestIntervalLength) { _ in
                timer.adjustTimerDebounced(state: .shortRest)
            }
            Stepper(value: $timer.currentPresetInstance.longRestIntervalLength, in: 1 ... 120) {
                HStack {
                    Text(NSLocalizedString("IntervalsView.longRestIntervalLength.label",
                                           comment: "Long rest interval label"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    TextField("", value: $timer.currentPresetInstance.longRestIntervalLength, formatter: ClampedNumberFormatter(min: 1, max: 120))
                        .frame(width: 36, alignment: .trailing)
                        .multilineTextAlignment(.trailing)
                        .focused($focusedField, equals: .longRestIntervalLength)
                        .onSubmit({ focusedField = .workIntervalsInSet })
                    Text(minStr)
                }
            }
            .help(NSLocalizedString("IntervalsView.longRestIntervalLength.help",
                                    comment: "Long rest interval hint"))
            .onChange(of: timer.currentPresetInstance.longRestIntervalLength) { _ in
                timer.adjustTimerDebounced(state: .longRest)
            }
            Stepper(value: $timer.currentPresetInstance.workIntervalsInSet, in: 1 ... 10) {
                HStack {
                    Text(NSLocalizedString("IntervalsView.workIntervalsInSet.label",
                                           comment: "Work intervals in a set label"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    TextField("", value: $timer.currentPresetInstance.workIntervalsInSet, formatter: ClampedNumberFormatter(min: 1, max: 10))
                        .frame(width: 36, alignment: .trailing)
                        .multilineTextAlignment(.trailing)
                        .focused($focusedField, equals: .workIntervalsInSet)
                        .onSubmit({ focusedField = .workIntervalLength })
                }
            }
            .help(NSLocalizedString("IntervalsView.workIntervalsInSet.help",
                                    comment: "Work intervals in set hint"))
            Spacer().frame(minHeight: 0)
            HStack {
                Text(NSLocalizedString("IntervalsView.presets.label",
                                        comment: "Presets label"))
                .frame(alignment: .leading)
                Spacer()
                Picker("", selection: $timer.currentPreset) {
                    Text("1").tag(0)
                    Text("2").tag(1)
                    Text("3").tag(2)
                    Text("4").tag(3)
                }
                .labelsHidden()
                .frame(maxWidth: 200)
                .pickerStyle(.segmented)
            }
            .onChange(of: timer.currentPreset) { _ in
                timer.updateDisplay()
            }
            Spacer().frame(minHeight: 0)
        }
        .padding(4)
    }
}

protocol DropdownDescribable: RawRepresentable where RawValue == String { }

private struct StartStopDropdown<E: CaseIterable & Hashable & DropdownDescribable>: View where E.RawValue == String, E.AllCases: RandomAccessCollection {
    @Binding var value: E

    var body: some View {
        Picker("", selection: $value) {
            ForEach(E.allCases, id: \.self) { option in
                Text(option.description)
            }
        }
        .labelsHidden()
        .pickerStyle(.segmented)
    }
}

extension DropdownDescribable {
    var description: String {
        switch self.rawValue {
            case "disabled": return NSLocalizedString("SettingsView.dropdownDisabled.label",
                                                  comment: "Disabled label")
            case "work": return NSLocalizedString("SettingsView.dropdownWork.label",
                                                    comment: "Work label")
            case "shortRest": return NSLocalizedString("SettingsView.dropdownBreak.label",
                                                    comment: "Short rest label")
            case "longRest": return NSLocalizedString("SettingsView.dropdownSet.label",
                                                    comment: "Long rest label")
            case "running": return NSLocalizedString("SettingsView.showTimerRunning.label",
                                                    comment: "Show timer running label")
            case "always": return NSLocalizedString("SettingsView.showTimerAlways.label",
                                                    comment: "Show timer always label")
            case "system": return NSLocalizedString("SettingsView.dropdownSystem.label",
                                                    comment: "System label")
            case "ptMono": return NSLocalizedString("SettingsView.dropdownMono.label",
                                                    comment: "PT Mono font label")
            case "sfMono": return NSLocalizedString("SettingsView.dropdownSFMono.label",
                                                    comment: "SF Mono font label")
            case "notify": return NSLocalizedString("SettingsView.alertModeNotify.label",
                                                    comment: "Alert mode notify label")
            case "fullScreen": return NSLocalizedString("SettingsView.alertModeFullScreen.label",
                                                    comment: "Alert mode full-screen label")
            case "small": return NSLocalizedString("SettingsView.notifyStyleSmall.label",
                                                    comment: "Notify style small label")
            case "big": return NSLocalizedString("SettingsView.notifyStyleBig.label",
                                                    comment: "Notify style big label")
            case "normal": return NSLocalizedString("SettingsView.maskModeNormal.label",
                                                    comment: "Mask mode normal label")
            case "blockActions": return NSLocalizedString("SettingsView.maskModeBlockActions.label",
                                                    comment: "Mask mode block actions label")
            default: return self.rawValue.capitalized
        }
    }
}

private struct ShortcutsView: View {
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

private struct SettingsView: View {
    @EnvironmentObject var timer: TBTimer
    @ObservedObject private var launchAtLogin = LaunchAtLogin.observable

    var body: some View {
        VStack {
            HStack {
                Text(NSLocalizedString("SettingsView.startWith.label",
                                        comment: "Start with label"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                StartStopDropdown(value: $timer.startWith)
            }
            .onChange(of: timer.startWith) { _ in
                timer.updateDisplay()
            }
            HStack {
                Text(NSLocalizedString("SettingsView.stopAfter.label",
                                        comment: "Stop session after label"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                StartStopDropdown(value: $timer.sessionStopAfter)
            }
            HStack {
                Text(NSLocalizedString("SettingsView.showTimer.label",
                                        comment: "Show timer label"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                StartStopDropdown(value: $timer.showTimerMode)
            }
            .onChange(of: timer.showTimerMode) { _ in
                timer.updateDisplay()
            }
            if timer.showTimerMode != .disabled {
                HStack {
                    Text(NSLocalizedString("SettingsView.timerFont.label",
                                            comment: "Timer font label"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    StartStopDropdown(value: $timer.timerFontMode)
                }
                .onChange(of: timer.timerFontMode) { _ in
                    timer.updateDisplay()
                }
                Stepper(value: $timer.grayBackgroundOpacity, in: 0 ... 10) {
                    HStack {
                        Text(NSLocalizedString("SettingsView.grayBackground.label",
                                               comment: "Gray background label"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        TextField("", value: $timer.grayBackgroundOpacity, formatter: ClampedNumberFormatter(min: 0, max: 10))
                            .frame(width: 36, alignment: .trailing)
                            .multilineTextAlignment(.trailing)
                    }
                }
                .onChange(of: timer.grayBackgroundOpacity) { _ in
                    timer.updateDisplay()
                }
            }
            HStack {
                Text(NSLocalizedString("SettingsView.alertMode.label",
                                        comment: "Alert mode label"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                StartStopDropdown(value: $timer.notify.alertMode)
            }
            if timer.notify.alertMode == .notify {
                HStack {
                    Text(NSLocalizedString("SettingsView.notifyStyle.label",
                                            comment: "Notify style label"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    StartStopDropdown(value: $timer.notify.notifyStyle)
                }
            }
            if timer.notify.alertMode == .fullScreen {
                HStack {
                    Text(NSLocalizedString("SettingsView.maskMode.label",
                                            comment: "Mask mode label"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    StartStopDropdown(value: $timer.notify.maskMode)
                }
            }
            Toggle(isOn: $timer.dnd.toggleDoNotDisturb) {
                Text(NSLocalizedString("SettingsView.toggleDoNotDisturb.label",
                                       comment: "Toggle Do Not Disturb"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .toggleStyle(.switch)
            .help(NSLocalizedString("SettingsView.toggleDoNotDisturb.help",
                                    comment: "Toggle Do Not Disturb hint"))
            Toggle(isOn: $timer.startTimerOnLaunch) {
                Text(NSLocalizedString("SettingsView.startTimerOnLaunch.label",
                                       comment: "Start timer on launch label"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }.toggleStyle(.switch)
            Toggle(isOn: $launchAtLogin.isEnabled) {
                Text(NSLocalizedString("SettingsView.launchAtLogin.label",
                                       comment: "Launch at login label"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }.toggleStyle(.switch)
            Spacer().frame(minHeight: 0)
        }
        .padding(4)
    }
}

private struct VolumeSlider: View {
    @Binding var volume: Double
    @State private var backupVolume: Double = 0.0
    @State private var isMuted: Bool = false

    var body: some View {
        Slider(value: Binding(
            get: { volume },
            set: { newVolume in
                volume = (newVolume / 0.05).rounded() * 0.05
                if volume > 0.0 {
                    isMuted = false
                }
        }), in: 0 ... 2) {
            Text(String(format: "%.0f%%", volume * 100))
            .font(.system(.body).monospacedDigit())
            .frame(width: 38, alignment: .trailing)
        }.gesture(TapGesture(count: 2).onEnded {
            volume = 1.0
        }).simultaneousGesture(LongPressGesture().onEnded { _ in
            if volume > 0.0 {
                backupVolume = volume
                volume = 0.0
                isMuted = true
            }
            else if isMuted {
                volume = backupVolume
                isMuted = false
            }
        })
    }
}

private struct SoundsView: View {
    @EnvironmentObject var player: TBPlayer
    var sliderWidth: CGFloat

    var body: some View {
        let columns = [
            GridItem(.flexible()),
            GridItem(.fixed(sliderWidth))
        ]
        LazyVGrid(columns: columns, alignment: .leading, spacing: 4) {
            Text(NSLocalizedString("SoundsView.isWindupEnabled.label",
                                   comment: "Windup label"))
            VolumeSlider(volume: $player.windupVolume)
            Text(NSLocalizedString("SoundsView.isDingEnabled.label",
                                   comment: "Ding label"))
            VolumeSlider(volume: $player.dingVolume)
            Text(NSLocalizedString("SoundsView.isTickingEnabled.label",
                                   comment: "Ticking label"))
            VolumeSlider(volume: $player.tickingVolume)
        }.padding(4)
        Button {
            TBStatusItem.shared.closePopover(nil)
            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: player.soundFolder.path)
        } label: {
            Text(NSLocalizedString("SoundsView.openSoundFolder.label", comment: "Open sound folder label"))
        }
        Spacer().frame(minHeight: 0)
    }
}

private enum ChildView {
    case intervals, settings, shortcuts, sounds
}

private struct IconButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 20))
            .accentColor(Color.white)
            .buttonStyle(.plain)
            .frame(width: 28, height: 28)
    }
}

extension View {
    func iconButtonStyle() -> some View {
        modifier(IconButtonStyle())
    }
}

struct TBPopoverView: View {
    @ObservedObject var timer = TBTimer()
    @State private var buttonHovered = false
    @State private var activeChildView = ChildView.intervals

    private func GetLocalizedWidth() -> CGFloat {
        let widthString = NSLocalizedString("TBPopoverView.width", comment: "Width for the view")
        return CGFloat(Double(widthString) ?? 255)
    }

    private func TimerDisplayString() -> String {
        var result = timer.timeLeftString
        if timer.currentPresetInstance.workIntervalsInSet > 1, timer.sessionStopAfter == .disabled || timer.sessionStopAfter == .longRest {
            result += " (" + String(timer.currentWorkInterval) + "/" + String(timer.currentPresetInstance.workIntervalsInSet) + ")"
        }
        return result
    }

    private var startLabel = NSLocalizedString("TBPopoverView.start.label", comment: "Start label")
    private var stopLabel = NSLocalizedString("TBPopoverView.stop.label", comment: "Stop label")
    private var addMinuteLabel = NSLocalizedString("TBPopoverView.addMinute.help", comment: "Add a minute hint")
    private var pauseLabel = NSLocalizedString("TBPopoverView.pause.help", comment: "Pause hint")
    private var resumeLabel = NSLocalizedString("TBPopoverView.resume.help", comment: "Resume hint")
    private var skipLabel = NSLocalizedString("TBPopoverView.skip.help", comment: "Skip hint")
    private var playIcon = Image(systemName: "play.fill")
    private var stopIcon = Image(systemName: "stop.fill")
    private var plusIcon = Image(systemName: "plus.circle.fill")
    private var resumeIcon = Image(systemName: "play.circle.fill")
    private var pauseIcon = Image(systemName: "pause.circle.fill")
    private var skipIcon = Image(systemName: "forward.circle.fill")

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 4) {
                Button {
                    timer.startStop()
                    TBStatusItem.shared.closePopover(nil)
                } label: {
                    HStack {
                        if timer.timer == nil || buttonHovered {
                            Text(timer.timer != nil ? stopIcon : playIcon)
                        }
                        Text(timer.timer != nil ?
                             (buttonHovered ? stopLabel : TimerDisplayString()) :
                                startLabel)
                    }
                    /*
                     When appearance is set to "Dark" and accent color is set to "Graphite"
                     "defaultAction" button label's color is set to the same color as the
                     button, making the button look blank. #24
                     */
                    .foregroundColor(Color.white)
                    .font(.system(.body).monospacedDigit())
                    .frame(maxWidth: .infinity)
                }
                .onHover { over in
                    buttonHovered = over
                }
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)

                Spacer()
                    .frame(width: 2)

                Button {
                    timer.addMinutes(1)
                } label: {
                    Text("+1")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color.white)
                        .frame(width: 28, height: 20)
                        .background(Color.primary.opacity(0.8))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help(addMinuteLabel)
                .disabled(timer.timer == nil)

                Button {
                    timer.addMinutes(5)
                } label: {
                    Text("+5")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color.white)
                        .frame(width: 28, height: 20)
                        .background(Color.primary.opacity(0.8))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help(NSLocalizedString("TBPopoverView.addFiveMinutes.help", comment: "Add five minutes hint"))
                .disabled(timer.timer == nil)

                Button {
                    timer.pauseResume()
                    TBStatusItem.shared.closePopover(nil)
                } label: {
                    (timer.paused ? resumeIcon : pauseIcon)
                }
                .iconButtonStyle()
                .help(timer.paused ? resumeLabel : pauseLabel)
                .disabled(timer.timer == nil)

                Button {
                    timer.skip()
                    TBStatusItem.shared.closePopover(nil)
                } label: {
                    skipIcon
                }
                .iconButtonStyle()
                .help(skipLabel)
                .disabled(timer.timer == nil)
            }
            
            Picker("", selection: $activeChildView) {
                Text(NSLocalizedString("TBPopoverView.intervals.label",
                                       comment: "Intervals label")).tag(ChildView.intervals)
                Text(NSLocalizedString("TBPopoverView.settings.label",
                                       comment: "Settings label")).tag(ChildView.settings)
                Text(NSLocalizedString("TBPopoverView.shortcuts.label",
                                       comment: "Shortcuts label")).tag(ChildView.shortcuts)
                Text(NSLocalizedString("TBPopoverView.sounds.label",
                                       comment: "Sounds label")).tag(ChildView.sounds)
            }
            .labelsHidden()
            .frame(maxWidth: .infinity)
            .pickerStyle(.segmented)

            GroupBox {
                switch activeChildView {
                case .intervals:
                    IntervalsView().environmentObject(timer)
                case .settings:
                    SettingsView().environmentObject(timer)
                case .shortcuts:
                    ShortcutsView()
                case .sounds:
                    SoundsView(sliderWidth: GetLocalizedWidth()*0.53).environmentObject(timer.player)
                }
            }

            Group {
                Button {
                    NSApp.activate(ignoringOtherApps: true)
                    NSApp.orderFrontStandardAboutPanel()
                } label: {
                    Text(NSLocalizedString("TBPopoverView.about.label",
                                           comment: "About label"))
                    Spacer()
                    Text("⌘ A").foregroundColor(Color.gray)
                }
                .buttonStyle(.plain)
                .keyboardShortcut("a")
                Button {
                    NSApplication.shared.terminate(self)
                } label: {
                    Text(NSLocalizedString("TBPopoverView.quit.label",
                                           comment: "Quit label"))
                    Spacer()
                    Text("⌘ Q").foregroundColor(Color.gray)
                }
                .buttonStyle(.plain)
                .keyboardShortcut("q")
            }
        }
        .frame(width: GetLocalizedWidth())
        .fixedSize()
        #if DEBUG
        .overlay(
                GeometryReader { proxy in
                    debugSize(proxy: proxy)
                }
            )
        #endif
            /* Use values from GeometryReader */
//            .frame(width: 240, height: 276)
        .padding(12)
    }
}

#if DEBUG
    func debugSize(proxy: GeometryProxy) -> some View {
        print("Optimal popover size:", proxy.size)
        return Color.clear
    }
#endif
