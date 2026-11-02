# MusicDL — Apple Music edition

MusicDL uses Apple's native MusicKit framework for catalog lookup and full-song/full-album playback. Apple Music subscription catalog audio is DRM-protected and cannot be exported by this app as MP3/M4A. The direct downloader remains for authorized, DRM-free audio file URLs.

## Fix for “Failed to request developer token”

MusicKit on iOS normally manages developer tokens automatically. Do not paste a manually generated JWT into this native app. Apple requires MusicKit to be enabled as an App Service for the exact App ID used by the installed app, and the app must be signed for that registered Bundle ID. An unsigned IPA is not a valid MusicKit device build.

1. In Apple Developer → Certificates, Identifiers & Profiles → Identifiers, open/create the exact App ID matching your app Bundle ID.
2. Open App Services, enable **MusicKit**, and save.
3. Use the same Apple Developer Team for signing.
4. Create an **Apple Distribution** certificate exported as `.p12`. Create an **Ad Hoc** provisioning profile for the exact Bundle ID and include the iPhone UDIDs where you will install the IPA.
5. In GitHub repository → Settings → Secrets and variables → Actions, add these repository secrets:
   - `IOS_BUNDLE_ID` — exact registered Bundle ID (not `com.example.MusicDL`).
   - `APPLE_TEAM_ID` — 10-character Apple Developer Team ID.
   - `APPLE_DISTRIBUTION_P12_BASE64` — base64 of the distribution `.p12` file.
   - `APPLE_DISTRIBUTION_P12_PASSWORD` — password used when exporting the `.p12`.
   - `APPLE_ADHOC_PROFILE_BASE64` — base64 of the Ad Hoc `.mobileprovision` file.
6. Run Actions → **Build signed MusicDL IPA**. Install the generated signed IPA, then allow Media & Apple Music access when prompted.

Example base64 commands (run locally; do not commit the resulting secrets):

```sh
base64 -i AppleDistribution.p12 | pbcopy
base64 -i MusicDL_AdHoc.mobileprovision | pbcopy
```

## Local build

```sh
brew install xcodegen
xcodegen generate
xcodebuild -project MusicDL.xcodeproj -scheme MusicDL -sdk iphoneos -configuration Release build
```

For device MusicKit use, configure signing in Xcode with the same registered App ID and Team.
