import UIKit
import UniformTypeIdentifiers
import ImageIO

/// Receives a share (an Instagram reel or post, a web page, a Google result, screenshots, or plain text), sends it
/// straight to the Kept server, shows a short confirmation and closes, so the user stays where they were.
///
/// If the server can't be reached, a link is stashed in the shared App Group and the main app submits it the next
/// time it opens (images and text can't be, so the user is told to try again).
final class ShareViewController: UIViewController {
    private let icon = UIImageView()
    private let label = UILabel()
    private let spinner = UIActivityIndicatorView(style: .medium)

    private enum Item {
        case reelLink(String)
        case webLink(String)
        case text(String)
        case screenshots([Data])
    }

    private enum Outcome { case saved, limitReached, rejected, unreachable }

    override func viewDidLoad() {
        super.viewDidLoad()
        buildUI()
        Task { await handle() }
    }

    // MARK: - Flow

    private func handle() async {
        guard let item = await readItem() else { return finish(success: false, message: "Nothing to save") }
        let outcome = await send(item)
        switch outcome {
        case .saved:
            finish(success: true, message: "Saved to Kept")
        case .limitReached:
            finish(success: false, message: "Monthly limit reached. Open Kept to see plans")
        case .rejected:
            finish(success: false, message: "Kept can't read that")
        case .unreachable:
            switch item {
            case .reelLink(let link), .webLink(let link):
                AppGroup.defaults?.set(link, forKey: AppGroup.pendingURLKey)
                finish(success: true, message: "Saved. Open Kept to finish")
            default:
                finish(success: false, message: "Couldn't reach Kept. Try again")
            }
        }
    }

    // MARK: - Reading what was shared

    private func readItem() async -> Item? {
        let providers = (extensionContext?.inputItems as? [NSExtensionItem])?.flatMap { $0.attachments ?? [] } ?? []

        // Screenshots win: sharing from Photos gives images.
        let imageProviders = providers.filter { $0.hasItemConformingToTypeIdentifier(UTType.image.identifier) }
        if !imageProviders.isEmpty {
            var images: [Data] = []
            for provider in imageProviders.prefix(10) {
                if let data = try? await provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier),
                   let jpeg = Self.shrunkJPEG(from: data) {
                    images.append(jpeg)
                }
            }
            return images.isEmpty ? nil : .screenshots(images)
        }

        // A link: a reel/post goes to the reel pipeline, anything else is read as a web page.
        if let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.url.identifier) }),
           let url = await loadURL(provider) {
            return AppGroup.isSupportedLink(url) ? .reelLink(url) : (AppGroup.isWebLink(url) ? .webLink(url) : nil)
        }

        // Text: a link inside it if there is one (apps often share "caption + link"), else the text itself.
        if let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) }),
           let text = await loadText(provider) {
            let link = text.split(whereSeparator: { $0.isWhitespace }).map(String.init)
                .first { $0.hasPrefix("http://") || $0.hasPrefix("https://") }
            if let link {
                return AppGroup.isSupportedLink(link) ? .reelLink(link) : (AppGroup.isWebLink(link) ? .webLink(link) : nil)
            }
            return text.trimmingCharacters(in: .whitespacesAndNewlines).count >= 12 ? .text(text) : nil
        }
        return nil
    }

    private func loadURL(_ provider: NSItemProvider) async -> String? {
        await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: UTType.url.identifier) { data, _ in
                continuation.resume(returning: (data as? URL)?.absoluteString)
            }
        }
    }

    private func loadText(_ provider: NSItemProvider) async -> String? {
        await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) { data, _ in
                continuation.resume(returning: data as? String)
            }
        }
    }

    /// Screenshots are big. Shrink them here, with ImageIO (low memory), before uploading: extensions have little RAM.
    private static func shrunkJPEG(from data: Data, maxSide: CGFloat = 1800) -> Data? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxSide,
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        return UIImage(cgImage: image).jpegData(compressionQuality: 0.85)
    }

    // MARK: - Sending

    private var baseURL: URL {
        let stored = AppGroup.defaults?.string(forKey: AppGroup.baseURLKey)
        return stored.flatMap(URL.init(string:)) ?? URL(string: "http://localhost:8000")!
    }

    private func send(_ item: Item) async -> Outcome {
        let tz = TimeZone.current.identifier
        var request: URLRequest
        switch item {
        case .reelLink(let link):
            request = jsonRequest("/api/v1/reels", ["url": link, "tz": tz])
        case .webLink(let link):
            request = jsonRequest("/api/v1/web", ["url": link, "text": "", "tz": tz])
        case .text(let text):
            request = jsonRequest("/api/v1/web", ["url": "", "text": text, "tz": tz])
        case .screenshots(let images):
            request = multipartRequest(images, tz: tz)
        }
        guard request.url != nil else { return .unreachable }
        request.setValue(AppGroup.deviceID, forHTTPHeaderField: "X-Device-Id")
        do {
            let (_, response) = try await URLSession(configuration: .ephemeral).data(for: request)
            switch (response as? HTTPURLResponse)?.statusCode ?? 0 {
            case 200..<300: return .saved
            case 402: return .limitReached
            case 400..<500: return .rejected
            default: return .unreachable
            }
        } catch {
            return .unreachable
        }
    }

    private func jsonRequest(_ path: String, _ fields: [String: String]) -> URLRequest {
        var request = URLRequest(url: URL(string: path, relativeTo: baseURL)?.absoluteURL ?? baseURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(fields)
        return request
    }

    private func multipartRequest(_ images: [Data], tz: String) -> URLRequest {
        let boundary = "kept-\(UUID().uuidString)"
        var body = Data()
        func append(_ string: String) { body.append(Data(string.utf8)) }
        append("--\(boundary)\r\nContent-Disposition: form-data; name=\"tz\"\r\n\r\n\(tz)\r\n")
        for (index, image) in images.enumerated() {
            append("--\(boundary)\r\nContent-Disposition: form-data; name=\"files\"; filename=\"shot\(index).jpg\"\r\n")
            append("Content-Type: image/jpeg\r\n\r\n")
            body.append(image)
            append("\r\n")
        }
        append("--\(boundary)--\r\n")
        var request = URLRequest(url: URL(string: "/api/v1/screenshots", relativeTo: baseURL)?.absoluteURL ?? baseURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        return request
    }

    // MARK: - UI

    private func buildUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.25)

        let card = UIView()
        card.backgroundColor = UIColor(red: 0.965, green: 0.945, blue: 0.918, alpha: 1)
        card.layer.cornerRadius = 28
        card.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(card)

        icon.tintColor = UIColor(red: 0.788, green: 0.251, blue: 0.122, alpha: 1)
        icon.contentMode = .scaleAspectFit
        icon.isHidden = true
        label.text = "Saving to Kept…"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = UIColor(red: 0.11, green: 0.106, blue: 0.098, alpha: 1)
        label.textAlignment = .center
        label.numberOfLines = 3
        spinner.startAnimating()

        let stack = UIStackView(arrangedSubviews: [spinner, icon, label])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        NSLayoutConstraint.activate([
            card.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            card.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            card.widthAnchor.constraint(equalToConstant: 240),
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 24),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -24),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            icon.heightAnchor.constraint(equalToConstant: 34),
            icon.widthAnchor.constraint(equalToConstant: 34),
        ])
    }

    private func finish(success: Bool, message: String) {
        DispatchQueue.main.async {
            self.spinner.stopAnimating()
            self.spinner.isHidden = true
            self.icon.image = UIImage(systemName: success ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
            self.icon.isHidden = false
            self.label.text = message
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                self.extensionContext?.completeRequest(returningItems: nil)
            }
        }
    }
}
