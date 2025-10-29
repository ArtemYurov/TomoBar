import SwiftUI

struct IntervalsView: View {
    @EnvironmentObject var timer: TBTimer
    private var minStr = NSLocalizedString("IntervalsView.min", comment: "min")

    enum IntervalField: Hashable {
        case work
        case shortRest
        case longRest
        case workIntervals
    }

    private func isFieldDisabled(_ field: IntervalField) -> Bool {
        let stopAfter = timer.currentPresetInstance.sessionStopAfter
        let workIntervals = timer.currentPresetInstance.workIntervalsInSet

        switch field {
        case .work:
            return false
        case .shortRest:
            return stopAfter == .work
        case .longRest:
            return workIntervals == 1 || stopAfter == .work || stopAfter == .shortRest
        case .workIntervals:
            return stopAfter == .work || stopAfter == .shortRest
        }
    }

    @FocusState private var focusedField: IntervalField?

    var body: some View {
        VStack {
            HStack {
                Text(NSLocalizedString("IntervalsView.startWith.label",
                                       comment: "Start with"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                StartStopDropdown(value: $timer.currentPresetInstance.startWith)
            }
            .onChange(of: timer.currentPresetInstance.startWith) { _ in
                timer.updateDisplay()
            }
            Stepper(value: $timer.currentPresetInstance.workIntervalLength, in: 1 ... 120) {
                HStack {
                    Text(NSLocalizedString("IntervalsView.workIntervalLength.label",
                                           comment: "Work interval label"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    TextField("", value: $timer.currentPresetInstance.workIntervalLength, formatter: clampedNumberFormatter(min: 1, max: 120))
                        .frame(width: 36, alignment: .trailing)
                        .multilineTextAlignment(.trailing)
                        .focused($focusedField, equals: .work)
                        .onSubmit({ focusedField = .shortRest })
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
                    TextField("", text: Binding(
                        get: {
                            isFieldDisabled(.shortRest) ? "—" : "\(Int(timer.currentPresetInstance.shortRestIntervalLength))"
                        },
                        set: { newValue in
                            if !isFieldDisabled(.shortRest), let value = Double(newValue) {
                                timer.currentPresetInstance.shortRestIntervalLength = min(max(value, 1), 120)
                            }
                        }
                    ))
                        .frame(width: 36, alignment: .trailing)
                        .multilineTextAlignment(.trailing)
                        .focused($focusedField, equals: .shortRest)
                        .onSubmit({ focusedField = .longRest })
                        .disabled(isFieldDisabled(.shortRest))
                        .foregroundColor(isFieldDisabled(.shortRest) ? .secondary : .primary)
                    Text(minStr)
                        .foregroundColor(isFieldDisabled(.shortRest) ? .secondary : .primary)
                }
            }
            .allowsHitTesting(!isFieldDisabled(.shortRest))
            .onChange(of: timer.currentPresetInstance.shortRestIntervalLength) { _ in
                timer.adjustTimerDebounced(state: .shortRest)
            }
            Stepper(value: $timer.currentPresetInstance.longRestIntervalLength, in: 1 ... 120) {
                HStack {
                    Text(NSLocalizedString("IntervalsView.longRestIntervalLength.label",
                                           comment: "Long rest interval label"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    TextField("", text: Binding(
                        get: {
                            isFieldDisabled(.longRest) ? "—" : "\(Int(timer.currentPresetInstance.longRestIntervalLength))"
                        },
                        set: { newValue in
                            if !isFieldDisabled(.longRest), let value = Double(newValue) {
                                timer.currentPresetInstance.longRestIntervalLength = min(max(value, 1), 120)
                            }
                        }
                    ))
                        .frame(width: 36, alignment: .trailing)
                        .multilineTextAlignment(.trailing)
                        .focused($focusedField, equals: .longRest)
                        .onSubmit({ focusedField = .workIntervals })
                        .disabled(isFieldDisabled(.longRest))
                        .foregroundColor(isFieldDisabled(.longRest) ? .secondary : .primary)
                    Text(minStr)
                        .foregroundColor(isFieldDisabled(.longRest) ? .secondary : .primary)
                }
            }
            .allowsHitTesting(!isFieldDisabled(.longRest))
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
                    TextField("", text: Binding(
                        get: {
                            isFieldDisabled(.workIntervals) ? "—" : "\(timer.currentPresetInstance.workIntervalsInSet)"
                        },
                        set: { newValue in
                            if !isFieldDisabled(.workIntervals), let value = Int(newValue) {
                                timer.currentPresetInstance.workIntervalsInSet = min(max(value, 1), 10)
                            }
                        }
                    ))
                        .frame(width: 36, alignment: .trailing)
                        .multilineTextAlignment(.trailing)
                        .focused($focusedField, equals: .workIntervals)
                        .onSubmit({ focusedField = .work })
                        .disabled(isFieldDisabled(.workIntervals))
                        .foregroundColor(isFieldDisabled(.workIntervals) ? .secondary : .primary)
                }
            }
            .allowsHitTesting(!isFieldDisabled(.workIntervals))
            .help(NSLocalizedString("IntervalsView.workIntervalsInSet.help",
                                    comment: "Work intervals in set hint"))
            HStack {
                Text(NSLocalizedString("IntervalsView.stopAfter.label",
                                       comment: "Stop after"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                StartStopDropdown(value: $timer.currentPresetInstance.sessionStopAfter)
            }
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
