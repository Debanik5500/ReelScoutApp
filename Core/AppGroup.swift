import Foundation

/// Shared container between the app and the share extension. Must match
/// the App Group entitlement on both targets.
enum AppGroup {
    static let id = "group.com.reelscout.app"
    static let pendingURLKey = "pendingShareURL"

    static var defaults: UserDefaults? { UserDefaults(suiteName: id) }
}
