# MusicDL (mock)
Build (Mac / GitHub macOS runner):
  brew install xcodegen && xcodegen generate
  xcodebuild -project MusicDL.xcodeproj -scheme MusicDL -sdk iphoneos -configuration Release CODE_SIGNING_ALLOWED=NO -derivedDataPath build
  mkdir Payload && cp -r build/Build/Products/Release-iphoneos/MusicDL.app Payload/ && zip -r MusicDL.ipa Payload
Sideload MusicDL.ipa with SideStore.
