# TikQuick APK inspection notes

Inspection target: TikQuick (3)(1).apk, examined as a ZIP/DEX package. The archive contains nine DEX files (classes.dex through classes9.dex), an Android manifest, Android resources, a bundled font, launcher artwork, and Dalvik bytecode.

## Findings visible in the bytecode strings

- Class identifiers include com.tikquick.app.mp4.Mp4Inspector and com.tikquick.app.mp4.Mp4QualityProcessor.
- Supporting types include Atom, Box, Track, Sample, SampleInfo, SampleTable, StscEntry, and Replacement.
- Recognized MP4 structures and errors include moov, moof, stco, co64, incomplete atom/header messages, invalid atom sizes, invalid chunk offsets, and file-size limits. This indicates custom MP4 box/sample-table inspection and rewriting rather than just changing a filename or extension.
- UI/resource strings include “Add Video”, “Fast video conversion”, “High Quality”, “High-quality video processing”, “Export failed”, and a direction to keep the original video audio without adding TikTok audio.
- The DEX includes video picker, input/output, and Android media-store identifiers.

## Porting decision

The current iOS baseline uses AVFoundation passthrough export. That can avoid decoding/re-encoding for supported formats, but it is not claimed to be equivalent to TikQuick's custom MP4 processor. Exact parity requires deeper bytecode decompilation and behavioral tests, followed by a native implementation of the necessary MP4 atom/sample-table logic.

## Not verified yet

- Exact algorithm used to rewrite MP4 atoms and sample tables.
- Accepted input formats/codecs and precise file-size boundaries.
- How much TikTok compression is reduced after upload.
- Behavior with HDR sources, high frame rates, and files with multiple audio/video tracks.
