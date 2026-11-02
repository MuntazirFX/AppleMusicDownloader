# MusicDL

MusicDL supports two separate workflows:

- **Play full Apple Music songs:** paste a song link and tap **Play full song with Apple Music**. The app requests MusicKit permission, resolves the catalog song, and plays it through Apple's `ApplicationMusicPlayer`.
- **Download direct audio files:** paste a direct URL to an audio file that you are authorized to download (for example, a DRM-free MP3 or M4A). The file is saved in the app's Documents folder.

## Apple Music limitation

Apple Music catalog streams are not downloadable/exportable as MP3/M4A files through MusicKit. The app therefore does not pretend that a 30-second preview is a full download and does not try to extract protected audio. Full catalog playback requires an eligible Apple Music subscription and the user's authorization. Offline downloads managed by the Apple Music app remain inside Apple's app and are not exposed as files to MusicDL.

## Setup

1. Open the project with Xcode (iOS deployment target 15.0).
2. Use a unique bundle identifier that belongs to your Apple Developer account.
3. In Certificates, Identifiers & Profiles, open that App ID and enable **MusicKit** under **App Services**. MusicKit is an App Service; do not add a made-up MusicKit entitlement.
4. Build and sign the app for a real iPhone. The repository's GitHub Actions workflow creates an **unsigned** IPA for build/testing distribution; unsigned IPA signing/installation and MusicKit account configuration must be handled separately.

## Build with GitHub Actions

Run **Build IPA** from the Actions tab. The workflow generates the Xcode project with XcodeGen, builds for `iphoneos`, packages `MusicDL.ipa`, and uploads it as an artifact.
