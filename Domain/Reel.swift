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
    /// Only present when the backend verified the place via a geocoder.
    var latitude: Double?
    var longitude: Double?
    /// "exact", "area" or "city": how specific the pin is. Optional so older saved reels still decode.
    var precision: String?
    /// Plain-language caveat, e.g. "Exact address not shared in the reel; near Manu Temple".
    var note: String?
    init(id: UUID = UUID(), name: String, subtitle: String, mapURL: String,
         latitude: Double? = nil, longitude: Double? = nil, precision: String? = nil, note: String? = nil) {
        self.id = id; self.name = name; self.subtitle = subtitle; self.mapURL = mapURL
        self.latitude = latitude; self.longitude = longitude
        self.precision = precision; self.note = note
    }

    /// True when the pin is only approximate (an area or a city, not the exact venue).
    var isApproximate: Bool { precision == "area" || precision == "city" }

    var coordinate: (latitude: Double, longitude: Double)? {
        guard let latitude, let longitude else { return nil }
        return (latitude, longitude)
    }
}

struct ReelLink: Identifiable, Codable, Hashable {
    let id: UUID
    var label: String
    var url: String
    var kind: String
    /// One line on what it is. Optional so reels saved before this existed still decode.
    var note: String?
    init(id: UUID = UUID(), label: String, url: String, kind: String = "", note: String? = nil) {
        self.id = id; self.label = label; self.url = url; self.kind = kind; self.note = note
    }
}

struct ReelProduct: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var brand: String
    var url: String
    init(id: UUID = UUID(), name: String, brand: String = "", url: String = "") {
        self.id = id; self.name = name; self.brand = brand; self.url = url
    }
}

struct ReelPerson: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var role: String
    init(id: UUID = UUID(), name: String, role: String = "") {
        self.id = id; self.name = name; self.role = role
    }
}

struct ReelSource: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var url: String
    init(id: UUID = UUID(), title: String, url: String) {
        self.id = id; self.title = title; self.url = url
    }
}

struct Board: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    init(id: UUID = UUID(), name: String) { self.id = id; self.name = name }
}

struct Reel: Identifiable, Codable, Hashable {
    var id: UUID
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
    /// A list reel ("5 places near Siliguri") has more than one place. Optional so older saved reels still decode.
    var extraPlaces: [ReelPlace]?
    /// "reel", "post", "screenshot" or "webpage". Optional so older saved items still decode.
    var kind: String?
    /// For screenshots and pages: event, ticket, schedule, article, ...
    var shotType: String?
    /// Dated things found in this item, with the user's calendar and reminder choices.
    var events: [ReelEvent]?
    /// Optional content blocks. Empty means the reel has none; views render a block only when non-empty.
    var links: [ReelLink] = []
    var products: [ReelProduct] = []
    var people: [ReelPerson] = []
    var sources: [ReelSource] = []
    /// Live processing only: per-step detail ("0:42 video"), finding chips, failure reason.
    var stepDetails: [String: String] = [:]
    var chips: [String] = []
    var errorMessage: String = ""
    /// Backend job id (the id on the server), when the reel came from the backend.
    var jobID: String?
    /// When this reel was first seen failing; it is removed `ReelStore.failedGrace` later unless retried.
    var failedAt: Date?
    var boardID: UUID?
    var category: String
    var platformID: String
    var liked: Bool = false

    var isNamed: Bool { title != nil }

    /// Screenshots and saved pages live in the Captures tab, not in the Library.
    var isCapture: Bool { kind == "screenshot" || kind == "webpage" }
    var eventList: [ReelEvent] { events ?? [] }

    /// Every place the reel is about, in the order the reel shows them.
    var places: [ReelPlace] { (place.map { [$0] } ?? []) + (extraPlaces ?? []) }

    init(
        id: UUID = UUID(), sourceURL: String, author: String, coverImageName: String,
        duration: String, savedAt: Date = .now, status: ReelStatus, progress: Double = 0,
        title: String? = nil, gist: String? = nil, keyMoments: [KeyMoment] = [],
        points: [KeepPoint] = [], place: ReelPlace? = nil, boardID: UUID? = nil,
        category: String = "Food", platformID: String? = nil, liked: Bool = false,
        coverURL: String? = nil, links: [ReelLink] = [], products: [ReelProduct] = [],
        people: [ReelPerson] = [], sources: [ReelSource] = [],
        stepDetails: [String: String] = [:], chips: [String] = [], errorMessage: String = "",
        jobID: String? = nil, extraPlaces: [ReelPlace]? = nil,
        kind: String? = nil, shotType: String? = nil, events: [ReelEvent]? = nil
    ) {
        self.id = id; self.sourceURL = sourceURL; self.author = author
        self.coverImageName = coverImageName; self.duration = duration; self.savedAt = savedAt
        self.status = status; self.progress = progress; self.title = title; self.gist = gist
        self.keyMoments = keyMoments; self.points = points; self.place = place
        self.boardID = boardID; self.category = category
        self.platformID = platformID ?? PlatformRegistry.detect(from: sourceURL).id
        self.liked = liked
        self.coverURL = coverURL
        self.links = links; self.products = products; self.people = people; self.sources = sources
        self.stepDetails = stepDetails; self.chips = chips; self.errorMessage = errorMessage
        self.jobID = jobID; self.extraPlaces = extraPlaces
        self.kind = kind; self.shotType = shotType; self.events = events
    }
}
