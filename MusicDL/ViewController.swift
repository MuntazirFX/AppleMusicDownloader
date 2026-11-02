import UIKit
import WebKit

final class ViewController: UIViewController {

    private let engine = DownloadEngine()
    private let titleLabel = UILabel()
    private let field = UITextField()
    private let button = UIButton(type: .system)
    private let progress = UIProgressView(progressViewStyle: .bar)
    private let logLabel = UILabel()
    private let logBox = UIView()
    private var logText = ""
    private let webView = WKWebView(frame: .zero) // placeholder for future extractor sub-system

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

        field.placeholder = "Track title"
        field.backgroundColor = .secondarySystemBackground
        field.textColor = .label
        field.layer.cornerRadius = 12
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        field.leftViewMode = .always

        var cfg = UIButton.Configuration.filled()
        cfg.title = "Download"
        cfg.baseBackgroundColor = UIColor(red: 0.98, green: 0.18, blue: 0.33, alpha: 1)
        cfg.baseForegroundColor = .white
        cfg.cornerStyle = .capsule
        button.configuration = cfg
        button.addTarget(self, action: #selector(tapped), for: .touchUpInside)

        progress.progressTintColor = UIColor(red: 0.98, green: 0.18, blue: 0.33, alpha: 1)
        progress.trackTintColor = .tertiarySystemFill

        logBox.backgroundColor = .secondarySystemBackground
        logBox.layer.cornerRadius = 12
        logLabel.numberOfLines = 0
        logLabel.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        logLabel.textColor = .secondaryLabel
        logLabel.text = "Status: idle"

        let stack = UIStackView(arrangedSubviews: [titleLabel, field, button, progress, logBox])
        stack.axis = .vertical; stack.spacing = 18
        stack.translatesAutoresizingMaskIntoConstraints = false
        logLabel.translatesAutoresizingMaskIntoConstraints = false
        logBox.addSubview(logLabel)
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            field.heightAnchor.constraint(equalToConstant: 48),
            button.heightAnchor.constraint(equalToConstant: 52),
            logBox.heightAnchor.constraint(greaterThanOrEqualToConstant: 220),
            logLabel.topAnchor.constraint(equalTo: logBox.topAnchor, constant: 12),
            logLabel.bottomAnchor.constraint(lessThanOrEqualTo: logBox.bottomAnchor, constant: -12),
            logLabel.leadingAnchor.constraint(equalTo: logBox.leadingAnchor, constant: 12),
            logLabel.trailingAnchor.constraint(equalTo: logBox.trailingAnchor, constant: -12),
        ])
    }

    private func bindEngine() {
        engine.onLog = { [weak self] m in
            guard let self else { return }
            self.logText += "• \(m)\n"; self.logLabel.text = self.logText
        }
        engine.onProgress = { [weak self] p in self?.progress.setProgress(p, animated: true) }
        engine.onFinish = { [weak self] r in
            guard let self else { return }
            self.button.isEnabled = true
            if case .failure(let e) = r { self.engine.onLog?("Error: \(e.localizedDescription)") }
        }
    }

    @objc private func tapped() {
        view.endEditing(true)
        button.isEnabled = false
        logText = ""; logLabel.text = ""
        engine.start(title: field.text ?? "")
    }
}
