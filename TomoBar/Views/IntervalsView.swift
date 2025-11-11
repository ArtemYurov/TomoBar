import SwiftUI

struct IntervalsView: View {
    @EnvironmentObject var timer: TBTimer
    #if DEBUG
    private var minStr: String {
        timer.useSecondsInsteadOfMinutes ? "sec" : NSLocalizedString("IntervalsView.min", comment: "min")
    }
    #else
    private var minStr = NSLocalizedString("IntervalsView.min", comment: "min")
    #endif

    enum DNDMode: String, CaseIterable, DropdownDescribable {
        case dndOff
        case onWork
    }

    // Temporary computed property for mapping bool to/from enum (preserves functionality)
    private var dndMode: Binding<DNDMode> {
        Binding(
            get: {
                timer.currentPresetInstance.focusOnWork ? .onWork : .dndOff
            },
            set: { newValue in
                // For now, only .onWork sets true, everything else is false
                timer.currentPresetInstance.focusOnWork = (newValue == .onWork)
            }
        )
    }

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

    private func updateDNDIfNeeded() {
        // Update DND status if timer is running in Work mode
        if timer.isWorking, !timer.paused {
            let shouldFocus = timer.currentPresetInstance.focusOnWork
            timer.dnd.set(focus: shouldFocus)
        }
    }

    @FocusState private var focusedField: IntervalField?

    var body: some View {
        VStack {
            HStack {
                Text(NSLocalizedString("IntervalsView.startWith.label",
                                       comment: "Start with"))
                    .frameInfinityLeading()
                EnumSegmentedPicker(value: $timer.currentPresetInstance.startWith)
            }
            .onChange(of: timer.currentPresetInstance.startWith) { _ in
                timer.updateDisplay()
            }
            HStack {
                Text(NSLocalizedString("IntervalsView.dnd.label",
                                       comment: "DND"))
                    .frameInfinityLeading()
                EnumSegmentedPicker(value: dndMode)
                    .help(NSLocalizedString("IntervalsView.dnd.help",
                                            comment: "Toggle Do Not Disturb hint"))
            }
            .onChange(of: timer.currentPresetInstance.focusOnWork) { _ in
                updateDNDIfNeeded()
            }
            Stepper(value: $timer.currentPresetInstance.workIntervalLength, in: 1 ... 120) {
                HStack {
                    Text(NSLocalizedString("IntervalsView.workIntervalLength.label",
                                           comment: "Work interval label"))
                        .frameInfinityLeading()
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
                        .frameInfinityLeading()
                    TextField("", text: Binding(
                        get: {
                            isFieldDisabled(.shortRest) ? "—" : "\(timer.currentPresetInstance.shortRestIntervalLength)"
                        },
                        set: { newValue in
                            if !isFieldDisabled(.shortRest), let value = Int(newValue) {
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
                        .frameInfinityLeading()
                    TextField("", text: Binding(
                        get: {
                            isFieldDisabled(.longRest) ? "—" : "\(timer.currentPresetInstance.longRestIntervalLength)"
                        },
                        set: { newValue in
                            if !isFieldDisabled(.longRest), let value = Int(newValue) {
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
                        .frameInfinityLeading()
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
                    .frameInfinityLeading()
                EnumSegmentedPicker(value: $timer.currentPresetInstance.sessionStopAfter)
            }
            Spacer().frame(minHeight: 0)
            HStack {
                Text(NSLocalizedString("IntervalsView.presets.label",
                                       comment: "Presets label"))
                Spacer().frame(width: 12)
                Picker("", selection: $timer.currentPreset) {
                    Text("1").tag(0)
                    Text("2").tag(1)
                    Text("3").tag(2)
                    Text("4").tag(3)
                }
                .labelsHidden()
                .frame(minWidth: 180, maxWidth: .infinity, alignment: .trailing)
                .pickerStyle(.segmented)
                .applyButtonSizingFlexible()
            }
            .onChange(of: timer.currentPreset) { _ in
                timer.updateDisplay()
                updateDNDIfNeeded()
            }
            Spacer().frame(minHeight: 0)
        }
        .padding(4)
    }
}
