import Foundation
import MusicKit

/// Plays full Apple Music catalog tracks through Apple's authorized MusicKit player.
/// MusicKit content is streamed by Apple and is not exported as an audio file.
@MainActor
final class AppleMusicPlayer {
    private let player = ApplicationMusicPlayer.shared

    func playAppleMusicLink(_ url: URL) async throws -> String {
        guard let songID = Self.songID(from: url) else {
            throw MusicDLError.message("Apple Music song ID nahi mili. Song ka direct Apple Music link paste karo.")
        }

        let authorization = await MusicAuthorization.request()
        guard authorization == .authorized else {
            throw MusicDLError.message("Apple Music access allow karo: iPhone Settings > Privacy & Security > Media & Apple Music.")
        }

        var request = MusicCatalogResourceRequest<Song>(
            matching: \.id,
            equalTo: MusicItemID(songID)
        )
        request.limit = 1
        let response = try await request.response()
        guard let song = response.items.first else {
            throw MusicDLError.message("Apple Music catalog mein song nahi mila. Region ya link check karo.")
        }

        player.queue = [song]
        try await player.play()
        return "Playing full track: \(song.artistName) – \(song.title)"
    }

    func stop() async {
        player.stop()
    }

    private static func songID(from url: URL) -> String? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        if let id = components.queryItems?.first(where: { $0.name == "i" })?.value,
           !id.isEmpty, id.allSatisfy({ $0.isNumber }) {
            return id
        }
        if let last = url.pathComponents.last, !last.isEmpty, last.allSatisfy({ $0.isNumber }) {
            return last
        }
        return nil
    }
}

enum MusicDLError: LocalizedError {
    case message(String)
    var errorDescription: String? {
        if case let .message(message) = self { return message }
        return nil
    }
}
