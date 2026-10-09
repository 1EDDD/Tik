# GlassVideo iOS

An original iOS implementation inspired by the general idea of preparing video files before social upload. The app uses a provisional brand, a glass-inspired SwiftUI interface, and Arabic/English labels.

## Build without Xcode on your computer

Every push to main starts the Build unsigned iOS IPA workflow on a GitHub-hosted macOS runner. After a successful run, open the repository's Actions tab, open the latest run, and download the GlassVideo-unsigned-ipa artifact.

The artifact is deliberately unsigned. Import it into a compatible sideloading app that signs apps with your Apple ID. An unsigned IPA cannot be installed directly on a normal iPhone.

## Implemented in this first pass

- Original glass-style interface and generated app icon.
- In-app Arabic/English toggle and RTL layout.
- Video selection using a file-based transfer to avoid loading the whole movie into memory.
- Basic duration/file-size metadata.
- AVFoundation passthrough export where supported, attempting to avoid an extra encode.
- Save to Photos and share-sheet handoff.

## Known limitations

This first iOS implementation does not yet reproduce TikQuick's custom MP4 sample-table rewriting algorithm. Passthrough export is a conservative baseline and may not support every input/container/track combination. It cannot guarantee that TikTok will not recompress a video after upload. Unsupported files return an error instead of silently re-encoding.

The final product name, bundle identifier, developer display name, privacy policy, and device testing remain to be finalized.
