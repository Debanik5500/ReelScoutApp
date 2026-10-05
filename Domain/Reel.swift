import Foundation

enum ReelStatus: String, Codable {
    case queued, downloading, watching, keyMoments, placesAndBoard, ready, failed

    var stepIndex: Int {
        switch self {
        case .queued: return -1
        case .downloading: return 0
        case .watching: return 1
        case .keyMoments: return 2
        case .placesAndBoard: return 3
        case .ready, .failed: return 4
        }
    }
    var label: String {
        switch self {
        case .queued: return "Queued"
        case .downloading: return "Downloading"
        case .watching: return "Watching"
        case .keyMoments: return "Key moments"
        case .placesAndBoard: return "Places & board"
        case .ready: return "Ready"
        case .failed: return "Couldn't process"
        }
    }
    var isLive: Bool { self != .ready && self != .failed }
}

struct KeyMoment: Identifiable, Codable, Hashable {
    let id: UUID
    var timestamp: String
    var label: String
    var note: String
    var imageName: String
    var frameURL: String?

    init(id: UUID = UUID(), timestamp: String, label: String, note: String, imageName: String, frameURL: String? = nil) {
        self.id = id; self.timestamp = timestamp; self.label = label; self.note = note; self.imageName = imageName; self.frameURL = frameURL
    }
}

struct KeepPoint: Identifiable, Codable, Hashable {
    let id: UUID
    var text: String
    var done: Bool = false
    init(id: UUID = UUID(), text: String, done: Bool = false) {
        self.id = id; self.text = text; self.done = done
    }
}

struct ReelPlace: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var subtitle: String
    var mapURL: String
    init(id: UUID = UUID(), name: String, subtitle: String, mapURL: String) {
        self.id = id; self.name = name; self.subtitle = subtitle; self.mapURL = mapURL
    }
}

struct Board: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    init(id: UUID = UUID(), name: String) { self.id = id; self.name = name }
}

struct Reel: Identifiable, Codable, Hashable {
    let id: UUID
    var sourceURL: String
    var author: String
    var coverImageName: String
    var coverURL: String?
    var duration: String
    var savedAt: Date

    var status: ReelStatus
    var progress: Double

    var title: String?
    var gist: String?
    var keyMoments: [KeyMoment]
    var points: [KeepPoint]
    var place: ReelPlace?
    var boardID: UUID?
    var category: String
    var platformID: String
    var liked: Bool = false

    var isNamed: Bool { title != nil }

    init(
        id: UUID = UUID(), sourceURL: String, author: String, coverImageName: String,
        duration: String, savedAt: Date = .now, status: ReelStatus, progress: Double = 0,
        title: String? = nil, gist: String? = nil, keyMoments: [KeyMoment] = [],
        points: [KeepPoint] = [], place: ReelPlace? = nil, boardID: UUID? = nil,
        category: String = "Food", platformID: String? = nil, liked: Bool = false,
        coverURL: String? = nil
    ) {
        self.id = id; self.sourceURL = sourceURL; self.author = author
        self.coverImageName = coverImageName; self.duration = duration; self.savedAt = savedAt
        self.status = status; self.progress = progress; self.title = title; self.gist = gist
        self.keyMoments = keyMoments; self.points = points; self.place = place
        self.boardID = boardID; self.category = category
        self.platformID = platformID ?? PlatformRegistry.detect(from: sourceURL).id
        self.liked = liked
        self.coverURL = coverURL
    }
}
