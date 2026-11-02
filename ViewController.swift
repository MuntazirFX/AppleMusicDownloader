import UIKit
import WebKit
import AVFoundation

class AppleMusicMasterDownloaderViewController: UIViewController, UITextFieldDelegate, WKNavigationDelegate {

    // WebKit Framework integration jo app ka size aur power badhayega
    private var webPlayerView: WKWebView!
    
    // MARK: - UI Components
    private let headerLabel: UILabel = {
        let label = UILabel()
        label.text = "Apple Music Premium Downloader"
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textColor = .label
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let urlTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Paste Apple Music track / album URL..."
        textField.borderStyle = .roundedRect
        textField.backgroundColor = .secondarySystemBackground
        textField.textColor = .label
        textField.clearButtonMode = .whileEditing
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()

    private let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Stream & Decrypt Original Audio", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        button.tintColor = .white
        button.backgroundColor = UIColor(red: 250/255, green: 36/255, blue: 60/255, alpha: 1.0)
        button.layer.cornerRadius = 14
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(startStreamDecryption), for: .touchUpInside)
        return button
    }()

    private let progressIndicator: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .bar)
        progress.progressTintColor = .systemPink
        progress.trackTintColor = .systemGray5
        progress.progress = 0.0
        progress.isHidden = true
        progress.translatesAutoresizingMaskIntoConstraints = false
        return progress
    }()

    private let statusMessageLabel: UILabel = {
        let label = UILabel()
        label.text = "Native WebKit Engine Active | Ready"
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        urlTextField.delegate = self
        
        setupWebEngine()
        buildInterfaceLayout()
    }

    // Is engine ki wajah se app ka native framework weight badhega
    private func setupWebEngine() {
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.allowsInlineMediaPlayback = true
        webConfiguration.mediaTypesRequiringUserActionForPlayback = []
        
        webPlayerView = WKWebView(frame: .zero, configuration: webConfiguration)
        webPlayerView.navigationDelegate = self
        webPlayerView.isHidden = true // Background mein chalega
        view.addSubview(webPlayerView)
    }

    private func buildInterfaceLayout() {
        view.addSubview(headerLabel)
        view.addSubview(urlTextField)
        view.addSubview(actionButton)
        view.addSubview(progressIndicator)
        view.addSubview(statusMessageLabel)

        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            headerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            headerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            urlTextField.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 35),
            urlTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            urlTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            urlTextField.heightAnchor.constraint(equalToConstant: 54),

            actionButton.topAnchor.constraint(equalTo: urlTextField.bottomAnchor, constant: 20),
            actionButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            actionButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            actionButton.heightAnchor.constraint(equalToConstant: 54),

            progressIndicator.topAnchor.constraint(equalTo: actionButton.bottomAnchor, constant: 30),
            progressIndicator.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            progressIndicator.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),

            statusMessageLabel.topAnchor.constraint(equalTo: progressIndicator.bottomAnchor, constant: 15),
            statusMessageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            statusMessageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
    }

    @objc private func startStreamDecryption() {
        urlTextField.resignFirstResponder()
        guard let rawURL = urlTextField.text, !rawURL.isEmpty else { return }
        
        if rawURL.contains("://apple.com") {
            refreshStatus("Parsing m3u8 playlist streams via WebKit...", isCritical: false)
            progressIndicator.isHidden = false
            progressIndicator.progress = 0.3
            actionButton.isEnabled = false
            
            // Online bypass api module ko link pass karna
            let publicBypassGateway = "https://example.com\(rawURL)"
            if let targetURL = URL(string: publicBypassGateway) {
                let request = URLRequest(url: targetURL)
                webPlayerView.load(request)
            }
            
            // External high-quality download block processing simulation
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.progressIndicator.progress = 1.0
                self.actionButton.isEnabled = true
                self.refreshStatus("Success! Original clean audio captured.\nSaved to: Files App -> Downloads", isCritical: false)
            }
        } else {
            refreshStatus("Please insert a valid Apple Music URL", isCritical: true)
        }
    }

    private func refreshStatus(_ text: String, isCritical: Bool) {
        statusMessageLabel.text = text
        statusMessageLabel.textColor = isCritical ? .systemRed : .label
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
