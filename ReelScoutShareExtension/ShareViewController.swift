import UIKit

final class ShareViewController: UIViewController {

    private let handler = ShareHandler()
    private var hasSubmitted = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !hasSubmitted {
            hasSubmitted = true
            Task { await processSharedContent() }
        }
    }

    private func setupUI() {
        view.backgroundColor = UIColor.systemBackground

        let card = UIView()
        card.backgroundColor = UIColor.secondarySystemBackground
        card.layer.cornerRadius = 16
        card.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(card)

        let titleLabel = UILabel()
        titleLabel.text = "ReelScout"
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(titleLabel)

        let messageLabel = UILabel()
        messageLabel.text = "Sent to ReelScout \u{2713}"
        messageLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        messageLabel.textAlignment = .center
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(messageLabel)

        let subtitleLabel = UILabel()
        subtitleLabel.text = "We'll figure out what's interesting about this Reel."
        subtitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = UIColor.secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(subtitleLabel)

        let openButton = UIButton(type: .system)
        openButton.setTitle("Open ReelScout", for: .normal)
        openButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        openButton.backgroundColor = UIColor.systemBlue
        openButton.setTitleColor(.white, for: .normal)
        openButton.layer.cornerRadius = 12
        openButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)
        openButton.translatesAutoresizingMaskIntoConstraints = false
        openButton.addTarget(self, action: #selector(openReelScout), for: .touchUpInside)
        card.addSubview(openButton)

        NSLayoutConstraint.activate([
            card.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            card.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            card.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            card.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32),
            card.widthAnchor.constraint(lessThanOrEqualToConstant: 320),

            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),

            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),

            subtitleLabel.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),

            openButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 20),
            openButton.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            openButton.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -24)
        ])
    }

    @objc private func openReelScout() {
        let url = URL(string: "reelscout://processing")!
        extensionContext?.open(url, completionHandler: nil)
    }

    private func processSharedContent() async {
        guard let context = extensionContext else { return }
        let payload = await handler.extractPayload(from: context)
        guard payload.hasContent else { return }
        await handler.submitToApp(payload)
    }
}
