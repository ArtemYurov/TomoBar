import Foundation

class AppNapPrevent {
    private var token: NSObjectProtocol?

    func startActivity() {
        if token == nil {
            token = ProcessInfo.processInfo.beginActivity(
                options: [.userInitiated, .idleSystemSleepDisabled],
                reason: "Timer is running"
            )
        }
    }

    func endActivity() {
        if let token = token {
            ProcessInfo.processInfo.endActivity(token)
            self.token = nil
        }
    }
}
