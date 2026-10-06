import UIKit
import UniformTypeIdentifiers

/// Receives a share (e.g. an Instagram reel), sends the link straight to the Kept server for processing,
/// shows a short confirmation and closes, so the user stays in the app they shared from.
///
/// If the server can't be reached, the link is stashed in the shared App Group and the main app submits it
/// the next time it opens. No storyboard: this class is the extension's principal class.
final class ShareViewController: UIViewController {
    private let icon = UIImageView()
    private let label = UILabel()
    private let spinner = UIActivityIndicatorView(style: .medium)
    private var limitReached = false

    override func viewDidLoad() {
        super.viewDidLoad()
        buildUI()
        extractSharedURL { [weak self] url in
            guard let self else { return }
            guard let url else { return self.finish(success: false, message: "Nothing to save") }
            guard AppGroup.isSupportedLink(url) else {
                return self.finish(success: false, message: "Open a reel or post, then share it")
            }
            self.submit(url) { ok in
                if self.limitReached {
                    // Over the monthly limit: nothing is saved; point the user at the plans page.
                    return self.finish(success: false, message: "Monthly limit reached. Open Kept to see plans")
                }
                if !ok { AppGroup.defaults?.set(url, forKey: AppGroup.pendingURLKey) }
                self.finish(success: true, message: ok ? "Saved to Kept" : "Saved. Open Kept to finish")
            }
        }
    }

    // MARK: - Submit

    private var baseURL: URL {
        let stored = AppGroup.defaults?.string(forKey: AppGroup.baseURLKey)
        return stored.flatMap(URL.init(string:)) ?? URL(string: "http://localhost:8000")!
    }

    private func submit(_ link: String, completion: @escaping (Bool) -> Void) {
        guard let endpoint = URL(string: "/api/v1/reels", relativeTo: baseURL)?.absoluteURL,
              let body = try? JSONEncoder().encode(["url": link]) else { return completion(false) }
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 8
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(AppGroup.deviceID, forHTTPHeaderField: "X-Device-Id")
        request.httpBody = body
        URLSession(configuration: .ephemeral).dataTask(with: request) { _, response, error in
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            let ok = error == nil && status / 100 == 2
            DispatchQueue.main.async {
                self.limitReached = status == 402
                completion(ok)
            }
        }.resume()
    }

    // MARK: - Reading the shared item

    private func extractSharedURL(completion: @escaping (String?) -> Void) {
        let attachments = (extensionContext?.inputItems as? [NSExtensionItem])?.flatMap { $0.attachments ?? [] } ?? []
        if let provider = attachments.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.url.identifier) }) {
            provider.loadItem(forTypeIdentifier: UTType.url.identifier) { data, _ in
                completion((data as? URL)?.absoluteString)
            }
        } else if let provider = attachments.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) }) {
            provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) { data, _ in
                // Plain-text shares can carry a caption around the link; keep only the first http(s) link.
                let text = data as? String ?? ""
                let link = text.split(whereSeparator: { $0.isWhitespace }).map(String.init)
                    .first { $0.hasPrefix("http://") || $0.hasPrefix("https://") }
                completion(link)
            }
        } else {
            completion(nil)
        }
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
        label.numberOfLines = 2
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
            card.widthAnchor.constraint(equalToConstant: 220),
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.extensionContext?.completeRequest(returningItems: nil)
            }
        }
    }
}
