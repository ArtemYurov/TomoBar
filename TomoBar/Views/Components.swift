import Foundation
import SwiftUI

func clampedNumberFormatter(min: Int, max: Int) -> NumberFormatter {
    let formatter = NumberFormatter()
    formatter.minimum = NSNumber(value: min)
    formatter.maximum = NSNumber(value: max)
    formatter.generatesDecimalNumbers = false
    formatter.maximumFractionDigits = 0
    return formatter
}

protocol DropdownDescribable: RawRepresentable where RawValue == String { }

struct StartStopDropdown<E: CaseIterable & Hashable & DropdownDescribable>: View where E.RawValue == String, E.AllCases: RandomAccessCollection {
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
