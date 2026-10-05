import SwiftUI
import Combine

/// Single source of truth for reels and boards. Backed by MockReelService
/// today; swap `service` for a real network-backed implementation later
/// without touching any view.
@MainActor
final class ReelStore: ObservableObject {
    @Published private(set) var reels: [Reel] = []
    @Published private(set) var boards: [Board] = []

    private let service: ReelService
    private var tickTimer: AnyCancellable?

    init(service: ReelService = MockReelService()) {
        self.service = service
        self.reels = service.seedReels()
        self.boards = service.seedBoards()
        // Advance any in-flight processing every 1.6s, mirroring the design's pacing.
        tickTimer = Timer.publish(every: 1.6, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.advanceProcessing() }
    }

    var liveReels: [Reel] { reels.filter { $0.status.isLive } }
    var readyReels: [Reel] { reels.filter { !$0.status.isLive } }

    func board(_ id: UUID?) -> Board? { boards.first { $0.id == id } }
    func reels(in boardID: UUID) -> [Reel] { reels.filter { $0.boardID == boardID } }

    func toggleLike(_ reel: Reel) {
        guard let i = reels.firstIndex(where: { $0.id == reel.id }) else { return }
        reels[i].liked.toggle()
    }

    func togglePoint(_ reel: Reel, point: KeepPoint) {
        guard let ri = reels.firstIndex(where: { $0.id == reel.id }),
              let pi = reels[ri].points.firstIndex(where: { $0.id == point.id }) else { return }
        reels[ri].points[pi].done.toggle()
    }

    func update(_ reel: Reel) {
        guard let i = reels.firstIndex(where: { $0.id == reel.id }) else { return }
        reels[i] = reel
    }

    /// Simulates the backend moving a processing reel forward one step.
    private func advanceProcessing() {
        for i in reels.indices where reels[i].status.isLive {
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

    /// Called by the share extension hand-off: adds a queued reel for a freshly shared URL.
    func ingest(sourceURL: String) {
        let reel = Reel(sourceURL: sourceURL, author: "unknown", coverImageName: "cover_ramen",
                         duration: "0:00", status: .downloading)
        reels.insert(reel, at: 0)
    }

    /// Call on app foreground: picks up a reel the share extension stashed
    /// in the App Group while the app wasn't running.
    func ingestPendingShareIfAny() {
        guard let defaults = AppGroup.defaults,
              let url = defaults.string(forKey: AppGroup.pendingURLKey) else { return }
        defaults.removeObject(forKey: AppGroup.pendingURLKey)
        ingest(sourceURL: url)
    }
}

protocol ReelService {
    func seedReels() -> [Reel]
    func seedBoards() -> [Board]
    /// Fill in the final extracted content once a reel reaches `.ready`.
    func finalize(_ reel: inout Reel)
}
