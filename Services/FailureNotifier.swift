import Foundation
import UserNotifications

/// Local notifications for reels Kept couldn't read. A failed reel is removed after `ReelStore.failedGrace`
/// unless the user retries, and the notification says so. Retry works straight from the notification.
///
/// These are local notifications: they appear while the app is running (foreground or recently backgrounded).
/// A closed app cannot learn about a failure without a push service.
final class FailureNotifier: NSObject, UNUserNotificationCenterDelegate {
    static let shared = FailureNotifier()

    private static let category = "REEL_FAILED"
    private static let retryAction = "RETRY_REEL"
    private let center = UNUserNotificationCenter.current()

    /// Called on the main actor with the reel's id when the user taps Retry on a notification.
    var onRetry: (@MainActor (UUID) -> Void)?

    func configure() {
        center.delegate = self
        let retry = UNNotificationAction(identifier: Self.retryAction, title: "Retry", options: [])
        center.setNotificationCategories([
            UNNotificationCategory(identifier: Self.category, actions: [retry], intentIdentifiers: [])
        ])
    }

    /// Asked once, in context (when the user first adds a reel), never at launch.
    func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func notifyFailure(reelID: UUID, graceMinutes: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Couldn't read your reel"
        content.body = "Retry within \(graceMinutes) minutes or Kept will remove it."
        content.sound = .default
        content.categoryIdentifier = Self.category
        content.userInfo = ["reelID": reelID.uuidString]
        center.add(UNNotificationRequest(identifier: Self.identifier(reelID), content: content, trigger: nil))
    }

    /// Removes the notification once the reel is retried, dismissed or auto-removed.
    func clear(reelID: UUID) {
        center.removeDeliveredNotifications(withIdentifiers: [Self.identifier(reelID)])
        center.removePendingNotificationRequests(withIdentifiers: [Self.identifier(reelID)])
    }

    private static func identifier(_ id: UUID) -> String { "failed-\(id.uuidString)" }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])  // show it even while Kept is open
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.actionIdentifier == Self.retryAction,
           let raw = response.notification.request.content.userInfo["reelID"] as? String,
           let id = UUID(uuidString: raw) {
            Task { @MainActor in self.onRetry?(id) }
        }
        completionHandler()
    }
}
