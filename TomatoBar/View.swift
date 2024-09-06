import KeyboardShortcuts
import LaunchAtLogin
import SwiftUI

extension KeyboardShortcuts.Name {
    static let startStopTimer = Self("startStopTimer")
    static let pauseResumeTimer = Self("pauseResumeTimer")
    static let skipTimer = Self("skipTimer")
}

private struct IntervalsView: View {
    @EnvironmentObject var timer: TBTimer
    private func ClampedNumberFormatter(min: Int, max: Int) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.minimum = NSNumber(value: min)
        formatter.maximum = NSNumber(value: max)
        formatter.generatesDecimalNumbers = false
        formatter.maximumFractionDigits = 0
        return formatter
    }
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
            Stepper(value: $timer.workIntervalLength, in: 1 ... 120) {
                HStack {
                    Text(NSLocalizedString("IntervalsView.workIntervalLength.label",
                                           comment: "Work interval label"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    TextField("", value: $timer.workIntervalLength, formatter: ClampedNumberFormatter(min: 1, max: 120))
                        .frame(width: 36, alignment: .trailing)
                        .multilineTextAlignment(.trailing)
                        .focused($focusedField, equals: .workIntervalLength)
                        .onSubmit({ focusedField = .shortRestIntervalLength })
                    Text(minStr)
                }
            }
            Stepper(value: $timer.shortRestIntervalLength, in: 1 ... 120) {
                HStack {
                    Text(NSLocalizedString("IntervalsView.shortRestIntervalLength.label",
                                           comment: "Short rest interval label"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    TextField("", value: $timer.shortRestIntervalLength, formatter: ClampedNumberFormatter(min: 1, max: 120))
                        .frame(width: 36, alignment: .trailing)
                        .multilineTextAlignment(.trailing)
                        .focused($focusedField, equals: .shortRestIntervalLength)
                        .onSubmit({ focusedField = .longRestIntervalLength })
                    Text(minStr)
                }
            }
            Stepper(value: $timer.longRestIntervalLength, in: 1 ... 120) {
                HStack {
                    Text(NSLocalizedString("IntervalsView.longRestIntervalLength.label",
                                           comment: "Long rest interval label"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    TextField("", value: $timer.longRestIntervalLength, formatter: ClampedNumberFormatter(min: 1, max: 120))
                        .frame(width: 36, alignment: .trailing)
                        .multilineTextAlignment(.trailing)
                        .focused($focusedField, equals: .longRestIntervalLength)
                        .onSubmit({ focusedField = .workIntervalsInSet })
                    Text(minStr)
                }
            }
            .help(NSLocalizedString("IntervalsView.longRestIntervalLength.help",
                                    comment: "Long rest interval hint"))
            Stepper(value: $timer.workIntervalsInSet, in: 1 ... 10) {
                HStack {
                    Text(NSLocalizedString("IntervalsView.workIntervalsInSet.label",
                                           comment: "Work intervals in a set label"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    TextField("", value: $timer.workIntervalsInSet, formatter: ClampedNumberFormatter(min: 1, max: 10))
                        .frame(width: 36, alignment: .trailing)
                        .multilineTextAlignment(.trailing)
                        .focused($focusedField, equals: .workIntervalsInSet)
                        .onSubmit({ focusedField = .workIntervalLength })
                }
            }
            .help(NSLocalizedString("IntervalsView.workIntervalsInSet.help",
                                    comment: "Work intervals in set hint"))
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
        .pickerStyle(.menu)
    }
}

extension DropdownDescribable {
    var description: String {
        switch self.rawValue {
            case "disabled": return NSLocalizedString("SettingsView.dropdownDisabled.label",
                                                  comment: "Disabled label")
            case "work": return NSLocalizedString("SettingsView.dropdownWork.label",
                                                    comment: "Work label")
            case "rest": return NSLocalizedString("SettingsView.dropdownBreak.label",
                                                    comment: "Break label")
            default: return self.rawValue
        }
    }
}

private struct SettingsView: View {
    @EnvironmentObject var timer: TBTimer
    @ObservedObject private var launchAtLogin = LaunchAtLogin.observable

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
            HStack {
                Text(NSLocalizedString("SettingsView.startWith.label",
                                        comment: "Start with label"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                StartStopDropdown(value: $timer.startWith)
            }
            HStack {
                Text(NSLocalizedString("SettingsView.stopAfter.label",
                                        comment: "Stop after label"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                StartStopDropdown(value: $timer.stopAfter)
            }
            Toggle(isOn: $timer.showTimerInMenuBar) {
                Text(NSLocalizedString("SettingsView.showTimerInMenuBar.label",
                                       comment: "Show timer in menu bar label"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }.toggleStyle(.switch)
                .onChange(of: timer.showTimerInMenuBar) { _ in
                    timer.updateTimeLeft()
                }
            Toggle(isOn: $timer.showFullScreenMask) {
                Text(NSLocalizedString("SettingsView.showFullScreenMask.label",
                                       comment: "show full screen mask on rest"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .toggleStyle(.switch)
            .help(NSLocalizedString("SettingsView.showFullScreenMask.help",
                                    comment: "show full screen mask hint"))
            Toggle(isOn: $timer.toggleDoNotDisturb) {
                Text(NSLocalizedString("SettingsView.toggleDoNotDisturb.label",
                                       comment: "Toggle Do Not Disturb"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .toggleStyle(.switch)
            .help(NSLocalizedString("SettingsView.toggleDoNotDisturb.help",
                                    comment: "Toggle Do Not Disturb hint"))
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

    private var columns = [
        GridItem(.flexible()),
        GridItem(.fixed(135))
    ]

    var body: some View {
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
    case intervals, settings, sounds
}

struct TBPopoverView: View {
    @ObservedObject var timer = TBTimer()
    @State private var buttonHovered = false
    @State private var activeChildView = ChildView.intervals

    private func TimerDisplayString() -> String {
        var result = timer.timeLeftString
        if timer.stopAfter == .disabled {
            result += " (" + String(timer.currentWorkInterval) + "/" + String(timer.workIntervalsInSet) + ")"
        }
        return result
    }

    private var startLabel = NSLocalizedString("TBPopoverView.start.label", comment: "Start label")
    private var stopLabel = NSLocalizedString("TBPopoverView.stop.label", comment: "Stop label")
    private var plusIcon = Image(systemName: "plus.circle.fill")
    private var playIcon = Image(systemName: "play.circle.fill")
    private var pauseIcon = Image(systemName: "pause.circle.fill")
    private var skipIcon = Image(systemName: "forward.circle.fill")

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 4) {
                Button {
                    timer.startStop()
                    TBStatusItem.shared.closePopover(nil)
                } label: {
                    Text(timer.timer != nil ?
                         (buttonHovered ? stopLabel : TimerDisplayString()) :
                            startLabel)
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
                
                if timer.timer != nil {
                    Group {
                        Button {
                            timer.addMinute()
                        } label: {
                            Text(plusIcon)
                        }
                        .controlSize(.large)
                        .help(NSLocalizedString("TBPopoverView.addMinute.help",
                                comment: "Add a minute hint"))

                        Button {
                            timer.pauseResume()
                            TBStatusItem.shared.closePopover(nil)
                        } label: {
                            Text(timer.paused ?  playIcon : pauseIcon)
                        }
                        .controlSize(.large)
                        .help(NSLocalizedString("TBPopoverView.pause.help",
                                comment: "Pause hint"))

                        Button {
                            timer.skip()
                            TBStatusItem.shared.closePopover(nil)
                        } label: {
                            Text(skipIcon)
                        }
                        .controlSize(.large)
                        .help(NSLocalizedString("TBPopoverView.skip.help",
                                comment: "Skip hint"))
                    }
                    .disabled(timer.timer == nil)
                }
            }
            
            Picker("", selection: $activeChildView) {
                Text(NSLocalizedString("TBPopoverView.intervals.label",
                                       comment: "Intervals label")).tag(ChildView.intervals)
                Text(NSLocalizedString("TBPopoverView.settings.label",
                                       comment: "Settings label")).tag(ChildView.settings)
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
                case .sounds:
                    SoundsView().environmentObject(timer.player)
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
        .frame(width: 245)
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
