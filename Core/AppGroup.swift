import Foundation

/// Shared container between the app and the share extension. Must match
/// the App Group entitlement on both targets.
enum AppGroup {
    static let id = "group.com.reelscout.app"
    static let pendingURLKey = "pendingShareURL"
    /// Server address, written by the app so the share extension can reach the same backend.
    static let baseURLKey = "apiBaseURL"

    static var defaults: UserDefaults? { UserDefaults(suiteName: id) }

    /// Anonymous per-install id the server uses to count the monthly reel limit. Shared with the extension.
    private static let deviceIDKey = "deviceID"
    static var deviceID: String {
        let store = defaults ?? .standard
        if let existing = store.string(forKey: deviceIDKey) { return existing }
        let created = UUID().uuidString
        store.set(created, forKey: deviceIDKey)
        return created
    }

    /// Other sites Kept can read videos from (Instagram is checked separately, by path).
    private static let otherHosts = ["tiktok.com", "youtube.com", "youtu.be", "twitter.com", "x.com", "reddit.com"]

    /// True only for a link to one reel or post. The Instagram home page, search pages and so on are not reels.
    static func isSupportedLink(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString.trimmingCharacters(in: .whitespacesAndNewlines)),
              var host = url.host?.lowercased() else { return false }
        if host.hasPrefix("www.") { host.removeFirst(4) }
        let parts = url.path.split(separator: "/").map(String.init)

        if host == "instagram.com" || host.hasSuffix(".instagram.com") || host == "instagr.am" {
            guard let first = parts.first else { return false }
            if ["reel", "reels", "p", "tv"].contains(first) { return parts.count >= 2 }
            return first == "share" && parts.count >= 2
        }
        return otherHosts.contains { host == $0 || host.hasSuffix("." + $0) } && !parts.isEmpty
    }
}
