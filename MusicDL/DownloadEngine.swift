import Foundation
import AVFoundation

/// SIMULATED pipeline: manifest parse -> handshake -> download -> save .m4a.
/// No real streaming service, DRM or decryption is involved.
final class DownloadEngine: NSObject, URLSessionDownloadDelegate {

    var onLog: ((String) -> Void)?
    var onProgress: ((Float) -> Void)?
    var onFinish: ((Result<URL, Error>) -> Void)?

    private lazy var session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
    private var downloaded: URL?
    private var timer: Timer?
    private var shown: Float = 0
    private var real: Float = 0
    private var finishedReal = false
    private var title = "Demo Track"

    func start(title: String) {
        self.title = title.isEmpty ? "Demo Track" : title
        shown = 0; real = 0; finishedReal = false; downloaded = nil
        onProgress?(0)
        log("Manifest fetch kar raha hu (simulated)...")
        after(0.8) { [self] in
            log("Manifest parsed: AAC 256kbps, 12 segments")
            log("Handshake shuru (simulated)...")
            after(1.0) { [self] in
                log("Handshake OK (mock key)")
                beginDownload()
            }
        }
    }

    private func beginDownload() {
        do {
            let payload = FileManager.default.temporaryDirectory.appendingPathComponent("payload.bin")
            try Data(count: 6 * 1024 * 1024).write(to: payload)
            log("Download shuru...")
            session.downloadTask(with: payload).resume()
            timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in self?.tick() }
        } catch { onFinish?(.failure(error)) }
    }

    /// Smooth fake pacing: progress eases up over ~4s, never passes real progress.
    private func tick() {
        guard finishedReal else { return }
        shown = min(1, shown + 0.0125)
        onProgress?(shown)
        if shown >= 1 { timer?.invalidate(); finish() }
    }

    private func finish() {
        log("Decrypt (mock) + mux ho raha hai...")
        do {
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let safe = title.replacingOccurrences(of: "/", with: "-")
            let out = docs.appendingPathComponent("\(safe).m4a")
            try? FileManager.default.removeItem(at: out)
            try writeSilentM4A(to: out, seconds: 5)
            log("Saved: \(out.lastPathComponent) (Files app > MusicDL)")
            onFinish?(.success(out))
        } catch { onFinish?(.failure(error)) }
    }

    private func writeSilentM4A(to url: URL, seconds: Int) throws {
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC, AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2, AVEncoderBitRateKey: 128000]
        let file = try AVAudioFile(forWriting: url, settings: settings)
        let fmt = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
        let frames = AVAudioFrameCount(44100)
        let buf = AVAudioPCMBuffer(pcmFormat: fmt, frameCapacity: frames)!
        buf.frameLength = frames // zeroed = silence
        for _ in 0..<seconds { try file.write(from: buf) }
    }

    // MARK: URLSessionDownloadDelegate
    func urlSession(_ s: URLSession, downloadTask t: URLSessionDownloadTask, didWriteData b: Int64,
                    totalBytesWritten w: Int64, totalBytesExpectedToWrite e: Int64) {
        if e > 0 { real = Float(w) / Float(e) }
    }

    func urlSession(_ s: URLSession, downloadTask t: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        downloaded = location
        finishedReal = true
    }

    func urlSession(_ s: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error { timer?.invalidate(); onFinish?(.failure(error)) }
    }

    private func log(_ m: String) { onLog?(m) }
    private func after(_ t: TimeInterval, _ b: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + t, execute: b)
    }
}
