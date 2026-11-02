import Foundation

/// Real downloader: kisi bhi direct (DRM-free) file URL ko download karke
/// app ke Documents folder mein save karta hai (Files app > On My iPhone > MusicDL).
final class DownloadEngine: NSObject, URLSessionDownloadDelegate {

    var onLog: ((String) -> Void)?
    var onProgress: ((Float, String) -> Void)?
    var onFinish: ((Result<URL, Error>) -> Void)?

    private lazy var session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 30
        return URLSession(configuration: cfg, delegate: self, delegateQueue: .main)
    }()
    private var task: URLSessionDownloadTask?
    private var sourceURL: URL?
    private var finished = false

    private static let mimeExt: [String: String] = [
        "audio/mp4": "m4a", "audio/x-m4a": "m4a", "audio/aac": "aac",
        "audio/mpeg": "mp3", "audio/mp3": "mp3", "audio/wav": "wav",
        "audio/x-wav": "wav", "audio/flac": "flac", "audio/ogg": "ogg"
    ]

    func start(url: URL) {
        finished = false
        sourceURL = url
        onProgress?(0, "")
        log("Connecting: \(url.host ?? url.absoluteString)")
        task = session.downloadTask(with: url)
        task?.resume()
    }

    func cancel() {
        task?.cancel()
    }

    // MARK: URLSessionDownloadDelegate
    func urlSession(_ s: URLSession, downloadTask t: URLSessionDownloadTask, didWriteData b: Int64,
                    totalBytesWritten w: Int64, totalBytesExpectedToWrite e: Int64) {
        let mb = { (x: Int64) in String(format: "%.1f MB", Double(x) / 1_048_576) }
        if e > 0 {
            onProgress?(Float(w) / Float(e), "\(mb(w)) / \(mb(e))")
        } else {
            onProgress?(0, "\(mb(w)) (size unknown)")
        }
    }

    func urlSession(_ s: URLSession, downloadTask t: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // temp file is deleted after this method returns, so move it right now.
        if let http = t.response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            return fail("Server ne HTTP \(http.statusCode) diya. Link check karo.")
        }
        if let mime = t.response?.mimeType, mime.hasPrefix("text/") {
            return fail("Ye direct file nahi, webpage hai (\(mime)). Direct audio file ka link do.")
        }
        do {
            let dest = destination(for: t.response, original: sourceURL!)
            try FileManager.default.moveItem(at: location, to: dest)
            finished = true
            onProgress?(1, "")
            log("Saved: \(dest.lastPathComponent)")
            log("Files app > On My iPhone > MusicDL")
            onFinish?(.success(dest))
        } catch {
            fail("Save fail: \(error.localizedDescription)")
        }
    }

    func urlSession(_ s: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error, !finished else { return }
        finished = true
        if (error as NSError).code == NSURLErrorCancelled {
            log("Cancelled")
        } else {
            log("Error: \(error.localizedDescription)")
        }
        onFinish?(.failure(error))
    }

    // MARK: Helpers
    private func fail(_ msg: String) {
        finished = true
        log(msg)
        onFinish?(.failure(NSError(domain: "MusicDL", code: 1, userInfo: [NSLocalizedDescriptionKey: msg])))
    }

    private func destination(for response: URLResponse?, original: URL) -> URL {
        var name = response?.suggestedFilename ?? original.lastPathComponent
        name = name.removingPercentEncoding ?? name
        name = name.replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: ":", with: "-")
        if name.isEmpty { name = "download" }
        if (name as NSString).pathExtension.isEmpty,
           let mime = response?.mimeType, let ext = DownloadEngine.mimeExt[mime] {
            name += "." + ext
        }
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let base = (name as NSString).deletingPathExtension
        let ext = (name as NSString).pathExtension
        var dest = docs.appendingPathComponent(name)
        var i = 1
        while FileManager.default.fileExists(atPath: dest.path) {
            dest = docs.appendingPathComponent("\(base) (\(i))" + (ext.isEmpty ? "" : "." + ext))
            i += 1
        }
        return dest
    }

    private func log(_ m: String) { onLog?(m) }
}
