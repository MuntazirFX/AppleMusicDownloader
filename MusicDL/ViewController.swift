import UIKit

final class ViewController: UIViewController {

    private let pink = UIColor(red: 0.98, green: 0.18, blue: 0.33, alpha: 1)
    private let engine = DownloadEngine()
    private let applePlayer = AppleMusicPlayer()
    private let applePlayButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let field = UITextField()
    private let pasteButton = UIButton(type: .system)
    private let button = UIButton(type: .system)
    private let progress = UIProgressView(progressViewStyle: .bar)
    private let sizeLabel = UILabel()
    private let logView = UITextView()
    private var running = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        buildUI()
        bindEngine()
    }

    private func buildUI() {
        titleLabel.text = "MusicDL"
        titleLabel.font = .systemFont(ofSize: 34, weight: .heavy)
        titleLabel.textColor = .label

        field.placeholder = "Apple Music song/album link ya direct audio URL"
        field.keyboardType = .URL
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.clearButtonMode = .whileEditing
        field.returnKeyType = .go
        field.addTarget(self, action: #selector(tapped), for: .editingDidEndOnExit)
        field.backgroundColor = .secondarySystemBackground
        field.textColor = .label
        field.layer.cornerRadius = 12
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        field.leftViewMode = .always

        applePlayButton.setTitle("Open link in Apple Music", for: .normal)
        applePlayButton.tintColor = pink
        applePlayButton.addTarget(self, action: #selector(playAppleMusicTapped), for: .touchUpInside)

        pasteButton.setTitle("Paste link", for: .normal)
        pasteButton.tintColor = pink
        pasteButton.contentHorizontalAlignment = .leading
        pasteButton.addTarget(self, action: #selector(pasteTapped), for: .touchUpInside)

        var cfg = UIButton.Configuration.filled()
        cfg.title = "Play Apple Music / Download Audio"
        cfg.baseBackgroundColor = pink
        cfg.baseForegroundColor = .white
        cfg.cornerStyle = .capsule
        button.configuration = cfg
        button.addTarget(self, action: #selector(tapped), for: .touchUpInside)

        progress.progressTintColor = pink
        progress.trackTintColor = .tertiarySystemFill

        sizeLabel.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        sizeLabel.textColor = .secondaryLabel
        sizeLabel.text = " "

        logView.isEditable = false
        logView.backgroundColor = .secondarySystemBackground
        logView.textColor = .secondaryLabel
        logView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        logView.layer.cornerRadius = 12
        logView.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
        logView.text = "Status: idle\n"

        let stack = UIStackView(arrangedSubviews: [titleLabel, field, pasteButton, button, applePlayButton, progress, sizeLabel, logView])
        stack.axis = .vertical; stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            field.heightAnchor.constraint(equalToConstant: 48),
            button.heightAnchor.constraint(equalToConstant: 52),
            logView.heightAnchor.constraint(equalToConstant: 260),
        ])
    }

    private func bindEngine() {
        engine.onLog = { [weak self] m in self?.append(m) }
        engine.onProgress = { [weak self] p, text in
            self?.progress.setProgress(p, animated: true)
            self?.sizeLabel.text = text.isEmpty ? " " : text
        }
        engine.onFinish = { [weak self] _ in self?.setRunning(false) }
    }

    private func append(_ m: String) {
        logView.text += "• \(m)\n"
        logView.scrollRangeToVisible(NSRange(location: logView.text.count - 1, length: 1))
    }

    private func setRunning(_ r: Bool) {
        running = r
        var c = button.configuration
        c?.title = r ? "Cancel" : "Play Apple Music / Download Audio"
        button.configuration = c
    }

    @objc private func pasteTapped() {
        if let s = UIPasteboard.general.string { field.text = s.trimmingCharacters(in: .whitespacesAndNewlines) }
    }


    @objc private func playAppleMusicTapped() {
        view.endEditing(true)
        let raw = (field.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: raw),
              let host = url.host?.lowercased(),
              host == "music.apple.com" || host.hasSuffix(".music.apple.com") || host == "itunes.apple.com" || host.hasSuffix(".itunes.apple.com") else {
            append("Apple Music song ya album link paste karo.")
            return
        }
        UIApplication.shared.open(url, options: [:]) { [weak self] success in
            self?.append(success ? "Apple Music app/browser open ho gaya." : "Apple Music link open nahi ho saka.")
        }
    }

    @objc private func tapped() {
        if running { engine.cancel(); return }
        view.endEditing(true)
        let raw = (field.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: raw), let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme), url.host != nil else {
            append("Valid http/https URL daalo.")
            return
        }
        let host = (url.host ?? "").lowercased()
        if host == "music.apple.com" || host.hasSuffix(".music.apple.com") || host == "itunes.apple.com" || host.hasSuffix(".itunes.apple.com") {
            logView.text = ""
            append("Apple Music link detected. Full catalog playback start ho raha hai…")
            applePlayButton.isEnabled = false
            Task { @MainActor in
                defer { self.applePlayButton.isEnabled = true }
                do {
                    let message = try await self.applePlayer.playAppleMusicLink(url)
                    self.append(message)
                    self.append("Note: Apple Music protected audio ko MP3/M4A file ke roop mein export nahi kiya ja sakta.")
                } catch {
                    self.let nsError = error as NSError
                    if nsError.localizedDescription.localizedCaseInsensitiveContains("developer token") || nsError.localizedDescription.localizedCaseInsensitiveContains("token") {
                        self.append("MusicKit token setup failed. Check: MusicKit enabled for this exact Bundle ID in Apple Developer, same Team ID used for signing, and install a properly signed IPA (unsigned IPA cannot use MusicKit automatic token generation).")
                        self.append("Technical error: \(nsError.domain) (\(nsError.code)) — \(nsError.localizedDescription)")
                    } else {
                        self.append("Apple Music error: \(nsError.localizedDescription)")
                    }
                }
            }
            return
        }
        logView.text = ""
        progress.setProgress(0, animated: false)
        setRunning(true)
        engine.start(url: url)
    }
}
