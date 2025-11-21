import SwiftUI

enum ChildView {
    case intervals, settings, shortcuts, sounds
}

struct TBPopoverView: View {
    @ObservedObject var timer = TBTimer()
    @State private var buttonHovered = false
    @State private var activeChildView = ChildView.intervals

    private func getLocalizedWidth() -> CGFloat {
        let widthString = NSLocalizedString("View.width", comment: "Width for the view")
        let baseWidth = CGFloat(Double(widthString) ?? 255)
        return uiSize(baseWidth, macOS26: baseWidth + 50)
    }

    private func timerDisplayString() -> String {
        var result = timer.timeLeftString
        if timer.currentPresetInstance.workIntervalsInSet > 1, timer.sessionStopAfter == .disabled || timer.sessionStopAfter == .longRest {
            result += " (" + String(timer.currentWorkInterval) + "/" + String(timer.currentPresetInstance.workIntervalsInSet) + ")"
        }
        return result
    }

    private var startLabel = NSLocalizedString("View.start.label", comment: "Start label")
    private var stopLabel = NSLocalizedString("View.stop.label", comment: "Stop label")
    private var addMinuteLabel = NSLocalizedString("View.addMinute.help", comment: "Add a minute hint")
    private var pauseLabel = NSLocalizedString("View.pause.help", comment: "Pause hint")
    private var resumeLabel = NSLocalizedString("View.resume.help", comment: "Resume hint")
    private var skipLabel = NSLocalizedString("View.skip.help", comment: "Skip hint")
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
                                (buttonHovered ? stopLabel : timerDisplayString()) :
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
                        .font(.system(size: UISizes.smallActionFontSize, weight: .semibold))
                        .foregroundColor(Color.white)
                        .frame(width: UISizes.actionButtonSize, height: UISizes.smallActionButtonHeight)
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
                        .font(.system(size: UISizes.smallActionFontSize, weight: .semibold))
                        .foregroundColor(Color.white)
                        .frame(width: UISizes.actionButtonSize, height: UISizes.smallActionButtonHeight)
                        .background(Color.primary.opacity(0.8))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help(NSLocalizedString("View.addFiveMinutes.help", comment: "Add five minutes hint"))
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
                    timer.skipInterval()
                    TBStatusItem.shared.closePopover(nil)
                } label: {
                    skipIcon
                }
                .iconButtonStyle()
                .help(skipLabel)
                .disabled(timer.timer == nil)
            }

            Picker("", selection: $activeChildView) {
                Text(NSLocalizedString("View.intervals.label",
                                       comment: "Intervals label")).tag(ChildView.intervals)
                Text(NSLocalizedString("View.settings.label",
                                       comment: "Settings label")).tag(ChildView.settings)
                Text(NSLocalizedString("View.shortcuts.label",
                                       comment: "Shortcuts label")).tag(ChildView.shortcuts)
                Text(NSLocalizedString("View.sounds.label",
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
                    SoundsView(sliderWidth: getLocalizedWidth()*0.53).environmentObject(timer.player)
                }
            }

            Group {
                #if SPARKLE
                Button {
                    TBStatusItem.shared.checkForUpdates()
                } label: {
                    Text(NSLocalizedString("View.checkForUpdates.label",
                                           comment: "Check for Updates label"))
                    Spacer()
                    Text("⌘ U").foregroundColor(Color.gray)
                }
                .buttonStyle(.plain)
                .keyboardShortcut("u")
                #endif

                Button {
                    NSApp.activate(ignoringOtherApps: true)
                    NSApp.orderFrontStandardAboutPanel()
                } label: {
                    Text(NSLocalizedString("View.about.label",
                                           comment: "About label"))
                    Spacer()
                    Text("⌘ A").foregroundColor(Color.gray)
                }
                .buttonStyle(.plain)
                .keyboardShortcut("a")
                Button {
                    NSApplication.shared.terminate(self)
                } label: {
                    Text(NSLocalizedString("View.quit.label",
                                           comment: "Quit label"))
                    Spacer()
                    Text("⌘ Q").foregroundColor(Color.gray)
                }
                .buttonStyle(.plain)
                .keyboardShortcut("q")
            }
        }
        .frame(width: getLocalizedWidth())
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
