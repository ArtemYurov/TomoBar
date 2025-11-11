import Foundation

extension TBTimer {
    var alertMode: AlertMode {
        get { notify.alertMode }
        set {
            notify.alertMode = newValue
            objectWillChange.send()
        }
    }

    var notifyStyle: NotifyStyle {
        get { notify.notifyStyle }
        set {
            notify.notifyStyle = newValue
            objectWillChange.send()
        }
    }

    var customBackgroundOpacity: Int {
        get { notify.custom.customBackgroundOpacity }
        set {
            notify.custom.customBackgroundOpacity = newValue
            objectWillChange.send()
        }
    }

    var maskBlockActions: Bool {
        get { notify.mask.maskBlockActions }
        set {
            notify.mask.maskBlockActions = newValue
            objectWillChange.send()
        }
    }

    var maskAutoResumeWork: Bool {
        get { notify.mask.maskAutoResumeWork }
        set {
            notify.mask.maskAutoResumeWork = newValue
            objectWillChange.send()
        }
    }

    public var currentPresetInstance: TimerPreset {
        get {
            return presets[currentPreset]
        }
        set(newValue) {
            presets[currentPreset] = newValue
        }
    }

    var startWith: StartWithValues {
        get { currentPresetInstance.startWith }
        set {
            currentPresetInstance.startWith = newValue
            objectWillChange.send()
        }
    }

    var sessionStopAfter: SessionStopAfter {
        get { currentPresetInstance.sessionStopAfter }
        set {
            currentPresetInstance.sessionStopAfter = newValue
            objectWillChange.send()
        }
    }
}
