import Foundation
import UIKit
import CryptoKit

protocol ReelServiceProtocol {
    func fetchReels() async throws -> [Reel]
    func fetchReel(id: String) async throws -> Reel
    func submitReel(url: String) async throws -> String
    func pollStatus(reelID: String) async throws -> Reel
    func loadImage(from urlString: String) async -> UIImage?
}

enum ReelAPIError: Error {
    case badURL(String)
    case notFound
    case badStatus(Int)
    case notSupported
}

/// Talks to the FastAPI backend. Every path below is relative and is resolved
/// against `baseURL`; image URLs coming back from the API are relative too and
/// get the same treatment in `resolveURL(_:base:)`.
final class ReelAPIClient: ReelServiceProtocol {
    static let shared = ReelAPIClient()

    static let baseURL = URL(string: "http://localhost:8000")!

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

    /// The backend contract exposes no submit endpoint yet, so this fails
    /// fast instead of hitting a URL that does not exist.
    func submitReel(url: String) async throws -> String {
        throw ReelAPIError.notSupported
    }

    // MARK: - Images

    func loadImage(from urlString: String) async -> UIImage? {
        guard let url = Self.resolveURL(urlString) else { return nil }
        let key = url.absoluteString
        if let cached = await imageCache.image(for: key) { return cached }
        guard let result = try? await session.data(from: url) else { return nil }
        if let http = result.1 as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            return nil
        }
        guard let image = UIImage(data: result.0) else { return nil }
        await imageCache.setImage(image, for: key)
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

// MARK: - Wire format (mirrors the FastAPI contract exactly)

private struct ReelsResponse: Decodable {
    let reels: [ReelDTO]
}

private struct ReelResponse: Decodable {
    let reel: ReelDTO
}

private struct ReelDTO: Decodable {
    let id: String
    let created: String?
    let title: String?
    let gist: String?
    let author: String
    let duration: String
    let coverURL: String?
    let status: String
    let progress: Double
    let category: String
    let group: String?
    let platform: String
    let sourceURL: String
    let summary: String?
    let frameCount: Int
    let keyMoments: [KeyMomentDTO]
    let places: [PlaceDTO]
    let points: [PointDTO]
    let board: AnyJSON?

    private enum CodingKeys: String, CodingKey {
        case id, created, title, gist, author, duration, status, progress
        case category, group, platform, summary, places, points, board
        case coverURL = "cover_url"
        case sourceURL = "source_url"
        case frameCount = "frame_count"
        case keyMoments = "key_moments"
    }
}

private struct KeyMomentDTO: Decodable {
    let id: String
    let timestamp: String
    let seconds: Double
    let label: String
    let note: String
    let frameIndex: Int
    let frameURL: String?

    private enum CodingKeys: String, CodingKey {
        case id, timestamp, seconds, label, note
        case frameIndex = "index"
        case frameURL = "frame_url"
    }
}

private struct PlaceDTO: Decodable {
    let name: String
    let subtitle: String
    let mapURL: String

    private enum CodingKeys: String, CodingKey {
        case name, subtitle
        case mapURL = "map_url"
    }
}

private struct PointDTO: Decodable {
    let text: String
    let done: Bool
}

/// Accepts any JSON value so a `null` (or a future object) never breaks decoding.
private struct AnyJSON: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() { return }
        if (try? container.decode(Bool.self)) != nil { return }
        if (try? container.decode(Double.self)) != nil { return }
        if (try? container.decode(String.self)) != nil { return }
        if (try? container.decode([AnyJSON].self)) != nil { return }
        if (try? container.decode([String: AnyJSON].self)) != nil { return }
    }
}

// MARK: - DTO → domain mapping

private extension ReelDTO {
    func toReel() -> Reel {
        Reel(
            id: ReelAPIClient.stableUUID(from: id),
            sourceURL: sourceURL,
            author: author,
            coverImageName: coverAssetName,
            duration: duration,
            savedAt: ReelAPIClient.parseDate(created) ?? Date(),
            status: ReelStatus(rawValue: status) ?? .ready,
            progress: progress,
            title: title,
            gist: gist,
            keyMoments: keyMoments.map { $0.toKeyMoment(reelID: id) },
            points: points.map { KeepPoint(text: $0.text, done: $0.done) },
            place: places.first.map {
                ReelPlace(name: $0.name, subtitle: $0.subtitle, mapURL: $0.mapURL)
            },
            boardID: nil,
            category: category,
            platformID: platform,
            liked: false,
            coverURL: ReelAPIClient.resolveURL(coverURL)?.absoluteString
        )
    }
    
    private var coverAssetName: String {
        // Map group (kind) to cover asset
        if let group = group {
            switch group {
            case "github_repo", "tool": return "cover_coderepo"
            case "website": return "cover_websites"
            case "product": return "cover_market"
            default: break
            }
        }
        
        // Map category to cover asset
        switch category {
        case "Food": return "cover_ramen"
        case "Travel": return "cover_sunrise"
        case "Fitness": return "cover_workout"
        case "Home": return "cover_interiors"
        default: return "cover_placeholder"
        }
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
            frameURL: ReelAPIClient.resolveURL(frameURL)?.absoluteString
        )
    }
}
