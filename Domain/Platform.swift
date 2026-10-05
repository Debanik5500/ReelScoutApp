import SwiftUI

/// Describes one source platform a reel can come from. Everything the app
/// needs to know about a platform — its name, icon, color, which URLs belong
/// to it, and whether it's switched on yet — lives in `Config/Platforms.json`.
/// No view or service should hardcode a platform's name, icon, or domain:
/// look it up here instead, so adding TikTok/YouTube/X later is a config
/// change, not a code change.
struct Platform: Identifiable, Codable, Hashable {
    let id: String              // stable key, e.g. "instagram"
    var displayName: String
    var icon: String            // SF Symbol name
    var colorHex: String        // "#RRGGBB"
    var domains: [String]       // hostnames that identify a shared URL as this platform
    var enabled: Bool           // whether Kept currently surfaces this platform in the UI

    var color: Color {
        Color(hex: UInt32(colorHex.trimmingCharacters(in: .init(charactersIn: "#")), radix: 16) ?? 0x6E685F)
    }
}

/// Single source of truth for every platform Kept knows about, loaded once
/// from the bundled `Platforms.json`. Falls back to a minimal built-in
/// Instagram-only config if that resource is ever missing, so the app still
/// runs, but the bundled config is the thing to edit in normal development.
enum PlatformRegistry {
    static let all: [Platform] = load()
    static var enabled: [Platform] { all.filter { $0.enabled } }

    static let unknown = Platform(
        id: "unknown", displayName: "Web", icon: "link",
        colorHex: "#6E685F", domains: [], enabled: true
    )

    static func platform(for id: String) -> Platform {
        all.first { $0.id == id } ?? unknown
    }

    /// Best-effort platform detection from a shared URL's host. This is what
    /// lets `ReelStore.ingest(sourceURL:)` — and the share extension upstream
    /// of it — stay platform-agnostic: neither one needs to know Instagram
    /// or any other platform by name.
    static func detect(from urlString: String) -> Platform {
        guard let host = URL(string: urlString)?.host?.lowercased() else { return unknown }
        return all.first { platform in
            platform.domains.contains { domain in
                host == domain || host.hasSuffix("." + domain)
            }
        } ?? unknown
    }

    private static func load() -> [Platform] {
        guard
            let url = Bundle.main.url(forResource: "Platforms", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let decoded = try? JSONDecoder().decode([Platform].self, from: data)
        else {
            return [Platform(id: "instagram", displayName: "Instagram", icon: "camera.fill",
                              colorHex: "#C9401F", domains: ["instagram.com", "instagr.am"], enabled: true)]
        }
        return decoded
    }
}
