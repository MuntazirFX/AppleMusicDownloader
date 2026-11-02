# MusicDL

MusicDL supports Apple Music catalog lookup and full-track / full-album playback through Apple's MusicKit framework. It also retains direct downloads for audio files hosted at direct, authorized, DRM-free URLs.

## Apple Music behavior

- Paste a song URL containing `?i=SONG_ID` to play that catalog song.
- Paste an album URL ending in an Apple Music album ID to play the album queue.
- Use **Play / Download** to start MusicKit playback for Apple Music URLs, or download a direct audio file URL.
- Use **Open link in Apple Music** to open the pasted Apple Music URL in Apple's Music app or browser.
- Apple Music catalog audio is protected. MusicDL does not export subscription catalog tracks as MP3/M4A files. For offline listening, add/download the music in Apple's Music app. See [Apple Support](https://support.apple.com/guide/iphone/add-music-and-listen-offline-iph0cff2d191/ios).

## Required Apple Developer setup

1. Register the app's Bundle ID in your Apple Developer account.
2. Enable **MusicKit** for that App ID in Certificates, Identifiers & Profiles.
3. In Xcode, use the same Team and Bundle ID, and ensure the MusicKit capability / entitlement is present.
4. Sign the app with a provisioning profile that includes the MusicKit entitlement. The included GitHub Actions workflow currently builds an **unsigned test IPA**; an unsigned IPA is not sufficient for MusicKit authorization on a device.
5. Install the signed app, grant Media & Apple Music permission, and use an Apple Music subscription for catalog playback.

## Build

The project is generated with XcodeGen:

```sh
brew install xcodegen
xcodegen generate
xcodebuild -project MusicDL.xcodeproj -scheme MusicDL -sdk iphoneos -configuration Release build
```
