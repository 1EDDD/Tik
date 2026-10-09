import SwiftUI
import PhotosUI
import AVFoundation
import Photos
import UIKit
import UniformTypeIdentifiers

private struct ImportedMovie: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(importedContentType: .movie) { received in
            let source = received.file
            let ext = source.pathExtension.isEmpty ? "mov" : source.pathExtension
            let destination = FileManager.default.temporaryDirectory
                .appendingPathComponent("GlassVideo-\(UUID().uuidString).\(ext)")
            try FileManager.default.copyItem(at: source, to: destination)
            return ImportedMovie(url: destination)
        }
    }
}

struct ContentView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var sourceURL: URL?
    @State private var outputURL: URL?
    @State private var durationText = "—"
    @State private var sizeText = "—"
    @State private var isProcessing = false
    @State private var status = ""
    @State private var showShare = false
    @State private var isArabic = Locale.preferredLanguages.first?.hasPrefix("ar") == true

    private var titleText: String { isArabic ? "استوديو الفيديو" : "Video Studio" }
    private var subtitleText: String {
        isArabic
        ? "جهّز فيديوك للنشر مع محاولة الحفاظ على الترميز الأصلي."
        : "Prepare a video for posting while attempting to preserve its original encoding."
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.035, green: 0.04, blue: 0.10),
                    Color(red: 0.12, green: 0.07, blue: 0.22),
                    Color(red: 0.025, green: 0.04, blue: 0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ).ignoresSafeArea()

            Circle().fill(Color.purple.opacity(0.22)).frame(width: 240)
                .blur(radius: 65).offset(x: 135, y: -280)
            Circle().fill(Color.cyan.opacity(0.12)).frame(width: 210)
                .blur(radius: 70).offset(x: -145, y: 250)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                                .overlay { RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.22)) }
                            Image(systemName: "sparkles.rectangle.stack.fill")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(LinearGradient(colors: [.cyan, .purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                        }.frame(width: 48, height: 48)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("GLASS VIDEO").font(.system(size: 12, weight: .bold, design: .rounded))
                                .tracking(2.2).foregroundStyle(.white.opacity(0.65))
                            Text(titleText).font(.system(size: 23, weight: .bold, design: .rounded))
                        }
                        Spacer()
                        Button { isArabic.toggle() } label: {
                            Text(isArabic ? "EN" : "ع").font(.system(size: 14, weight: .bold))
                                .padding(.horizontal, 14).padding(.vertical, 10)
                                .background(.ultraThinMaterial, in: Capsule())
                                .overlay { Capsule().stroke(.white.opacity(0.18)) }
                        }.buttonStyle(.plain)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text(isArabic ? "كل إطار، بعناية." : "Every frame, handled with care.")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .fixedSize(horizontal: false, vertical: true)
                        Text(subtitleText).font(.system(size: 15))
                            .foregroundStyle(.white.opacity(0.67)).lineSpacing(4)
                    }.padding(.top, 8)

                    VStack(spacing: 14) {
                        if let url = sourceURL {
                            VideoPreviewCard(url: url, duration: durationText, size: sizeText, isArabic: isArabic)
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: 22).fill(.white.opacity(0.045)).frame(height: 150)
                                RoundedRectangle(cornerRadius: 22)
                                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [6, 6]))
                                    .foregroundStyle(.white.opacity(0.20)).frame(height: 150)
                                VStack(spacing: 12) {
                                    Image(systemName: "arrow.up.doc").font(.system(size: 30, weight: .light)).foregroundStyle(.cyan)
                                    Text(isArabic ? "اختر فيديو من مكتبتك" : "Choose a video from your library")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text(isArabic ? "ملفات الفيديو • حتى 4K حسب الجهاز" : "Video files • up to 4K depending on device support")
                                        .font(.system(size: 12)).foregroundStyle(.white.opacity(0.55))
                                }
                            }
                        }

                        PhotosPicker(selection: $selectedItem, matching: .videos, photoLibrary: .shared()) {
                            Label(isArabic ? "اختيار فيديو" : "Choose Video", systemImage: "plus.circle.fill")
                                .font(.system(size: 16, weight: .bold)).frame(maxWidth: .infinity).padding(.vertical, 17)
                                .background(LinearGradient(colors: [Color.cyan.opacity(0.9), Color.purple.opacity(0.92)], startPoint: .leading, endPoint: .trailing), in: RoundedRectangle(cornerRadius: 18))
                        }
                        .buttonStyle(.plain)
                        .onChange(of: selectedItem) { newItem in
                            Task { await loadVideo(newItem) }
                        }
                    }
                    .padding(16).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28))
                    .overlay { RoundedRectangle(cornerRadius: 28).stroke(.white.opacity(0.15), lineWidth: 1) }

                    VStack(alignment: .leading, spacing: 12) {
                        Text(isArabic ? "طريقة العمل" : "Workflow").font(.system(size: 18, weight: .bold))
                        HStack(spacing: 12) {
                            FeatureTile(icon: "waveform.path", title: isArabic ? "الترميز الأصلي" : "Original streams",
                                        detail: isArabic ? "بدون إعادة ترميز عند الدعم" : "No re-encoding where supported")
                            FeatureTile(icon: "lock.shield", title: isArabic ? "على جهازك" : "On-device",
                                        detail: isArabic ? "لا نرفع الفيديو إلى خادم" : "No video upload to a server")
                        }
                    }

                    if !status.isEmpty {
                        Text(status).font(.system(size: 13, weight: .medium)).foregroundStyle(.white.opacity(0.82))
                            .padding(14).frame(maxWidth: .infinity, alignment: .leading)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                    }

                    if sourceURL != nil {
                        Button(action: processVideo) {
                            HStack {
                                if isProcessing { ProgressView().tint(.white) } else { Image(systemName: "sparkles") }
                                Text(isProcessing ? (isArabic ? "جارٍ التجهيز..." : "Preparing...")
                                     : (isArabic ? "معالجة وحفظ الفيديو" : "Process & Save Video"))
                            }
                            .font(.system(size: 16, weight: .bold)).frame(maxWidth: .infinity).padding(.vertical, 17)
                            .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 18))
                            .overlay { RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.2)) }
                        }.buttonStyle(.plain).disabled(isProcessing)
                    }

                    Text(isArabic
                         ? "ملاحظة: الحفاظ على الترميز لا يضمن أن تيك توك لن يضغط الفيديو بعد رفعه."
                         : "Note: preserving encoding cannot guarantee TikTok will not recompress the video after upload.")
                        .font(.system(size: 11)).foregroundStyle(.white.opacity(0.42)).padding(.top, 2)
                }
                .padding(.horizontal, 20).padding(.top, 18).padding(.bottom, 34)
            }
        }
        .environment(\.layoutDirection, isArabic ? .rightToLeft : .leftToRight)
        .sheet(isPresented: $showShare) {
            if let outputURL { ShareSheet(items: [outputURL]) }
        }
    }

    @MainActor
    private func loadVideo(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            guard let imported = try await item.loadTransferable(type: ImportedMovie.self) else {
                status = isArabic ? "تعذر قراءة الفيديو المختار." : "Could not read the selected video."
                return
            }
            sourceURL = imported.url
            outputURL = nil
            let asset = AVURLAsset(url: imported.url)
            let duration = try await asset.load(.duration)
            let seconds = CMTimeGetSeconds(duration)
            durationText = seconds.isFinite ? String(format: "%.1f s", seconds) : "—"
            let bytes = (try? imported.url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            sizeText = ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
            status = isArabic ? "تم اختيار الفيديو. جاهز للمعالجة." : "Video selected and ready to process."
        } catch {
            status = (isArabic ? "تعذر تحميل الفيديو: " : "Unable to load video: ") + error.localizedDescription
        }
    }

    private func processVideo() {
        guard let sourceURL else { return }
        isProcessing = true
        status = isArabic
            ? "يجري تصدير الفيديو دون إعادة ترميز عند دعم الملف..."
            : "Exporting without re-encoding where the file supports it..."

        Task {
            do {
                let asset = AVURLAsset(url: sourceURL)
                guard let session = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough) else {
                    throw NSError(domain: "GlassVideo", code: 1,
                                  userInfo: [NSLocalizedDescriptionKey: "Passthrough export is unavailable for this file."])
                }
                let destination = FileManager.default.temporaryDirectory
                    .appendingPathComponent("GlassVideo-\(UUID().uuidString).mp4")
                session.outputURL = destination
                session.outputFileType = .mp4
                session.shouldOptimizeForNetworkUse = true

                let result: (AVAssetExportSession.Status, Error?) = await withCheckedContinuation { continuation in
                    session.exportAsynchronously {
                        continuation.resume(returning: (session.status, session.error))
                    }
                }
                guard result.0 == .completed else {
                    throw result.1 ?? NSError(domain: "GlassVideo", code: 2,
                        userInfo: [NSLocalizedDescriptionKey: "Export did not complete. The input may not support MP4 passthrough."])
                }

                let savedToPhotos: Bool
                do {
                    try await saveToPhotos(destination)
                    savedToPhotos = true
                } catch {
                    savedToPhotos = false
                }

                await MainActor.run {
                    outputURL = destination
                    status = savedToPhotos
                        ? (isArabic ? "اكتمل التصدير والحفظ في الصور. يمكنك مشاركة الفيديو أيضًا." : "Exported and saved to Photos. You can also share the video.")
                        : (isArabic ? "اكتمل التصدير، لكن تعذر الحفظ في الصور. يمكنك مشاركة الملف." : "Export completed, but saving to Photos failed. You can still share the file.")
                    isProcessing = false
                    showShare = true
                }
            } catch {
                await MainActor.run {
                    status = (isArabic ? "تعذرت المعالجة: " : "Processing failed: ") + error.localizedDescription
                    isProcessing = false
                }
            }
        }
    }

    private func saveToPhotos(_ url: URL) async throws {
        let authorization = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard authorization == .authorized || authorization == .limited else {
            throw NSError(domain: "GlassVideo", code: 3,
                          userInfo: [NSLocalizedDescriptionKey: "Photos permission was not granted."])
        }
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }
    }
}

private struct VideoPreviewCard: View {
    let url: URL
    let duration: String
    let size: String
    let isArabic: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "film").font(.system(size: 22)).foregroundStyle(.cyan)
                VStack(alignment: .leading, spacing: 3) {
                    Text(isArabic ? "الفيديو المحدد" : "Selected video").font(.system(size: 15, weight: .bold))
                    Text(url.lastPathComponent).font(.system(size: 11)).foregroundStyle(.white.opacity(0.55)).lineLimit(1)
                }
                Spacer()
                Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
            }
            HStack {
                Label(duration, systemImage: "clock")
                Spacer()
                Label(size, systemImage: "externaldrive")
            }.font(.system(size: 12, weight: .medium)).foregroundStyle(.white.opacity(0.68))
        }
        .padding(14).background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 18))
    }
}

private struct FeatureTile: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon).font(.system(size: 20)).foregroundStyle(.cyan)
            Text(title).font(.system(size: 13, weight: .bold))
            Text(detail).font(.system(size: 11)).foregroundStyle(.white.opacity(0.55))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
        .overlay { RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.12)) }
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
