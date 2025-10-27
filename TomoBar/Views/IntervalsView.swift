import SwiftUI

struct IntervalsView: View {
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
                    TextField("", value: $timer.currentPresetInstance.workIntervalLength, formatter: clampedNumberFormatter(min: 1, max: 120))
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
                    TextField("", value: $timer.currentPresetInstance.shortRestIntervalLength, formatter: clampedNumberFormatter(min: 1, max: 120))
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
                    TextField("", value: $timer.currentPresetInstance.longRestIntervalLength, formatter: clampedNumberFormatter(min: 1, max: 120))
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
                    TextField("", value: $timer.currentPresetInstance.workIntervalsInSet, formatter: clampedNumberFormatter(min: 1, max: 10))
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
