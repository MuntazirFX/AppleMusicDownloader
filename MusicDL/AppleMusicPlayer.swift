import Foundation
import MusicKit

/// Plays Apple Music catalog songs or complete albums using Apple's authorized MusicKit player.
/// Apple Music catalog audio remains protected and is never exported as an MP3/M4A file.
@MainActor
final class AppleMusicPlayer {
    private let player = ApplicationMusicPlayer.shared

    func playAppleMusicLink(_ url: URL) async throws -> String {
        guard let target = Self.target(from: url) else {
            throw MusicDLError.message("Apple Music song ya album link samajh nahi aaya. Full link paste karo.")
        }

        let authorization = await MusicAuthorization.request()
        guard authorization == .authorized else {
            throw MusicDLError.message("MusicDL ko Apple Music access allow karo: iPhone Settings > Privacy & Security > Media & Apple Music.")
        }

        switch target {
        case .song(let id):
            var request = MusicCatalogResourceRequest<Song>(matching: \.id, equalTo: MusicItemID(id))
            request.limit = 1
            let response = try await request.response()
            guard let song = response.items.first else {
                throw MusicDLError.message("Apple Music catalog mein song nahi mila. Region ya link check karo.")
            }
            player.queue = [song]
            try await player.play()
            return "Playing full song: \(song.artistName) – \(song.title)"

        case .album(let id):
            var request = MusicCatalogResourceRequest<Album>(matching: \.id, equalTo: MusicItemID(id))
            request.limit = 1
            let response = try await request.response()
            guard let album = response.items.first else {
                throw MusicDLError.message("Apple Music catalog mein album nahi mila. Region ya link check karo.")
            }
            player.queue = [album]
            try await player.play()
            return "Playing full album: \(album.title) – \(album.artistName)"
        }
    }

    func stop() async { player.stop() }

    private enum Target {
        case song(String)
        case album(String)
    }

    /// Supports song links with ?i=TRACK_ID and album links ending in ALBUM_ID.
    private static func target(from url: URL) -> Target? {
        guard let host = url.host?.lowercased(),
              host == "music.apple.com" || host.hasSuffix(".music.apple.com") || host == "itunes.apple.com" || host.hasSuffix(".itunes.apple.com"),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }

        if let id = components.queryItems?.first(where: { $0.name == "i" })?.value,
           isNumericCatalogID(id) {
            return .song(id)
        }

        let parts = url.pathComponents.filter { $0 != "/" && !$0.isEmpty }
        guard let last = parts.last, isNumericCatalogID(last) else { return nil }

        // Apple Music album URLs look like /{storefront}/album/{album-slug}/{album-id}.
        if parts.contains("album") { return .album(last) }
        // Song URLs can also end in a numeric catalog ID without ?i=.
        if parts.contains("song") { return .song(last) }
        return nil
    }

    private static func isNumericCatalogID(_ value: String) -> Bool {
        !value.isEmpty && value.allSatisfy { $0.isNumber }
    }
}

enum MusicDLError: LocalizedError {
    case message(String)
    var errorDescription: String? {
        if case let .message(message) = self { return message }
        return nil
    }
}
