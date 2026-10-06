import Foundation
import CryptoKit

/// On-device copy of everything the backend has processed: reel JSON plus the images they reference.
/// The app renders from this first and treats the network as a background sync.
enum ReelDiskCache {
    /// Bump when `Reel`'s Codable shape changes; an old file is then ignored instead of failing to decode.
    private static let version = 4

    private static var directory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ReelScout", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base
    }

    private static var reelsFile: URL { directory.appendingPathComponent("reels.v\(version).json") }

    private static var imagesDirectory: URL {
        let dir = directory.appendingPathComponent("images", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func imageFile(for key: String) -> URL {
        let digest = SHA256.hash(data: Data(key.utf8)).map { String(format: "%02x", $0) }.joined()
        return imagesDirectory.appendingPathComponent(digest)
    }

    static func loadReels() -> [Reel] {
        guard let data = try? Data(contentsOf: reelsFile) else { return [] }
        return (try? JSONDecoder().decode([Reel].self, from: data)) ?? []
    }

    static func save(_ reels: [Reel]) {
        guard let data = try? JSONEncoder().encode(reels) else { return }
        try? data.write(to: reelsFile, options: .atomic)
    }
}
