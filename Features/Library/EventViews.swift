import SwiftUI

/// The date block used by every event view: month over day.
private struct DateBlock: View {
    let event: ReelEvent

    var body: some View {
        VStack(spacing: 0) {
            Text(event.dayParts.month).font(Theme.Font.body(10, weight: .bold)).foregroundStyle(Theme.accentHighlight)
            Text(event.dayParts.day).font(Theme.Font.display(24)).foregroundStyle(Theme.text)
        }
        .frame(width: 52, height: 56)
        .background(Theme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

/// An event with its calendar button and reminder choices. Shown on every item that contains an event.
struct EventCard: View {
    @EnvironmentObject var store: ReelStore
    let reelID: UUID
    let event: ReelEvent
    @State private var editing = false
    @State private var reminderFailed = false

    private var added: Bool { event.calendarState == .added }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                DateBlock(event: event)
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title).font(Theme.Font.body(16, weight: .semibold)).fixedSize(horizontal: false, vertical: true)
                    Text(event.whenText).font(Theme.Font.body(13)).foregroundStyle(Theme.textSecondary)
                    if !event.location.isEmpty {
                        Label(event.location, systemImage: "mappin.circle.fill")
                            .font(Theme.Font.body(12)).foregroundStyle(Theme.placeFg)
                    }
                    if event.needsCheck && !event.isPast {
                        Label("Check the date", systemImage: "exclamationmark.circle.fill")
                            .font(Theme.Font.body(11, weight: .semibold)).foregroundStyle(Theme.accentHighlight)
                    }
                }
                Spacer(minLength: 0)
            }
            if !event.notes.isEmpty {
                Text(event.notes).font(Theme.Font.body(12)).foregroundStyle(Theme.textSecondary)
            }

            if event.isPast {
                Text("This one has already happened").font(Theme.Font.body(12)).foregroundStyle(Theme.textSecondary)
            } else {
                Button { editing = true } label: {
                    Label(added ? "Added to Calendar" : "Add to Calendar",
                          systemImage: added ? "checkmark.circle.fill" : "calendar.badge.plus")
                        .font(Theme.Font.body(14, weight: .semibold))
                        .frame(maxWidth: .infinity).frame(height: 44)
                        .background(added ? Theme.placeBg : Theme.text, in: Capsule())
                        .foregroundStyle(added ? Theme.placeFg : Theme.background)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("REMIND ME").font(Theme.Font.body(10, weight: .bold)).foregroundStyle(Theme.textSecondary)
                    HStack(spacing: 8) {
                        ForEach(event.availableLeads, id: \.self) { lead in reminderChip(lead) }
                    }
                }
            }
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .sheet(isPresented: $editing) {
            CalendarEventEditor(event: event) { saved in
                editing = false
                if saved { store.setCalendarState(.added, reelID: reelID, eventID: event.id) }
            }
        }
        .alert("Couldn't set that reminder", isPresented: $reminderFailed) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Notifications for Kept may be turned off in Settings, or that time has already passed.")
        }
    }

    private func reminderChip(_ lead: Int) -> some View {
        let on = event.reminderLeads?.contains(lead) == true
        let possible = (event.fireDate(lead: lead) ?? .distantPast) > Date()
        return Button {
            Task { if await store.toggleReminder(reelID: reelID, eventID: event.id, lead: lead) == nil { reminderFailed = true } }
        } label: {
            Label(ReelEvent.leadLabel(lead, allDay: event.allDay), systemImage: on ? "bell.fill" : "bell")
                .font(Theme.Font.body(12, weight: .semibold))
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(on ? Theme.aiBg : Theme.surface2, in: Capsule())
                .foregroundStyle(on ? Theme.aiFg : (possible ? Theme.text : Theme.textSecondary))
        }
        .disabled(!possible && !on)
    }
}

/// A one-line prompt at the top of a screen: "Kept found an event. Add it to your calendar?"
struct EventPromptCard: View {
    @EnvironmentObject var store: ReelStore
    @State private var editing = false

    var body: some View {
        if let pending = store.pendingEventPrompt {
            let reel = pending.reel, event = pending.event
            VStack(alignment: .leading, spacing: 12) {
                Label("Kept found an event", systemImage: "sparkles")
                    .font(Theme.Font.body(12, weight: .semibold)).foregroundStyle(Theme.aiFg)
                HStack(alignment: .top, spacing: 12) {
                    DateBlock(event: event)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(event.title).font(Theme.Font.body(15, weight: .semibold)).lineLimit(2)
                        Text(event.whenText).font(Theme.Font.body(12)).foregroundStyle(Theme.textSecondary)
                        Text("From \(reel.title ?? "a saved item")").font(Theme.Font.body(11))
                            .foregroundStyle(Theme.textSecondary).lineLimit(1)
                    }
                    Spacer(minLength: 0)
                }
                HStack(spacing: 10) {
                    Button { editing = true } label: {
                        Text("Add to Calendar").font(Theme.Font.body(14, weight: .semibold))
                            .frame(maxWidth: .infinity).frame(height: 42)
                            .background(Theme.text, in: Capsule()).foregroundStyle(Theme.background)
                    }
                    Button {
                        store.setCalendarState(.dismissed, reelID: reel.id, eventID: event.id)
                    } label: {
                        Text("No thanks").font(Theme.Font.body(14, weight: .semibold))
                            .padding(.horizontal, 18).frame(height: 42)
                            .background(Theme.surface2, in: Capsule()).foregroundStyle(Theme.text)
                    }
                }
            }
            .padding(16)
            .background(Theme.aiBg, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .padding(.horizontal, 16).padding(.top, 14)
            .sheet(isPresented: $editing) {
                CalendarEventEditor(event: event) { saved in
                    editing = false
                    if saved { store.setCalendarState(.added, reelID: reel.id, eventID: event.id) }
                }
            }
        }
    }
}

/// One row in "Coming up".
struct UpcomingEventRow: View {
    let reel: Reel
    let event: ReelEvent

    var body: some View {
        HStack(spacing: 12) {
            DateBlock(event: event)
            VStack(alignment: .leading, spacing: 3) {
                Text(event.title).font(Theme.Font.body(15, weight: .semibold)).lineLimit(2).foregroundStyle(Theme.text)
                Text(event.whenText).font(Theme.Font.body(12)).foregroundStyle(Theme.textSecondary)
                Text(reel.title ?? "").font(Theme.Font.body(11)).foregroundStyle(Theme.aiFg).lineLimit(1)
            }
            Spacer(minLength: 4)
            if event.calendarState == .added {
                Image(systemName: "calendar.badge.checkmark").foregroundStyle(Theme.placeFg)
            }
            if (event.reminderLeads ?? []).isEmpty == false {
                Image(systemName: "bell.fill").font(.system(size: 12)).foregroundStyle(Theme.aiFg)
            }
        }
        .padding(12).frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
