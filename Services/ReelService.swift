import Foundation
import UIKit
import CryptoKit

protocol ReelServiceProtocol {
    func fetchReels() async throws -> [Reel]
    func fetchReel(id: String) async throws -> Reel
    func submitReel(url: String) async throws -> String
    func events() -> AsyncThrowingStream<ReelEvent, Error>
    func pollStatus(reelID: String) async throws -> Reel
    func loadImage(from urlString: String) async -> UIImage?
}

/// Server-pushed update. `snapshot` lists every active job (sent on connect); `progress` is one live reel;
/// `ready` carries the finished reel, which the app then stores on the phone.
enum ReelEvent {
    case snapshot([Reel])
    case progress(Reel)
    case ready(Reel)
    /// The server found this job was the same reel as one it already has (reached via another link form).
    case removed(jobID: String, canonicalID: String)
}

enum ReelAPIError: Error {
    case badURL(String)
    case notFound
    case badStatus(Int)
    case quotaExceeded(Quota)
    case notSupported
}

/// Talks to the FastAPI backend. Every path below is relative and is resolved
/// against `baseURL`; image URLs coming back from the API are relative too and
/// get the same treatment in `resolveURL(_:base:)`.
final class ReelAPIClient: ReelServiceProtocol {
    static let shared = ReelAPIClient()

    /// Set `ReelScoutAPIBaseURL` in Info.plist (or UserDefaults) to point a real device at the backend host.
    static let baseURL: URL = {
        let configured = (Bundle.main.object(forInfoDictionaryKey: "ReelScoutAPIBaseURL") as? String)
            ?? UserDefaults.standard.string(forKey: "ReelScoutAPIBaseURL")
        return configured.flatMap(URL.init(string:)) ?? URL(string: "http://localhost:8000")!
    }()

    private let session: URLSession
    private let decoder = JSONDecoder()
    private let imageCache = ImageCache()

    private init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Reels

    func fetchReels() async throws -> [Reel] {
        let data = try await get("/api/v1/reels")
        let payload = try decoder.decode(ReelsResponse.self, from: data)
        return payload.reels.map { $0.toReel() }
    }

    func fetchReel(id: String) async throws -> Reel {
        let data = try await get("/api/v1/reels/\(Self.pathComponent(id))")
        let payload = try decoder.decode(ReelResponse.self, from: data)
        return payload.reel.toReel()
    }

    func pollStatus(reelID: String) async throws -> Reel {
        try await fetchReel(id: reelID)
    }

    // MARK: - Plan and quota

    func fetchQuota() async throws -> Quota {
        try decoder.decode(Quota.self, from: try await get("/api/v1/me"))
    }

    func fetchPlans() async throws -> PlansConfig {
        try decoder.decode(PlansConfig.self, from: try await get("/api/v1/plans"))
    }

    /// Queues the reel for background processing; returns the backend job id.
    func submitReel(url: String) async throws -> String {
        guard let endpoint = URL(string: "/api/v1/reels", relativeTo: Self.baseURL)?.absoluteURL else {
            throw ReelAPIError.badURL("/api/v1/reels")
        }
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(AppGroup.deviceID, forHTTPHeaderField: "X-Device-Id")
        request.httpBody = try JSONEncoder().encode(["url": url])
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            if http.statusCode == 402, let quota = try? decoder.decode(QuotaErrorResponse.self, from: data).detail {
                throw ReelAPIError.quotaExceeded(quota)  // monthly limit reached: the app shows the plans page
            }
            throw ReelAPIError.badStatus(http.statusCode)
        }
        return try decoder.decode(SubmitResponse.self, from: data).id
    }

    /// Tells the server to forget a failed job (the user closed its error card).
    func dismiss(jobID: String) async {
        guard let url = URL(string: "/api/v1/reels/\(Self.pathComponent(jobID))", relativeTo: Self.baseURL)?.absoluteURL else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.timeoutInterval = 15
        _ = try? await session.data(for: request)
    }

    /// Live progress over server-sent events. Ends (throws) when the connection drops; the caller reconnects.
    func events() -> AsyncThrowingStream<ReelEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    guard let endpoint = URL(string: "/api/v1/reels/stream", relativeTo: Self.baseURL)?.absoluteURL else {
                        throw ReelAPIError.badURL("/api/v1/reels/stream")
                    }
                    var request = URLRequest(url: endpoint)
                    request.timeoutInterval = 60  // server sends a keepalive every 15s
                    request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
                    request.setValue(AppGroup.deviceID, forHTTPHeaderField: "X-Device-Id")
                    let (bytes, response) = try await session.bytes(for: request)
                    if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                        throw ReelAPIError.badStatus(http.statusCode)
                    }
                    // `bytes.lines` drops blank lines, so an event is completed by its single `data:` line.
                    var name = "message"
                    for try await line in bytes.lines {
                        if line.hasPrefix("event:") {
                            name = line.dropFirst(6).trimmingCharacters(in: .whitespaces)
                        } else if line.hasPrefix("data:") {
                            let json = Data(line.dropFirst(5).trimmingCharacters(in: .whitespaces).utf8)
                            if let event = try? self.decodeEvent(name: name, data: json) {
                                continuation.yield(event)
                            }
                            name = "message"
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func decodeEvent(name: String, data: Data) throws -> ReelEvent? {
        switch name {
        case "snapshot":
            return .snapshot(try decoder.decode(ReelsResponse.self, from: data).reels.map { $0.toReel() })
        case "progress":
            return .progress(try decoder.decode(EventReelResponse.self, from: data).reel.toReel())
        case "ready":
            return .ready(try decoder.decode(EventReelResponse.self, from: data).reel.toReel())
        case "removed":
            let removed = try decoder.decode(RemovedResponse.self, from: data)
            return .removed(jobID: removed.id, canonicalID: removed.canonical)
        default:
            return nil
        }
    }

    /// Downloads a reel's key-moment frames into the on-disk cache so it opens offline.
    /// (Covers are bundled illustrations, so they need no download.)
    func prefetchImages(for reel: Reel) async {
        let urls = reel.keyMoments.compactMap(\.frameURL)
        for url in urls { _ = await loadImage(from: url) }
    }

    // MARK: - Images

    /// Images already in memory, readable synchronously so a view can show one on its very first frame.
    private static let memoryCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 120
        return cache
    }()

    static func cachedImage(_ urlString: String) -> UIImage? {
        guard let key = resolveURL(urlString)?.absoluteString else { return nil }
        return memoryCache.object(forKey: key as NSString)
    }

    func loadImage(from urlString: String) async -> UIImage? {
        guard let url = Self.resolveURL(urlString) else { return nil }
        let key = url.absoluteString
        if let hot = Self.memoryCache.object(forKey: key as NSString) { return hot }
        if let cached = await imageCache.image(for: key) {
            Self.memoryCache.setObject(cached, forKey: key as NSString)
            return cached
        }
        let file = ReelDiskCache.imageFile(for: key)
        if let data = try? Data(contentsOf: file), let image = UIImage(data: data) {
            await imageCache.setImage(image, for: key)
            Self.memoryCache.setObject(image, forKey: key as NSString)
            return image
        }
        guard let result = try? await session.data(from: url) else { return nil }
        if let http = result.1 as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            return nil
        }
        guard let image = UIImage(data: result.0) else { return nil }
        try? result.0.write(to: file, options: .atomic)
        await imageCache.setImage(image, for: key)
        Self.memoryCache.setObject(image, forKey: key as NSString)
        return image
    }

    // MARK: - URL helpers

    /// Prefixes relative paths with `base`; absolute URLs pass through untouched.
    static func resolveURL(_ string: String?, base: URL? = nil) -> URL? {
        guard let raw = string?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty else { return nil }
        let root = base ?? baseURL
        if let url = URL(string: raw), url.scheme != nil { return url }
        if raw.hasPrefix("/") {
            return URL(string: raw, relativeTo: root)?.absoluteURL
        }
        let directory = URL(string: "./", relativeTo: root)?.absoluteURL ?? root
        return URL(string: raw, relativeTo: directory)?.absoluteURL
    }

    /// Instagram shortcode from a reel URL (`/reel/<code>/`, `/reels/`, `/p/`, `/tv/`); tracking params are ignored.
    static func shortcode(from urlString: String) -> String? {
        guard let path = URL(string: urlString.trimmingCharacters(in: .whitespacesAndNewlines))?.path else { return nil }
        let parts = path.split(separator: "/").map(String.init)
        guard let i = parts.firstIndex(where: { ["reel", "reels", "p", "tv"].contains($0) }),
              parts.indices.contains(i + 1) else { return nil }
        return parts[i + 1]
    }

    /// True when both URLs point at the same reel (same shortcode), else falls back to exact equality.
    static func sameReel(_ a: String, _ b: String) -> Bool {
        if let x = shortcode(from: a), let y = shortcode(from: b) { return x == y }
        return a == b
    }

    /// Stable UUID so a reel keeps the same identity across refreshes.
    static func stableUUID(from string: String) -> UUID {
        let digest = SHA256.hash(data: Data(string.utf8))
        let hex = digest.map { String(format: "%02x", $0) }.joined()
        let first = String(hex.prefix(32))
        let parts = [
            String(first.prefix(8)),
            String(first.dropFirst(8).prefix(4)),
            String(first.dropFirst(12).prefix(4)),
            String(first.dropFirst(16).prefix(4)),
            String(first.dropFirst(20).prefix(12))
        ]
        return UUID(uuidString: parts.joined(separator: "-")) ?? UUID()
    }

    fileprivate static func parseDate(_ value: String?) -> Date? {
        guard let value, !value.isEmpty else { return nil }
        if let date = isoFractional.date(from: value) { return date }
        if let date = isoPlain.date(from: value) { return date }
        if let date = isoLocalFractional.date(from: value) { return date }
        return isoLocalPlain.date(from: value)
    }

    fileprivate static func pathComponent(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? value
    }

    fileprivate static let isoFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    fileprivate static let isoPlain: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    fileprivate static let isoLocalFractional: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        return formatter
    }()

    fileprivate static let isoLocalPlain: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter
    }()

    private func get(_ path: String) async throws -> Data {
        guard let url = URL(string: path, relativeTo: Self.baseURL) else {
            throw ReelAPIError.badURL(path)
        }
        var request = URLRequest(url: url.absoluteURL)
        request.timeoutInterval = 30
        request.setValue(AppGroup.deviceID, forHTTPHeaderField: "X-Device-Id")
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse {
            if http.statusCode == 404 { throw ReelAPIError.notFound }
            guard (200..<300).contains(http.statusCode) else {
                throw ReelAPIError.badStatus(http.statusCode)
            }
        }
        return data
    }
}

actor ImageCache {
    private var cache: [String: UIImage] = [:]

    func image(for key: String) -> UIImage? {
        cache[key]
    }

    func setImage(_ image: UIImage, for key: String) {
        cache[key] = image
    }
}

// MARK: - Wire format (schema_version 2; every field optional, empty means "not in this reel")

private struct ReelsResponse: Decodable {
    let reels: [ReelDTO]
}

private struct ReelResponse: Decodable {
    let reel: ReelDTO
}

private struct EventReelResponse: Decodable {
    let reel: ReelDTO
}

private struct QuotaErrorResponse: Decodable {
    let detail: Quota
}

private struct RemovedResponse: Decodable {
    let id: String
    let canonical: String
}

private struct SubmitResponse: Decodable {
    let id: String
}

private extension KeyedDecodingContainer {
    func string(_ key: Key) -> String { (try? decodeIfPresent(String.self, forKey: key)) ?? "" }
    func list<T: Decodable>(_ key: Key) -> [T] { (try? decodeIfPresent([T].self, forKey: key)) ?? [] }
}

private struct ReelDTO: Decodable {
    let id: String
    let created: String
    let title: String
    let summary: String
    let category: String
    let author: String
    let duration: String
    let coverURL: String
    let status: String
    let progress: Double
    let group: String
    let platform: String
    let sourceURL: String
    let location: LocationDTO
    let places: [LocationDTO]
    let products: [ProductDTO]
    let people: [PersonDTO]
    let links: [LinkDTO]
    let sources: [SourceDTO]
    let keyMoments: [KeyMomentDTO]
    let points: [PointDTO]
    let details: [String: String]
    let chips: [String]
    let error: String

    private enum CodingKeys: String, CodingKey {
        case id, created, title, summary, category, author, duration, status, progress
        case group, platform, location, places, products, people, links, sources, points
        case details, chips, error
        case coverURL = "cover_url"
        case sourceURL = "source_url"
        case keyMoments = "key_moments"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        created = c.string(.created)
        title = c.string(.title)
        summary = c.string(.summary)
        category = c.string(.category)
        author = c.string(.author)
        duration = c.string(.duration)
        coverURL = c.string(.coverURL)
        status = c.string(.status)
        progress = (try? c.decodeIfPresent(Double.self, forKey: .progress)) ?? 1
        group = c.string(.group)
        platform = c.string(.platform)
        sourceURL = c.string(.sourceURL)
        location = (try? c.decodeIfPresent(LocationDTO.self, forKey: .location)) ?? LocationDTO()
        places = c.list(.places)
        products = c.list(.products)
        people = c.list(.people)
        links = c.list(.links)
        sources = c.list(.sources)
        keyMoments = c.list(.keyMoments)
        points = c.list(.points)
        details = (try? c.decodeIfPresent([String: String].self, forKey: .details)) ?? [:]
        chips = c.list(.chips)
        error = c.string(.error)
    }
}

private struct LocationDTO: Decodable {
    var name = ""
    var area = ""
    var city = ""
    var country = ""
    var lat: Double?
    var lng: Double?
    var mapURL = ""
    var precision = ""
    var note = ""

    init() {}

    private enum CodingKeys: String, CodingKey {
        case name, area, city, country, lat, lng, precision, note
        case mapURL = "map_url"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = c.string(.name)
        area = c.string(.area)
        city = c.string(.city)
        country = c.string(.country)
        lat = try? c.decodeIfPresent(Double.self, forKey: .lat)
        lng = try? c.decodeIfPresent(Double.self, forKey: .lng)
        mapURL = c.string(.mapURL)
        precision = c.string(.precision)
        note = c.string(.note)
    }
}

private struct ProductDTO: Decodable {
    let name: String, brand: String, url: String
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = c.string(.name); brand = c.string(.brand); url = c.string(.url)
    }
    private enum CodingKeys: String, CodingKey { case name, brand, url }
}

private struct PersonDTO: Decodable {
    let name: String, role: String
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = c.string(.name); role = c.string(.role)
    }
    private enum CodingKeys: String, CodingKey { case name, role }
}

private struct LinkDTO: Decodable {
    let label: String, url: String, kind: String, note: String
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        label = c.string(.label); url = c.string(.url); kind = c.string(.kind); note = c.string(.note)
    }
    private enum CodingKeys: String, CodingKey { case label, url, kind, note }
}

private struct SourceDTO: Decodable {
    let title: String, url: String
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        title = c.string(.title); url = c.string(.url)
    }
    private enum CodingKeys: String, CodingKey { case title, url }
}

private struct KeyMomentDTO: Decodable {
    let id: String
    let timestamp: String
    let label: String
    let note: String
    let frameIndex: Int
    let frameURL: String

    private enum CodingKeys: String, CodingKey {
        case id, timestamp, label, note
        case frameIndex = "index"
        case frameURL = "frame_url"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.string(.id); timestamp = c.string(.timestamp)
        label = c.string(.label); note = c.string(.note)
        frameIndex = (try? c.decodeIfPresent(Int.self, forKey: .frameIndex)) ?? 0
        frameURL = c.string(.frameURL)
    }
}

private struct PointDTO: Decodable {
    let text: String
    let done: Bool
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        text = c.string(.text)
        done = (try? c.decodeIfPresent(Bool.self, forKey: .done)) ?? false
    }
    private enum CodingKeys: String, CodingKey { case text, done }
}

// MARK: - DTO → domain mapping

private extension String {
    /// nil for blank strings, so views can use plain optional checks.
    var nonBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

private extension ReelDTO {
    func toReel() -> Reel {
        // Every place the reel is about; falls back to the single `location` from older servers.
        let allPlaces = (places.isEmpty ? [location] : places).compactMap { $0.toPlace(reelID: id) }
        return Reel(
            id: ReelAPIClient.stableUUID(from: id),
            sourceURL: sourceURL,
            author: author,
            coverImageName: coverAssetName,
            duration: duration,
            savedAt: ReelAPIClient.parseDate(created) ?? Date(),
            status: ReelStatus(rawValue: status) ?? .ready,
            progress: progress,
            title: title.nonBlank,
            gist: summary.nonBlank,
            keyMoments: keyMoments.map { $0.toKeyMoment(reelID: id) },
            points: points.compactMap { p in
                p.text.nonBlank.map { KeepPoint(id: ReelAPIClient.stableUUID(from: "\(id)#point#\($0)"), text: $0, done: p.done) }
            },
            place: allPlaces.first,
            boardID: nil,
            category: category,
            platformID: platform.nonBlank,
            liked: false,
            coverURL: ReelAPIClient.resolveURL(coverURL)?.absoluteString,
            links: links.compactMap { l in
                l.url.nonBlank.map { ReelLink(label: l.label.nonBlank ?? $0, url: $0, kind: l.kind, note: l.note.nonBlank) }
            },
            products: products.compactMap { p in
                p.name.nonBlank.map { ReelProduct(name: $0, brand: p.brand, url: p.url) }
            },
            people: people.compactMap { p in
                p.name.nonBlank.map { ReelPerson(name: $0, role: p.role) }
            },
            sources: sources.compactMap { s in
                s.url.nonBlank.map { ReelSource(title: s.title.nonBlank ?? $0, url: $0) }
            },
            stepDetails: details,
            chips: chips,
            errorMessage: error,
            jobID: id,
            extraPlaces: allPlaces.count > 1 ? Array(allPlaces.dropFirst()) : nil
        )
    }

    /// Illustration for the reel: tech kinds first, then a category pool. The pick inside a pool is derived
    /// from the reel id so a reel keeps the same art on every launch.
    private var coverAssetName: String {
        switch group {
        case "github_repo", "package": return "cover_coderepo"
        case "tool": return "cover_devtools"
        case "website": return "cover_websites"
        case "product": return "cover_market"
        default: break
        }
        let pool: [String]
        switch category {
        case "Food": pool = ["cover_ramen", "cover_bread", "cover_coffee"]
        case "Travel": pool = ["cover_sunrise", "cover_alley"]
        case "Fitness": pool = ["cover_workout"]
        case "Home": pool = ["cover_interiors", "cover_desk"]
        case "Tech": pool = ["cover_devtools", "cover_coderepo", "cover_websites"]
        case "Shopping": pool = ["cover_market"]
        case "Learning": pool = ["cover_books"]
        case "Entertainment": pool = ["cover_movies", "cover_music"]
        default: return "cover_placeholder"
        }
        let seed = id.unicodeScalars.reduce(0) { ($0 &* 31 &+ Int($1.value)) & 0x7fffffff }
        return pool[seed % pool.count]
    }
}

private extension LocationDTO {
    /// nil when the reel has no location, so every place UI disappears.
    func toPlace(reelID: String) -> ReelPlace? {
        guard let name = name.nonBlank else { return nil }
        // "Gachibowli, Hyderabad, India": skip parts already contained in the place name or an earlier part.
        var parts: [String] = []
        for part in [area, city, country].compactMap(\.nonBlank) {
            let seen = ([name] + parts).contains { $0.localizedCaseInsensitiveContains(part) }
            if !seen { parts.append(part) }
        }
        let subtitle = parts.joined(separator: ", ")
        return ReelPlace(id: ReelAPIClient.stableUUID(from: "\(reelID)#place#\(name)"),
                         name: name, subtitle: subtitle, mapURL: mapURL, latitude: lat, longitude: lng,
                         precision: precision.nonBlank, note: note.nonBlank)
    }
}

private extension KeyMomentDTO {
    func toKeyMoment(reelID: String) -> KeyMoment {
        KeyMoment(
            id: ReelAPIClient.stableUUID(from: "\(reelID)#\(frameIndex)#\(id)"),
            timestamp: timestamp,
            label: label,
            note: note,
            imageName: "cover_placeholder",
            frameURL: ReelAPIClient.resolveURL(frameURL.nonBlank)?.absoluteString
        )
    }
}
