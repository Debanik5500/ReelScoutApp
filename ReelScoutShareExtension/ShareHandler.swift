import Foundation
import UniformTypeIdentifiers

@MainActor
final class ShareHandler {

    private let appGroupIdentifier = "group.com.reelscout.app"

    func extractPayload(from context: NSExtensionContext) async -> SharePayload {
        var extractedURL: String?
        var extractedText: String?
        var extractedImageData: Data?
        var extractedVideoURL: String?
        var sourceApp: String?

        for item in context.inputItems {
            guard let extensionItem = item as? NSExtensionItem else { continue }

            if let attachments = extensionItem.attachments {
                for attachment in attachments {
                    if let provider = attachment as? NSItemProvider {
                        if let app = extensionItem.attributedContentText?.string {
                            sourceApp = app
                        }

                        if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                            if let url = try? await loadURL(from: provider) {
                                extractedURL = url.absoluteString
                            }
                        }

                        if provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
                            if let text = try? await loadText(from: provider) {
                                extractedText = text
                            }
                        }

                        if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                            if let data = try? await loadImageData(from: provider) {
                                extractedImageData = data
                            }
                        }

                        if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                            if let videoURL = try? await loadVideoURL(from: provider) {
                                extractedVideoURL = videoURL.absoluteString
                            }
                        }
                    }
                }
            }

            if extractedText == nil, let text = extensionItem.attributedContentText?.string {
                extractedText = text
            }
        }

        let detectedSource = detectSource(from: extractedURL)

        return SharePayload(
            url: extractedURL,
            text: extractedText,
            imageData: extractedImageData,
            videoURL: extractedVideoURL,
            sourceApp: sourceApp,
            detectedSource: detectedSource
        )
    }

    func submitToApp(_ payload: SharePayload) async {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else { return }

        do {
            let data = try JSONEncoder().encode(payload)
            defaults.set(data, forKey: "pendingSharePayload")
        } catch {
        }
    }

    private func detectSource(from urlString: String?) -> String? {
        guard let urlString = urlString?.lowercased() else { return nil }

        if urlString.contains("instagram.com") { return "instagram" }
        if urlString.contains("tiktok.com") { return "tiktok" }
        if urlString.contains("youtube.com") || urlString.contains("youtu.be") { return "youtube" }
        return "other"
    }

    private func loadURL(from provider: NSItemProvider) async throws -> URL? {
        try await withCheckedThrowingContinuation { continuation in
            provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                if let url = item as? URL {
                    continuation.resume(returning: url)
                } else if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    private func loadText(from provider: NSItemProvider) async throws -> String? {
        try await withCheckedThrowingContinuation { continuation in
            provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { item, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                if let text = item as? String {
                    continuation.resume(returning: text)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    private func loadImageData(from provider: NSItemProvider) async throws -> Data? {
        try await withCheckedThrowingContinuation { continuation in
            provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { item, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                if let data = item as? Data {
                    continuation.resume(returning: data)
                } else if let url = item as? URL, let data = try? Data(contentsOf: url) {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    private func loadVideoURL(from provider: NSItemProvider) async throws -> URL? {
        try await withCheckedThrowingContinuation { continuation in
            provider.loadItem(forTypeIdentifier: UTType.movie.identifier, options: nil) { item, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                if let url = item as? URL {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}
