import Foundation
import UserNotifications

struct NotificationAction {
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func sendAlarmNotification(reason: String) {
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
}
