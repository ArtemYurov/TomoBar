import UserNotifications

enum TBNotification {
    enum Category: String {
        case restStarted, restFinished, sessionComplete
    }

    enum Action: String {
        case skip
    }
}

class SystemNotifyHelper: NSObject, UNUserNotificationCenterDelegate {

    private var center = UNUserNotificationCenter.current()
    private var skipEventHandler: (() -> Void)?

    init(skipHandler: @escaping () -> Void) {
        self.skipEventHandler = skipHandler
        super.init()

        center.delegate = self

        let categoryConfigs: [(category: TBNotification.Category, actionTitle: String?)] = [
            (.restStarted, NSLocalizedString("SystemNotification.restStart.skipBreak.action", comment: "Skip break")),
            (.restFinished, NSLocalizedString("SystemNotification.restFinish.skipWork.action", comment: "Skip work")),
            (.sessionComplete, nil)
        ]

        let categories = categoryConfigs.map { config in
            let actions = config.actionTitle.map { title in
                [UNNotificationAction(
                    identifier: TBNotification.Action.skip.rawValue,
                    title: title,
                    options: []
                )]
            } ?? []

            return UNNotificationCategory(
                identifier: config.category.rawValue,
                actions: actions,
                intentIdentifiers: []
            )
        }

        center.setNotificationCategories(Set(categories))
    }

    func needsPermission(completion: @escaping (Bool) -> Void) {
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus == .notDetermined)
            }
        }
    }

    func requestPermission() {
        center.requestAuthorization(options: [.alert]) { granted, error in
            if let error = error {
                print("Error requesting notification authorization: \(error)")
            }
            if granted {
                print("Notification permission granted")
            }
        }
    }

    func userNotificationCenter(_: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler _: @escaping () -> Void)
    {
        if let action = TBNotification.Action(rawValue: response.actionIdentifier) {
            if action == .skip {
                skipEventHandler?()
            }
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is active
        if #available(macOS 11.0, *) {
            completionHandler([.banner, .sound])
        } else {
            completionHandler([.alert, .sound])
        }
    }

    func sessionComplete() {
        let title = NSLocalizedString("SystemNotification.sessionComplete.title", comment: "Timer completed")
        let body = NSLocalizedString("SystemNotification.sessionComplete.body", comment: "Session finished")
        send(title: title, body: body, category: .sessionComplete)
    }

    func restStarted(isLong: Bool) {
        let title = NSLocalizedString("SystemNotification.restStart.title", comment: "Time's up title")
        let body = isLong
            ? NSLocalizedString("SystemNotification.restStart.longBreak.body", comment: "It's time for a long break!")
            : NSLocalizedString("SystemNotification.restStart.shortBreak.body", comment: "It's time for a short break!")
        send(title: title, body: body, category: .restStarted)
    }

    func restFinished() {
        let title = NSLocalizedString("SystemNotification.restFinish.title", comment: "Break is over title")
        let body = NSLocalizedString("SystemNotification.restFinish.body", comment: "Break is over body")
        send(title: title, body: body, category: .restFinished)
    }

    private func send(title: String, body: String, category: TBNotification.Category) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.categoryIdentifier = category.rawValue

        if #available(macOS 12.0, *) {
            content.interruptionLevel = .timeSensitive
        }

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        DispatchQueue.main.async {
            self.center.add(request) { error in
                if error != nil {
                    print("Error adding notification: \(error!)")
                }
            }
        }
    }
}
