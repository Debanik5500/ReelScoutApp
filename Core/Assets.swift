import SwiftUI
import UIKit

extension Image {
    /// Resolves a named asset-catalog image, falling back to a neutral
    /// "more to come" placeholder cover when the name doesn't exist in the
    /// bundle — e.g. a config-driven platform or category (see
    /// `PlatformRegistry`) that's been switched on before its art shipped.
    /// Every reel/board/key-moment cover should load through this instead of
    /// `Image(_:)` directly, so a missing asset never silently renders blank.
    static func cover(_ name: String) -> Image {
        UIImage(named: name) != nil ? Image(name) : Image("cover_placeholder")
    }
}
