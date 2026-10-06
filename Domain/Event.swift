import Foundation

enum CalendarState: String, Codable {
    case added      // the user put it in their calendar
    case dismissed  // the user said no thanks (we stop asking, the card stays available)
}

/// A dated thing Kept found in a reel, post, screenshot or web page.
struct ReelEvent: Identifiable, Codable, Hashable {
    let id: String
    var title: String
    var start: Date
    var end: Date?
    var allDay: Bool
    var timeZoneID: String
    var location: String
    var notes: String
    /// The date was inferred or the time is missing: ask the user to double-check.
    var needsCheck: Bool
    /// User state, kept across syncs.
    var calendarState: CalendarState?
    /// Minutes before the start for which a local notification is scheduled.
    var reminderLeads: [Int]?

    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: timeZoneID) ?? .current
        return cal
    }

    var isPast: Bool {
        if allDay { return calendar.startOfDay(for: start) < calendar.startOfDay(for: Date()) }
        return (end ?? start) < Date()
    }

    /// Reminder lead times that make sense: all-day events have no clock time, so no "1 hour before".
    var availableLeads: [Int] { allDay ? [0, 1440] : [0, 60, 1440] }

    static func leadLabel(_ minutes: Int, allDay: Bool) -> String {
        switch minutes {
        case 0: return allDay ? "Morning of" : "At the time"
        case 60: return "1 hour before"
        case 1440: return allDay ? "Day before" : "1 day before"
        default: return "\(minutes) min before"
        }
    }

    /// When a reminder with this lead fires. All-day events fire at 9:00 in the event's own timezone.
    func fireDate(lead: Int) -> Date? {
        let base: Date
        if allDay {
            guard let nine = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: start) else { return nil }
            base = nine
        } else {
            base = start
        }
        return base.addingTimeInterval(-Double(lead) * 60)
    }

    /// "Sat 14 Nov, 6:30 PM" or "Sat 14 Nov" for all-day events, in the timezone the event was read in.
    var whenText: String {
        let formatter = DateFormatter()
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate(allDay ? "EEE d MMM" : "EEE d MMM jmm")
        return formatter.string(from: start) + (allDay ? " · all day" : "")
    }

    /// Short month and day for the date block.
    var dayParts: (month: String, day: String) {
        let month = DateFormatter(), day = DateFormatter()
        for f in [month, day] { f.timeZone = calendar.timeZone; f.locale = Locale.current }
        month.setLocalizedDateFormatFromTemplate("MMM")
        day.setLocalizedDateFormatFromTemplate("d")
        return (month.string(from: start).uppercased(), day.string(from: start))
    }
}
