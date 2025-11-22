import Foundation
import SwiftUI

extension View {
    /// Apply flexible button sizing for segmented pickers on macOS 26+
    @ViewBuilder
    func applyButtonSizingFlexible() -> some View {
        if #available(macOS 26.0, *) {
            self.buttonSizing(.flexible)
        } else {
            self
        }
    }

    /// Frame with maxWidth infinity and leading alignment
    func frameInfinityLeading() -> some View {
        self.frame(maxWidth: .infinity, alignment: .leading)
    }
}

// Get localized name for a language code
func getLanguageName(for code: String) -> String {
    if code == "system" {
        return NSLocalizedString("SettingsView.app.language.system.label",
                                comment: "Language system label")
    }
    // Get language name in its own language via Locale API
    if let name = Locale(identifier: code).localizedString(forLanguageCode: code) {
        return name.prefix(1).uppercased() + name.dropFirst()
    }
    return code
}

// Get available app languages: system + English + all other localizations
func getAvailableLanguages() -> [String] {
    let localizations = Bundle.main.localizations.filter { $0 != "en" }.sorted()
    return ["system", "en"] + localizations
}

func clampedNumberFormatter(min: Int, max: Int) -> NumberFormatter {
    let formatter = NumberFormatter()
    formatter.minimum = NSNumber(value: min)
    formatter.maximum = NSNumber(value: max)
    formatter.generatesDecimalNumbers = false
    formatter.maximumFractionDigits = 0
    return formatter
}

// Adaptive UI size for different macOS versions
func uiSize(_ base: CGFloat, macOS26: CGFloat) -> CGFloat {
    if #available(macOS 26, *) { return macOS26 }
    return base
}

// Adaptive UI sizes for different macOS versions
enum UISizes {
    // Size for icon action buttons (pause, skip)
    static var actionButtonSize: CGFloat {
        uiSize(28, macOS26: 32)
    }

    // Height for small action buttons (+1, +5)
    static var smallActionButtonHeight: CGFloat {
        uiSize(20, macOS26: 22)
    }

    // Font size for action button icons
    static var actionFontSize: CGFloat {
        uiSize(20, macOS26: 22)
    }

    // Font size for small action button text (+1, +5)
    static var smallActionFontSize: CGFloat {
        uiSize(10, macOS26: 11)
    }
}

protocol DropdownDescribable: RawRepresentable where RawValue == String { }

struct EnumSegmentedPicker<E: CaseIterable & Hashable & DropdownDescribable>: View where E.RawValue == String, E.AllCases: RandomAccessCollection {
    @Binding var value: E

    var body: some View {
        Picker("", selection: $value) {
            ForEach(E.allCases, id: \.self) { option in
                Text(option.description)
            }
        }
        .labelsHidden()
        .pickerStyle(.segmented)
        .applyButtonSizingFlexible()
    }
}

struct RightClickActionPicker: View {
    @Binding var value: RightClickAction

    var body: some View {
        Picker("", selection: $value) {
            ForEach(RightClickAction.allCases, id: \.self) { option in
                Text(option.label)
            }
        }
        .labelsHidden()
        .pickerStyle(.segmented)
        .applyButtonSizingFlexible()
    }
}

extension RightClickAction {
    var label: String {
        switch self {
        case .off: return "✕"
        case .startStop: return "▶︎"
        case .pauseResume: return "⏸"
        case .addMinute: return "+1"
        case .addFiveMinutes: return "+5"
        case .skipInterval: return ">>"
        }
    }
}

extension DropdownDescribable {
    var description: String {
        switch self.rawValue {
        case "disabled": return NSLocalizedString("IntervalsView.off.label",
                                                  comment: "Disabled label")
        case "work": return NSLocalizedString("IntervalsView.work.label",
                                              comment: "Work label")
        case "rest": return NSLocalizedString("IntervalsView.break.label",
                                              comment: "Break label")
        case "shortRest": return NSLocalizedString("IntervalsView.break.label",
                                                   comment: "Short rest label")
        case "longRest": return NSLocalizedString("IntervalsView.set.label",
                                                  comment: "Long rest label")
        case "running": return NSLocalizedString("SettingsView.timer.show.active.label",
                                                 comment: "Show timer active label")
        case "always": return NSLocalizedString("SettingsView.timer.show.always.label",
                                                comment: "Show timer always label")
        case "fontSystem": return NSLocalizedString("SettingsView.timer.font.system.label",
                                                    comment: "Timer font system label")
        case "notifySystem": return NSLocalizedString("SettingsView.alert.notifyStyle.system.label",
                                                      comment: "Notify style system label")
        case "ptMono": return NSLocalizedString("SettingsView.timer.font.ptMono.label",
                                                comment: "PT Mono font label")
        case "sfMono": return NSLocalizedString("SettingsView.timer.font.sfMono.label",
                                                comment: "SF Mono font label")
        case "notify": return NSLocalizedString("SettingsView.alert.mode.notify.label",
                                                comment: "Alert mode notify label")
        case "fullScreen": return NSLocalizedString("SettingsView.alert.mode.fullScreen.label",
                                                    comment: "Alert mode full-screen label")
        case "small": return NSLocalizedString("SettingsView.alert.notifyStyle.small.label",
                                               comment: "Notify style small label")
        case "big": return NSLocalizedString("SettingsView.alert.notifyStyle.big.label",
                                             comment: "Notify style big label")
        case "dndOff": return NSLocalizedString("IntervalsView.dnd.off",
                                                comment: "DND off label")
        case "onWork": return NSLocalizedString("IntervalsView.dnd.onWork",
                                                comment: "DND on work label")
        default: return self.rawValue.capitalized
        }
    }
}

struct VolumeSlider: View {
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
            } else if isMuted {
                volume = backupVolume
                isMuted = false
            }
        })
    }
}

private struct IconButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: UISizes.actionFontSize))
            .accentColor(Color.white)
            .buttonStyle(.plain)
            .frame(width: UISizes.actionButtonSize, height: UISizes.actionButtonSize)
    }
}

extension View {
    func iconButtonStyle() -> some View {
        modifier(IconButtonStyle())
    }
}
