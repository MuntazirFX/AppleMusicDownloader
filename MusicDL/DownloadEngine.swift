import Foundation

/// Real downloader: kisi bhi direct (DRM-free) file URL ko download karke
/// app ke Documents folder mein save karta hai (Files app > On My iPhone > MusicDL).
/// Apple Music / iTunes link dene pe Apple ki official iTunes API se 30-second preview clip download hota hai.
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
    private var preferredName: String?
    private var lookupTask: URLSessionDataTask?

    private static let mimeExt: [String: String] = [
        "audio/mp4": "m4a", "audio/x-m4a": "m4a", "audio/aac": "aac",
        "audio/mpeg": "mp3", "audio/mp3": "mp3", "audio/wav": "wav",
        "audio/x-wav": "wav", "audio/flac": "flac", "audio/ogg": "ogg"
    ]

    func start(url: URL) {
        finished = false
        preferredName = nil
        task = nil
        lookupTask = nil
        onProgress?(0, "")
        let host = (url.host ?? "").lowercased()
        if host.hasSuffix("music.apple.com") || host.hasSuffix("itunes.apple.com") {
            resolveApple(url: url, country: nil)
        } else {
            beginDownload(url)
        }
    }

    func cancel() {
        lookupTask?.cancel()
        if let t = task { t.cancel() } else if !finished {
            finished = true
            log("Cancelled")
            onFinish?(.failure(NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled)))
        }
    }

    private func beginDownload(_ url: URL) {
        sourceURL = url
        log("Connecting: \(url.host ?? url.absoluteString)")
        task = session.downloadTask(with: url)
        task?.resume()
    }

    // MARK: Apple Music link -> official 30s preview
    private static func appleID(from url: URL) -> String? {
        if let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let i = comps.queryItems?.first(where: { $0.name == "i" })?.value,
           !i.isEmpty, i.allSatisfy({ $0.isNumber }) { return i }
        if let last = url.pathComponents.last, !last.isEmpty, last.allSatisfy({ $0.isNumber }) { return last }
        return nil
    }

    private func resolveApple(url: URL, country: String?) {
        guard let id = DownloadEngine.appleID(from: url) else {
            return fail("Apple Music link se track ID nahi mili. Share Song se link copy karo.")
        }
        var urlCountry = "us"
        if url.pathComponents.count > 1, url.pathComponents[1].count == 2 {
            urlCountry = url.pathComponents[1]
        }
        let cc = country ?? urlCountry
        log("Apple Music link mila. iTunes API se preview dhoondh raha hu (\(cc))...")
        var c = URLComponents(string: "https://itunes.apple.com/lookup")!
        c.queryItems = [URLQueryItem(name: "id", value: id),
                        URLQueryItem(name: "country", value: cc),
                        URLQueryItem(name: "entity", value: "song")]
        lookupTask = URLSession.shared.dataTask(with: c.url!) { [weak self] data, _, error in
            DispatchQueue.main.async {
                guard let self, !self.finished else { return }
                if let error {
                    if (error as NSError).code == NSURLErrorCancelled {
                        self.finished = true
                        self.log("Cancelled")
                        self.onFinish?(.failure(error))
                        return
                    }
                    return self.fail("Lookup error: \(error.localizedDescription)")
                }
                var results: [[String: Any]] = []
                if let d = data,
                   let obj = try? JSONSerialization.jsonObject(with: d) as? [String: Any],
                   let arr = obj["results"] as? [[String: Any]] {
                    results = arr
                }
                guard let track = results.first(where: { ($0["previewUrl"] as? String) != nil }),
                      let prev = track["previewUrl"] as? String, let pURL = URL(string: prev) else {
                    if cc != "us" { return self.resolveApple(url: url, country: "us") }
                    return self.fail("Is link ka preview nahi mila.")
                }
                let name = track["trackName"] as? String ?? "Track"
                let artist = track["artistName"] as? String ?? ""
                self.log("Mila: \(artist) - \(name)")
                self.log("Note: Apple sirf 30 sec ka preview deta hai.")
                self.preferredName = (artist.isEmpty ? name : "\(artist) - \(name)") + " (preview).m4a"
                self.beginDownload(pURL)
            }
        }
        lookupTask?.resume()
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
        var name = preferredName ?? response?.suggestedFilename ?? original.lastPathComponent
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
