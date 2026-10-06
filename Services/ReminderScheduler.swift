import Foundation
import UserNotifications

/// Local notifications for events. They are scheduled with iOS itself, so they still fire if Kept is closed.
enum ReminderScheduler {
    private static var center: UNUserNotificationCenter { .current() }

    private static func identifier(_ reelID: UUID, _ eventID: String, _ lead: Int) -> String {
        "event-\(reelID.uuidString)-\(eventID)-\(lead)"
    }

    /// Asks once when the user first turns on a reminder (not at launch). False when notifications are off.
    static func requestAccess() async -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral: return true
        case .denied: return false
        default: return (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        }
    }

    /// Schedules one reminder. Returns false if the time has already passed or access was refused.
    @discardableResult
    static func schedule(reelID: UUID, reelTitle: String, event: ReelEvent, lead: Int) async -> Bool {
        guard await requestAccess(), let fire = event.fireDate(lead: lead), fire > Date() else { return false }
        let content = UNMutableNotificationContent()
        content.title = event.title
        let where_ = event.location.isEmpty ? "" : " · \(event.location)"
        content.body = (lead == 0 ? "Starting now" : "Starts \(event.whenText)") + where_
        content.subtitle = reelTitle
        content.sound = .default
        content.userInfo = ["reelID": reelID.uuidString]
        var calendar = Calendar.current
        calendar.timeZone = .current
        let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
        let request = UNNotificationRequest(identifier: identifier(reelID, event.id, lead), content: content,
                                            trigger: UNCalendarNotificationTrigger(dateMatching: parts, repeats: false))
        do { try await center.add(request); return true } catch { return false }
    }

    static func cancel(reelID: UUID, eventID: String, lead: Int) {
        center.removePendingNotificationRequests(withIdentifiers: [identifier(reelID, eventID, lead)])
    }

    /// Removes every reminder for an item (it was deleted).
    static func cancelAll(reelID: UUID, events: [ReelEvent]) {
        let ids = events.flatMap { event in (event.reminderLeads ?? []).map { identifier(reelID, event.id, $0) } }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }
}
