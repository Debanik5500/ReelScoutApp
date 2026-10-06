import SwiftUI
import Combine

/// Single source of truth for reels and boards.
///
/// The phone is the source of truth: reels are rendered from `ReelDiskCache` at launch and every finished reel
/// is written back to it. The backend is only used to process new reels and to push live progress
/// (server-sent events); losing it never removes anything the phone already holds.
@MainActor
final class ReelStore: ObservableObject {
    @Published private(set) var reels: [Reel] = []
    @Published private(set) var boards: [Board] = []
    /// This device's monthly reel allowance (nil until the server has answered once).
    @Published private(set) var quota: Quota?
    @Published private(set) var plans: [Plan] = ReelStore.cachedPlans()
    /// Drives the plans sheet: opened from the header, the reels-left pill, or when the limit is reached.
    @Published var showingPlans = false

    private let service: ReelService
    private let api = ReelAPIClient.shared
    private var tickTimer: AnyCancellable?
    private var syncTask: Task<Void, Never>?
    /// Mock seed reels that still animate locally (only used before the first real sync).
    private var simulatedIDs: Set<UUID> = []
    private var showingSeeds = false

    /// How long a failed reel stays (so it can be retried) before Kept removes it.
    static let failedGrace: TimeInterval = 120

    private enum PredefinedCategory: String, CaseIterable, Identifiable {
        case food = "Food"
        case travel = "Travel"
        case fitness = "Fitness"
        case home = "Home"
        case tech = "Tech"
        case shopping = "Shopping"
        case learning = "Learning"
        case entertainment = "Entertainment"

        var id: String { rawValue }
    }

    init(service: ReelService = MockReelService()) {
        self.service = service
        let cached = ReelDiskCache.loadReels()
        if cached.isEmpty {
            reels = service.seedReels()
            boards = service.seedBoards()
            showingSeeds = true
            simulatedIDs = Set(reels.filter { $0.status.isLive }.map(\.id))
        } else {
            reels = cached
            boards = Self.boards(for: cached.filter { !$0.isCapture })
        }
        FailureNotifier.shared.configure()
        FailureNotifier.shared.onRetry = { [weak self] id in
            guard let self, let reel = self.reels.first(where: { $0.id == id }) else { return }
            self.retry(reel)
        }
        // Mirrors the design's pacing for the offline demo reels; also expires failed reels.
        tickTimer = Timer.publish(every: 1.6, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.advanceSimulatedProcessing()
                self?.expireFailures()
            }

        // The share extension submits reels itself and needs to know where the server is.
        AppGroup.defaults?.set(ReelAPIClient.baseURL.absoluteString, forKey: AppGroup.baseURLKey)

        startSync()
    }

    // MARK: - Plan and quota

    private static let plansKey = "cachedPlans"

    private static func cachedPlans() -> [Plan] {
        guard let data = UserDefaults.standard.data(forKey: plansKey),
              let config = try? JSONDecoder().decode(PlansConfig.self, from: data) else {
            return PlansConfig.fallback.plans
        }
        return config.plans
    }

    /// Reels left this month, and the plan list. Failures are ignored: the last known values stay.
    func refreshQuota() async {
        if let latest = try? await api.fetchQuota() { quota = latest }
        if let config = try? await api.fetchPlans(), !config.plans.isEmpty {
            plans = config.plans
            if let data = try? JSONEncoder().encode(config) { UserDefaults.standard.set(data, forKey: Self.plansKey) }
        }
    }

    // MARK: - Sync (snapshot + live events)

    /// (Re)connects to the backend: fetches everything once, then follows live progress until the connection
    /// drops, and retries with backoff. Safe to call repeatedly (e.g. on app foreground).
    func startSync() {
        syncTask?.cancel()
        syncTask = Task { [weak self] in
            var delay: Double = 1
            while !Task.isCancelled {
                guard let self else { return }
                do {
                    try await self.loadBackendReels()
                    await self.refreshQuota()
                    for try await event in self.api.events() {
                        delay = 1
                        self.apply(event)
                    }
                } catch {
                    // Unreachable backend: keep showing what is on the phone.
                }
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                delay = min(delay * 2, 30)
            }
        }
    }

    /// Pull-to-refresh: re-fetches from the backend and merges. If the server is unreachable the phone's reels
    /// stay as they are and the live stream is retried in the background.
    func refresh() async {
        do {
            try await loadBackendReels()
        } catch {
            startSync()
        }
    }

    /// Merges the backend list into the phone's reels. Phone-only reels are kept, user state (likes, checked
    /// points) is carried over, and finished reels are persisted with their images.
    private func loadBackendReels() async throws {
        let backendReels = try await api.fetchReels()
        if showingSeeds {
            reels = []
            simulatedIDs = []
            showingSeeds = false
        }
        for reel in backendReels { merge(reel) }
        let serverIDs = Set(backendReels.map(\.id))
        // A failed card that came from the server is gone once the server forgets it.
        reels.removeAll { $0.status == .failed && $0.jobID != nil && !serverIDs.contains($0.id) }
        // A reel still "processing" that the server no longer knows (the server restarted) will never finish:
        // turn it into a failed card so it can be retried instead of spinning forever.
        for i in reels.indices where reels[i].status.isLive && reels[i].jobID != nil && !serverIDs.contains(reels[i].id) {
            reels[i].status = .failed
            reels[i].errorMessage = "The server restarted while reading this reel."
        }
        trackFailures()
        reorder()
        rebuildBoards()
        persist()
        prefetchImages(for: backendReels.filter { !$0.status.isLive })
    }

    private func apply(_ event: ReelEvent) {
        switch event {
        case .snapshot(let live):
            for reel in live { merge(reel) }
        case .progress(let reel):
            merge(reel)
        case .ready(let reel):
            merge(reel)
            prefetchImages(for: [reel])
            Task { await refreshQuota() }
        case .removed(let jobID, _):
            // Duplicate of a reel we already hold: drop the card, then re-sync so the real one is present.
            let id = ReelAPIClient.stableUUID(from: jobID)
            reels.removeAll { $0.id == id && $0.status.isLive }
            Task { await refresh(); await refreshQuota() }
        }
        trackFailures()
        reorder()
        rebuildBoards()
        persist()
    }

    /// Inserts or updates one backend reel. A reel the user just shared (queued, no job id yet) is adopted by
    /// matching its source URL, so the card never duplicates or jumps.
    private func merge(_ incoming: Reel) {
        var incoming = incoming
        if let i = reels.firstIndex(where: { $0.id == incoming.id }) {
            incoming.liked = reels[i].liked
            incoming.savedAt = reels[i].savedAt
            incoming.failedAt = reels[i].failedAt
            if let old = reels[i].events, var fresh = incoming.events {
                for k in fresh.indices {
                    if let match = old.first(where: { $0.id == fresh[k].id }) {
                        fresh[k].calendarState = match.calendarState  // the user's choices survive a re-sync
                        fresh[k].reminderLeads = match.reminderLeads
                    }
                }
                incoming.events = fresh
            }
            let done = Set(reels[i].points.filter(\.done).map(\.id))
            for p in incoming.points.indices where done.contains(incoming.points[p].id) {
                incoming.points[p].done = true
            }
            // A finished reel is never downgraded: not to a live state (late or out-of-order event) and not to
            // "failed" (a failed re-run must not replace, and then auto-delete, a reel the user already saved).
            if reels[i].status == .ready && incoming.status != .ready { return }
            if !reels[i].status.isLive && incoming.status.isLive { return }
            reels[i] = incoming
        } else if !incoming.sourceURL.isEmpty,
                  let i = reels.firstIndex(where: { $0.status == .queued && ReelAPIClient.sameReel($0.sourceURL, incoming.sourceURL) }) {
            incoming.savedAt = reels[i].savedAt
            reels[i] = incoming
        } else {
            reels.append(incoming)
        }
    }

    /// Keeps one entry per reel id (preferring a finished one over a live one), then orders live first.
    private func reorder() {
        var best: [UUID: Reel] = [:]
        for reel in reels {
            if let existing = best[reel.id], !existing.status.isLive || reel.status.isLive { continue }
            best[reel.id] = reel
        }
        var seen = Set<UUID>()
        reels = reels.compactMap { reel in
            guard seen.insert(reel.id).inserted else { return nil }
            return best[reel.id]
        }
        let position = Dictionary(uniqueKeysWithValues: reels.enumerated().map { ($1.id, $0) })
        reels.sort { a, b in
            if a.status.isLive != b.status.isLive { return a.status.isLive }
            if a.savedAt != b.savedAt { return a.savedAt > b.savedAt }
            return (position[a.id] ?? 0) < (position[b.id] ?? 0)
        }
    }

    // MARK: - Boards

    /// Boards are derived from the categories present in the reels.
    private static func boards(for reels: [Reel]) -> [Board] {
        let present = Set(reels.map(\.category))
        return PredefinedCategory.allCases
            .filter { present.contains($0.rawValue) }
            .map { Board(id: ReelAPIClient.stableUUID(from: "board:\($0.rawValue)"), name: $0.rawValue) }
    }

    /// Reels whose category has no predefined board appear under "All" only.
    private func rebuildBoards() {
        let newBoards = Self.boards(for: libraryReels)
        let idByName = Dictionary(uniqueKeysWithValues: newBoards.map { ($0.name, $0.id) })
        for i in reels.indices { reels[i].boardID = reels[i].isCapture ? nil : idByName[reels[i].category] }
        boards = newBoards
    }

    // MARK: - Persistence

    private func persist() {
        ReelDiskCache.save(reels.filter { !$0.status.isLive && $0.status != .failed && !simulatedIDs.contains($0.id) })
    }

    private func prefetchImages(for finished: [Reel]) {
        guard !finished.isEmpty else { return }
        Task.detached(priority: .utility) { [api] in
            for reel in finished { await api.prefetchImages(for: reel) }
        }
    }

    // MARK: - Queries & edits

    /// Reels and posts (the Library). Screenshots and saved pages live in the Captures tab.
    var libraryReels: [Reel] { reels.filter { !$0.isCapture } }
    var captures: [Reel] { reels.filter { $0.isCapture } }
    var liveReels: [Reel] { reels.filter { $0.status.isLive && !$0.isCapture } }
    var readyReels: [Reel] { reels.filter { !$0.status.isLive && $0.status != .failed && !$0.isCapture } }

    func board(_ id: UUID?) -> Board? { boards.first { $0.id == id } }
    func reels(in boardID: UUID) -> [Reel] { reels.filter { $0.boardID == boardID } }

    func toggleLike(_ reel: Reel) {
        guard let i = reels.firstIndex(where: { $0.id == reel.id }) else { return }
        reels[i].liked.toggle()
        persist()
    }

    func togglePoint(_ reel: Reel, point: KeepPoint) {
        guard let ri = reels.firstIndex(where: { $0.id == reel.id }),
              let pi = reels[ri].points.firstIndex(where: { $0.id == point.id }) else { return }
        reels[ri].points[pi].done.toggle()
        persist()
    }

    func update(_ reel: Reel) {
        guard let i = reels.firstIndex(where: { $0.id == reel.id }) else { return }
        reels[i] = reel
        persist()
    }

    // MARK: - Failed reels

    /// First time a reel is seen failing: start its removal countdown and notify once.
    private func trackFailures() {
        for i in reels.indices where reels[i].status == .failed && reels[i].failedAt == nil {
            reels[i].failedAt = Date()
            FailureNotifier.shared.notifyFailure(reelID: reels[i].id, graceMinutes: Int(Self.failedGrace / 60))
        }
    }

    /// Removes failed reels whose grace period ran out (the user did not retry).
    private func expireFailures() {
        let cutoff = Date().addingTimeInterval(-Self.failedGrace)
        for reel in reels where reel.status == .failed {
            if let failedAt = reel.failedAt, failedAt < cutoff { remove(reel) }
        }
    }

    func remove(_ reel: Reel) {
        FailureNotifier.shared.clear(reelID: reel.id)
        ReminderScheduler.cancelAll(reelID: reel.id, events: reel.eventList)
        if reel.status == .failed, let jobID = reel.jobID {
            Task { await api.dismiss(jobID: jobID) }
        }
        reels.removeAll { $0.id == reel.id }
        rebuildBoards()
        persist()
    }

    // MARK: - Ingest

    /// Share-extension hand-off: shows a queued card immediately, then asks the backend to process the reel.
    /// Later progress arrives over the event stream and is matched back to this card by source URL.
    /// Anything shared or pasted: a reel or post link, a web page, a Google search link.
    func ingest(sourceURL: String) {
        let link = sourceURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if AppGroup.isSupportedLink(link) {
            guard canStartNewItem() else { return }
            // Already in the library (or already queued): nothing to do.
            guard !reels.contains(where: { ReelAPIClient.sameReel($0.sourceURL, link) && $0.status != .failed }) else { return }
            enqueue(Reel(sourceURL: link, author: "", coverImageName: "cover_placeholder",
                         duration: "0:00", status: .queued, kind: "reel")) { try await self.api.submitReel(url: link) }
        } else if AppGroup.isWebLink(link) {
            guard canStartNewItem() else { return }
            guard !reels.contains(where: { $0.kind == "webpage" && $0.sourceURL == link && $0.status != .failed }) else { return }
            enqueue(Reel(sourceURL: link, author: "", coverImageName: "cover_placeholder",
                         duration: "0:00", status: .queued, kind: "webpage")) { try await self.api.submitWeb(url: link, text: nil) }
        }
    }

    /// Pasted or shared text (for example a copied fixture list) with no link.
    func ingest(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 12, canStartNewItem() else { return }
        enqueue(Reel(sourceURL: "", author: "", coverImageName: "cover_placeholder", duration: "0:00",
                     status: .queued, kind: "webpage")) { try await self.api.submitWeb(url: nil, text: trimmed) }
    }

    /// 1-10 screenshots as one item. `images` are JPEGs, already shrunk by the caller.
    func ingestScreenshots(_ images: [Data]) {
        guard !images.isEmpty, canStartNewItem() else { return }
        enqueue(Reel(sourceURL: "", author: "", coverImageName: "cover_placeholder", duration: "0:00",
                     status: .queued, kind: "screenshot")) { try await self.api.uploadScreenshots(images) }
    }

    /// Out of items this month: show the plans instead of starting. Also asks for notification access once.
    private func canStartNewItem() -> Bool {
        if quota?.isOut == true { showingPlans = true; return false }
        FailureNotifier.shared.requestAuthorization()
        return true
    }

    private func enqueue(_ reel: Reel, send: @escaping () async throws -> String) {
        reels.insert(reel, at: 0)
        Task { await submit(localID: reel.id, send: send) }
    }

    private func submit(localID: UUID, send: () async throws -> String) async {
        do {
            let jobID = try await send()
            Task { await refreshQuota() }
            // Adopt the backend's id right away so later events update this very card.
            let newID = ReelAPIClient.stableUUID(from: jobID)
            if let i = reels.firstIndex(where: { $0.id == localID }) {
                if reels.contains(where: { $0.id == newID }) { reels.remove(at: i) } else { reels[i].id = newID }
            }
            startSync()  // make sure the event stream is live to follow this job
        } catch {
            guard let i = reels.firstIndex(where: { $0.id == localID }) else { return }
            if case ReelAPIError.badStatus(let code) = error, [413, 422].contains(code) {
                reels.remove(at: i)  // the server says it can't be read: nothing to keep
                return
            }
            if case ReelAPIError.quotaExceeded(let latest) = error {
                reels.remove(at: i)  // not processed, so nothing to show
                quota = latest
                showingPlans = true
                return
            }
            reels[i].status = .failed
            reels[i].errorMessage = "Couldn't reach the Kept server"
            trackFailures()
        }
    }

    // MARK: - Events (calendar and reminders)

    /// Every event not yet past, soonest first, across reels, posts, screenshots and pages.
    var upcomingEvents: [(reel: Reel, event: ReelEvent)] {
        reels.filter { !$0.status.isLive && $0.status != .failed }
            .flatMap { reel in reel.eventList.filter { !$0.isPast }.map { (reel: reel, event: $0) } }
            .sorted { $0.event.start < $1.event.start }
    }

    /// The first upcoming event the user has not yet answered "add to calendar?" for.
    var pendingEventPrompt: (reel: Reel, event: ReelEvent)? {
        upcomingEvents.first { $0.event.calendarState == nil }
    }

    func setCalendarState(_ state: CalendarState, reelID: UUID, eventID: String) {
        updateEvent(reelID: reelID, eventID: eventID) { $0.calendarState = state }
    }

    /// Turns one reminder on or off. Returns the new state, or nil when it could not be scheduled
    /// (notifications refused, or the time has passed).
    @discardableResult
    func toggleReminder(reelID: UUID, eventID: String, lead: Int) async -> Bool? {
        guard let reel = reels.first(where: { $0.id == reelID }),
              let event = reel.eventList.first(where: { $0.id == eventID }) else { return nil }
        let isOn = event.reminderLeads?.contains(lead) == true
        if isOn {
            ReminderScheduler.cancel(reelID: reelID, eventID: eventID, lead: lead)
            updateEvent(reelID: reelID, eventID: eventID) { $0.reminderLeads = ($0.reminderLeads ?? []).filter { $0 != lead } }
            return false
        }
        guard await ReminderScheduler.schedule(reelID: reelID, reelTitle: reel.title ?? "Kept", event: event, lead: lead) else {
            return nil
        }
        updateEvent(reelID: reelID, eventID: eventID) { $0.reminderLeads = ((($0.reminderLeads ?? []) + [lead]).sorted()) }
        return true
    }

    private func updateEvent(reelID: UUID, eventID: String, _ change: (inout ReelEvent) -> Void) {
        guard let r = reels.firstIndex(where: { $0.id == reelID }),
              let e = reels[r].events?.firstIndex(where: { $0.id == eventID }) else { return }
        change(&reels[r].events![e])
        persist()
    }

    /// Re-submits a failed reel.
    func retry(_ reel: Reel) {
        remove(reel)
        // A failed screenshot upload can't be retried (the images are not kept): it is simply removed.
        if !reel.sourceURL.isEmpty { ingest(sourceURL: reel.sourceURL) }
    }

    /// Call on app foreground: picks up a reel the share extension stashed in the App Group while the app
    /// wasn't running, and reconnects the live stream.
    func ingestPendingShareIfAny() {
        startSync()
        guard let defaults = AppGroup.defaults,
              let url = defaults.string(forKey: AppGroup.pendingURLKey) else { return }
        defaults.removeObject(forKey: AppGroup.pendingURLKey)
        ingest(sourceURL: url)
    }

    // MARK: - Demo simulation (seed reels only)

    private func advanceSimulatedProcessing() {
        for i in reels.indices where simulatedIDs.contains(reels[i].id) && reels[i].status.isLive {
            let order: [ReelStatus] = [.downloading, .watching, .keyMoments, .placesAndBoard, .ready]
            guard let idx = order.firstIndex(of: reels[i].status) else { continue }
            if reels[i].progress < 1 {
                reels[i].progress = min(1, reels[i].progress + 0.5)
            } else if idx + 1 < order.count {
                reels[i].status = order[idx + 1]
                reels[i].progress = 0
                if reels[i].status == .ready { service.finalize(&reels[i]) }
            }
        }
    }
}

protocol ReelService {
    func seedReels() -> [Reel]
    func seedBoards() -> [Board]
    /// Fill in the final extracted content once a reel reaches `.ready`.
    func finalize(_ reel: inout Reel)
}
