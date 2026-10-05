import UIKit
import UniformTypeIdentifiers

/// Receives an Instagram share, stashes the URL in the shared App Group,
/// and hands off to the main app. No storyboard: this class is the
/// extension's principal class directly.
final class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        extractSharedURL { [weak self] url in
            guard let self else { return }
            if let url {
                AppGroup.defaults?.set(url, forKey: AppGroup.pendingURLKey)
            }
            DispatchQueue.main.async {
                if let url, let deepLink = URL(string: "kept://share?url=\\(url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? url)") {
                    self.openHostApp(deepLink)
                }
                self.extensionContext?.completeRequest(returningItems: nil)
            }
        }
    }

    private func extractSharedURL(completion: @escaping (String?) -> Void) {
        guard let item = extensionContext?.inputItems.first as? NSExtensionItem,
              let attachment = item.attachments?.first else { completion(nil); return }

        if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            attachment.loadItem(forTypeIdentifier: UTType.url.identifier) { data, _ in
                completion((data as? URL)?.absoluteString)
            }
        } else if attachment.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
            attachment.loadItem(forTypeIdentifier: UTType.plainText.identifier) { data, _ in
                completion(data as? String)
            }
        } else {
            completion(nil)
        }
    }

    /// Share extensions can't call UIApplication.shared.open directly; walk
    /// the responder chain to find it, the standard workaround for this.
    private func openHostApp(_ url: URL) {
        var responder: UIResponder? = self
        let selector = sel_registerName("openURL:")
        while let r = responder {
            if r.responds(to: selector) {
                r.perform(selector, with: url)
                return
            }
            responder = r.next
        }
    }
}
