import SwiftUI
import EventKit
import EventKitUI

/// Apple's own "New Event" screen, pre-filled. The user reviews it and taps Add, so Kept never writes to the
/// calendar silently. On iOS 17 this screen needs no calendar permission.
struct CalendarEventEditor: UIViewControllerRepresentable {
    let event: ReelEvent
    /// true when the user saved the event, false when they cancelled.
    let onFinish: (Bool) -> Void

    func makeUIViewController(context: Context) -> EKEventEditViewController {
        let store = EKEventStore()
        let draft = EKEvent(eventStore: store)
        draft.title = event.title
        draft.startDate = event.start
        draft.isAllDay = event.allDay
        draft.endDate = event.end ?? (event.allDay ? event.start : event.start.addingTimeInterval(3600))
        draft.timeZone = TimeZone(identifier: event.timeZoneID)
        if !event.location.isEmpty { draft.location = event.location }
        if !event.notes.isEmpty { draft.notes = event.notes }
        let controller = EKEventEditViewController()
        controller.eventStore = store
        controller.event = draft
        controller.editViewDelegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: EKEventEditViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onFinish: onFinish) }

    final class Coordinator: NSObject, EKEventEditViewDelegate {
        let onFinish: (Bool) -> Void
        init(onFinish: @escaping (Bool) -> Void) { self.onFinish = onFinish }

        func eventEditViewController(_ controller: EKEventEditViewController,
                                     didCompleteWith action: EKEventEditViewAction) {
            // The SwiftUI sheet that hosts this screen is closed by the caller; no manual dismiss here.
            onFinish(action == .saved)
        }
    }
}
