import SwiftUI
import UIKit

extension Image {
    /// Resolves a named asset-catalog image, falling back to a neutral
    /// "more to come" placeholder cover when the name doesn't exist.
    static func cover(_ name: String) -> Image {
        if name.hasPrefix("http://") || name.hasPrefix("https://") {
            return Image("cover_placeholder")
        }
        return UIImage(named: name) != nil ? Image(name) : Image("cover_placeholder")
    }
}

struct RemoteImage: View {
    let urlString: String
    var fallback: String = "cover_placeholder"

    @State private var image: UIImage?
    @State private var isLoading = false

    init(urlString: String, fallback: String = "cover_placeholder") {
        self.urlString = urlString
        self.fallback = fallback
        _image = State(initialValue: ReelAPIClient.cachedImage(urlString))  // instant when already loaded
    }

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
            } else {
                Image(fallback)
                    .resizable()
            }
        }
        .task(id: urlString) {
            image = ReelAPIClient.cachedImage(urlString)  // nil when the URL changed to one not loaded yet
            await loadImage()
        }
    }

    private func loadImage() async {
        // Relative API paths are prefixed with the API base inside the client.
        guard ReelAPIClient.resolveURL(urlString) != nil else { return }
        guard !urlString.isEmpty, image == nil, !isLoading else { return }

        isLoading = true
        defer { isLoading = false }

        if let loaded = await ReelAPIClient.shared.loadImage(from: urlString) {
            await MainActor.run {
                self.image = loaded
            }
        }
        // On failure `image` stays nil so `Image(fallback)` is shown.
    }
}

/// A reel's cover: always the bundled illustration chosen for it (see `coverAssetName` in ReelService).
/// Real video frames are shown only inside Key moments. Always resizable; callers apply `.aspectRatio`/`.frame`.
struct ReelCover: View {
    let reel: Reel

    var body: some View {
        Image.cover(reel.coverImageName).resizable()
    }
}
