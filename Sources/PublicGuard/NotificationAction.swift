import Foundation
import UserNotifications

struct NotificationAction {
    func requestAuthorization() {
        guard Self.canUseUserNotifications else { return }

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func sendAlarmNotification(reason: String) {
        guard Self.canUseUserNotifications else { return }

        let content = UNMutableNotificationContent()
        content.title = "PublicGuard alarm triggered"
        content.body = reason
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "publicguard.alarm.\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    private static var canUseUserNotifications: Bool {
        Bundle.main.bundleIdentifier != nil
    }
}
