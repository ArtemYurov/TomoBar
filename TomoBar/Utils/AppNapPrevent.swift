import Foundation

class AppNapPrevent {
    private var token: NSObjectProtocol?

    // ── Activity options: .userInitiated vs .background ────────────────────────
    //
    // .userInitiated (0x001FFFFF) = all bits 0-20 set:
    //
    //   .userInitiated (0x001FFFFF) = .background (0xFF)          bits 0-7
    //                               + UNDOCUMENTED BITS           bits 8-13
    //                               + .suddenTermDisabled         bit 14
    //                               + .automaticTermDisabled      bit 15
    //                               + UNDOCUMENTED BITS           bits 16-19
    //                               + .idleSystemSleepDisabled    bit 20
    //
    // .background + 3 explicit flags = 0x0010C0FF:
    //
    //   .background (0xFF)          bits 0-7
    //   + .suddenTermDisabled       bit 14
    //   + .automaticTermDisabled    bit 15
    //   + .idleSystemSleepDisabled  bit 20
    //
    // Bitwise comparison:
    //
    //   .userInitiated: 0001 1111 1111 1111 1111 1111  (0x001FFFFF)
    //   .background+3:  0001 0000 1100 0000 1111 1111  (0x0010C0FF)
    //                        ^^^^   ^^^^^^^^
    //                        bits   bits 8-13
    //                        16-19
    //
    // The 12 extra bits (8-13, 16-19) in .userInitiated are undocumented Apple
    // internals that disable CPU throttling, timer coalescing, and App Nap.
    // They cause high energy impact in Activity Monitor even when the user is idle.
    //
    //                       .userInitiated     .background + 3 flags
    //   App Nap              prevented          ALLOWED
    //   Timer throttling     prevented          POSSIBLE
    //   CPU throttling       prevented          POSSIBLE
    //   System sleep         prevented          prevented
    //   Process kill         prevented          prevented
    //   Energy impact        HIGH               lower
    //
    // Chosen: .background for energy efficiency. Timer ticks may be delayed
    // under App Nap, but wall-clock calculation in TimerCore
    // (finishTime.timeIntervalSince(Date())) compensates for any drift.
    // ─────────────────────────────────────────────────────────────────────────

    func startActivity() {
        if token == nil {
            token = ProcessInfo.processInfo.beginActivity(
                options: [
                    .background,
                    .idleSystemSleepDisabled,
                    .automaticTerminationDisabled,
                    .suddenTerminationDisabled
                ],
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
