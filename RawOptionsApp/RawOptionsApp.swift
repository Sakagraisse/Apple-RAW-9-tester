import AppKit
import CoreImage
import ImageIO
import QuickLookThumbnailing
import SwiftUI
import UniformTypeIdentifiers

enum RawMode: String, CaseIterable, Identifiable {
    case raw8 = "RAW 8"
    case raw9 = "RAW 9"

    var id: String { rawValue }
}

enum ExportFormat: String, CaseIterable, Identifiable {
    case jpeg = "JPEG"
    case png8 = "PNG 8-bit"

    var id: String { rawValue }

    var contentType: UTType {
        switch self {
        case .jpeg: return .jpeg
        case .png8: return .png
        }
    }

    var fileExtension: String {
        switch self {
        case .jpeg: return "jpg"
        case .png8: return "png"
        }
    }

    var filenameToken: String {
        switch self {
        case .jpeg: return "jpeg"
        case .png8: return "png8"
        }
    }
}

struct RawFile: Identifiable {
    let id = UUID()
    let url: URL

    var name: String { url.lastPathComponent }
    var folder: String { url.deletingLastPathComponent().path }
    var isDNG: Bool { url.pathExtension.lowercased() == "dng" }
}

struct RawSettings {
    var scaleFactor: Float = 1
    var draftModeEnabled = false
    var exposure: Float = 0
    var baselineExposure: Float = 0
    var shadowBias: Float = 0
    var boostAmount: Float = 1
    var boostShadowAmount: Float = 1
    var highlightRecoveryEnabled = false
    var gamutMappingEnabled = true
    var lensCorrectionEnabled = false
    var luminanceNoiseReductionAmount: Float = 0
    var colorNoiseReductionAmount: Float = 0
    var sharpnessAmount: Float = 0
    var contrastAmount: Float = 0
    var detailAmount: Float = 0
    var moireReductionAmount: Float = 0
    var despeckleAmount: Float = 0
    var localToneMapAmount: Float = 0
    var extendedDynamicRangeAmount: Float = 0
    var neutralTemperature: Float = 6500
    var neutralTint: Float = 0

    init() {}

    init(filter: CIRAWFilter) {
        scaleFactor = filter.scaleFactor
        draftModeEnabled = filter.isDraftModeEnabled
        exposure = filter.exposure
        baselineExposure = filter.baselineExposure
        shadowBias = filter.shadowBias
        boostAmount = filter.boostAmount
        boostShadowAmount = filter.boostShadowAmount
        highlightRecoveryEnabled = filter.isHighlightRecoveryEnabled
        gamutMappingEnabled = filter.isGamutMappingEnabled
        lensCorrectionEnabled = filter.isLensCorrectionEnabled
        luminanceNoiseReductionAmount = filter.luminanceNoiseReductionAmount
        colorNoiseReductionAmount = filter.colorNoiseReductionAmount
        sharpnessAmount = filter.sharpnessAmount
        contrastAmount = filter.contrastAmount
        detailAmount = filter.detailAmount
        moireReductionAmount = filter.moireReductionAmount
        despeckleAmount = filter.despeckleAmount
        localToneMapAmount = filter.localToneMapAmount
        extendedDynamicRangeAmount = filter.extendedDynamicRangeAmount
        neutralTemperature = filter.neutralTemperature
        neutralTint = filter.neutralTint
    }
}

struct RawSupport {
    var decoder = false
    var highlightRecovery = false
    var lensCorrection = false
    var luminanceNoiseReduction = false
    var colorNoiseReduction = false
    var sharpness = false
    var contrast = false
    var detail = false
    var moireReduction = false
    var despeckle = false
    var localToneMap = false
}

final class RawOptionsModel: ObservableObject {
    @Published var files: [RawFile] = []
    @Published var selectedFileID: RawFile.ID?
    @Published var mode: RawMode = .raw9
    @Published var settings = RawSettings()
    @Published var support = RawSupport()
    @Published var exportFormat: ExportFormat = .jpeg
    @Published var isDropTargeted = false
    @Published var statusText = "Drop RAW or DNG files"
    @Published var metadataText = ""
    @Published private(set) var thumbnails: [RawFile.ID: NSImage] = [:]

    private let rawExtensions: Set<String> = [
        "3fr", "arw", "cr2", "cr3", "dng", "erf", "fff", "iiq", "kdc",
        "mos", "mrw", "nef", "nrw", "orf", "pef", "raf", "raw", "rw2", "srw"
    ]

    var selectedFile: RawFile? {
        files.first { $0.id == selectedFileID }
    }

    func thumbnail(for file: RawFile) -> NSImage? {
        thumbnails[file.id]
    }

    func addDroppedProviders(_ providers: [NSItemProvider]) -> Bool {
        var accepted = false
        for provider in providers where provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            accepted = true
            provider.loadObject(ofClass: NSURL.self) { [weak self] item, _ in
                guard let url = item as? URL else { return }
                DispatchQueue.main.async { self?.addURL(url) }
            }
        }
        return accepted
    }

    func chooseFiles() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.rawImage, .image]
        if panel.runModal() == .OK {
            panel.urls.forEach(addURL)
        }
    }

    func removeSelectedFile() {
        guard let file = selectedFile else { return }
        files.removeAll { $0.id == file.id }
        thumbnails[file.id] = nil
        selectedFileID = files.first?.id
        loadDefaultsForSelection()
    }

    func clearFiles() {
        files = []
        thumbnails = [:]
        selectedFileID = nil
        loadDefaultsForSelection()
    }

    func loadDefaultsForSelection() {
        guard let file = selectedFile else {
            support = RawSupport()
            settings = RawSettings()
            statusText = "Drop RAW or DNG files"
            metadataText = ""
            return
        }

        guard let filter = configuredFilter(for: file, applyingSettings: false) else {
            support = RawSupport()
            settings = RawSettings()
            statusText = "Core Image cannot open this RAW file."
            metadataText = file.name
            return
        }

        metadataText = metadataSummary(for: filter, file: file)
        support = supportSummary(for: filter)

        guard support.decoder else {
            settings = RawSettings()
            let versions = filter.supportedDecoderVersions.map(\.rawValue).joined(separator: ", ")
            statusText = "\(mode.rawValue) is not available for \(file.name). Available: \(versions)"
            return
        }

        settings = RawSettings(filter: filter)
        statusText = "Default \(mode.rawValue) settings loaded"
    }

    func resetToDefaults() {
        loadDefaultsForSelection()
    }

    func exportSelectedFile() {
        guard let file = selectedFile else {
            statusText = "Select a RAW file before exporting."
            return
        }
        guard support.decoder else {
            statusText = "\(mode.rawValue) is not available for this file."
            return
        }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [exportFormat.contentType]
        let decoderToken = mode.rawValue.replacingOccurrences(of: " ", with: "").lowercased()
        panel.nameFieldStringValue = "\(file.url.deletingPathExtension().lastPathComponent)-\(decoderToken)-\(exportFormat.filenameToken).\(exportFormat.fileExtension)"
        if panel.runModal() == .OK, let destination = panel.url {
            do {
                try export(file: file, to: destination, format: exportFormat)
                statusText = "Exported \(destination.lastPathComponent)"
            } catch {
                statusText = "Export failed: \(error.localizedDescription)"
            }
        }
    }

    private func addURL(_ url: URL) {
        let standardized = url.standardizedFileURL
        guard rawExtensions.contains(standardized.pathExtension.lowercased()) else {
            statusText = "Ignored unsupported file: \(standardized.lastPathComponent)"
            return
        }
        guard !files.contains(where: { $0.url == standardized }) else { return }

        let file = RawFile(url: standardized)
        files.append(file)
        files.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        if selectedFileID == nil || files.count == 1 {
            selectedFileID = file.id
        }
        loadThumbnail(for: file)
        loadDefaultsForSelection()
    }

    private func decoderVersion(for file: RawFile) -> CIRAWDecoderVersion {
        switch (mode, file.isDNG) {
        case (.raw8, true): return .version8DNG
        case (.raw8, false): return .version8
        case (.raw9, true): return .version9DNG
        case (.raw9, false): return .version9
        }
    }

    private func configuredFilter(for file: RawFile, applyingSettings: Bool) -> CIRAWFilter? {
        guard let filter = CIRAWFilter(imageURL: file.url) else { return nil }
        let decoder = decoderVersion(for: file)
        if filter.supportedDecoderVersions.contains(decoder) {
            filter.decoderVersion = decoder
        }
        filter.scaleFactor = applyingSettings ? settings.scaleFactor : 1
        filter.isDraftModeEnabled = applyingSettings ? settings.draftModeEnabled : false
        if applyingSettings {
            apply(settings: settings, support: support, to: filter)
        }
        return filter
    }

    private func apply(settings: RawSettings, support: RawSupport, to filter: CIRAWFilter) {
        filter.exposure = settings.exposure
        filter.baselineExposure = settings.baselineExposure
        filter.shadowBias = settings.shadowBias
        filter.boostAmount = settings.boostAmount
        filter.boostShadowAmount = settings.boostShadowAmount
        filter.isGamutMappingEnabled = settings.gamutMappingEnabled
        filter.extendedDynamicRangeAmount = settings.extendedDynamicRangeAmount
        filter.neutralTemperature = settings.neutralTemperature
        filter.neutralTint = settings.neutralTint

        if support.highlightRecovery { filter.isHighlightRecoveryEnabled = settings.highlightRecoveryEnabled }
        if support.lensCorrection { filter.isLensCorrectionEnabled = settings.lensCorrectionEnabled }
        if support.luminanceNoiseReduction { filter.luminanceNoiseReductionAmount = settings.luminanceNoiseReductionAmount }
        if support.colorNoiseReduction { filter.colorNoiseReductionAmount = settings.colorNoiseReductionAmount }
        if support.sharpness { filter.sharpnessAmount = settings.sharpnessAmount }
        if support.contrast { filter.contrastAmount = settings.contrastAmount }
        if support.detail { filter.detailAmount = settings.detailAmount }
        if support.moireReduction { filter.moireReductionAmount = settings.moireReductionAmount }
        if support.despeckle { filter.despeckleAmount = settings.despeckleAmount }
        if support.localToneMap { filter.localToneMapAmount = settings.localToneMapAmount }
    }

    private func supportSummary(for filter: CIRAWFilter) -> RawSupport {
        let decoder = selectedFile.map { decoderVersion(for: $0) }
        return RawSupport(
            decoder: decoder.map { filter.supportedDecoderVersions.contains($0) } ?? false,
            highlightRecovery: filter.isHighlightRecoverySupported,
            lensCorrection: filter.isLensCorrectionSupported,
            luminanceNoiseReduction: filter.isLuminanceNoiseReductionSupported,
            colorNoiseReduction: filter.isColorNoiseReductionSupported,
            sharpness: filter.isSharpnessSupported,
            contrast: filter.isContrastSupported,
            detail: filter.isDetailSupported,
            moireReduction: filter.isMoireReductionSupported,
            despeckle: filter.isDespeckleSupported,
            localToneMap: filter.isLocalToneMapSupported
        )
    }

    private func metadataSummary(for filter: CIRAWFilter, file: RawFile) -> String {
        let tiff = filter.properties[kCGImagePropertyTIFFDictionary as String] as? [String: Any]
        let model = tiff?[kCGImagePropertyTIFFModel as String] as? String ?? "Unknown camera"
        return "\(file.name) · \(model) · \(Int(filter.nativeSize.width)) x \(Int(filter.nativeSize.height))"
    }

    private func loadThumbnail(for file: RawFile) {
        let request = QLThumbnailGenerator.Request(
            fileAt: file.url,
            size: CGSize(width: 160, height: 160),
            scale: NSScreen.main?.backingScaleFactor ?? 2,
            representationTypes: [.thumbnail, .icon]
        )
        QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { [weak self] representation, _ in
            let thumbnail = representation?.nsImage ?? self?.makeCoreImageThumbnail(for: file.url)
            guard let thumbnail else { return }
            DispatchQueue.main.async { self?.thumbnails[file.id] = thumbnail }
        }
    }

    private func makeCoreImageThumbnail(for url: URL) -> NSImage? {
        guard let filter = CIRAWFilter(imageURL: url) else { return nil }
        filter.scaleFactor = 0.04
        filter.isDraftModeEnabled = true
        guard let image = filter.outputImage?.oriented(filter.orientation) else { return nil }

        let context = CIContext(options: [.cacheIntermediates: false])
        let extent = image.extent.integral
        let maxSide: CGFloat = 96
        let scale = min(maxSide / max(extent.width, extent.height), 1)
        let thumbnailImage = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let bounds = thumbnailImage.extent.integral
        let width = Int(bounds.width)
        let height = Int(bounds.height)
        let rowBytes = width * 4
        var pixels = Data(count: rowBytes * height)
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!

        pixels.withUnsafeMutableBytes { buffer in
            context.render(thumbnailImage, toBitmap: buffer.baseAddress!, rowBytes: rowBytes, bounds: bounds, format: .RGBA8, colorSpace: colorSpace)
        }
        guard let provider = CGDataProvider(data: pixels as CFData),
              let cgImage = CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: rowBytes, space: colorSpace, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue), provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent) else { return nil }
        return NSImage(cgImage: cgImage, size: NSSize(width: width, height: height))
    }

    private func export(file: RawFile, to destination: URL, format: ExportFormat) throws {
        guard let filter = configuredFilter(for: file, applyingSettings: true),
              let image = filter.outputImage?.oriented(filter.orientation) else {
            throw NSError(domain: "RawOptions", code: 1, userInfo: [NSLocalizedDescriptionKey: "The RAW decoder did not produce an image."])
        }
        let context = CIContext(options: [.cacheIntermediates: false])
        let bounds = image.extent.integral
        switch format {
        case .jpeg: try exportJPEG(image: image, bounds: bounds, context: context, to: destination)
        case .png8: try exportPNG8(image: image, bounds: bounds, context: context, to: destination)
        }
    }

    private func exportJPEG(image: CIImage, bounds: CGRect, context: CIContext, to destination: URL) throws {
        guard let cgImage = context.createCGImage(image, from: bounds) else {
            throw NSError(domain: "RawOptions", code: 2, userInfo: [NSLocalizedDescriptionKey: "The image could not be rendered."])
        }
        guard let destinationRef = CGImageDestinationCreateWithURL(destination as CFURL, UTType.jpeg.identifier as CFString, 1, nil) else {
            throw NSError(domain: "RawOptions", code: 3, userInfo: [NSLocalizedDescriptionKey: "The JPEG destination could not be created."])
        }
        CGImageDestinationAddImage(destinationRef, cgImage, [kCGImageDestinationLossyCompressionQuality: 0.95] as CFDictionary)
        if !CGImageDestinationFinalize(destinationRef) {
            throw NSError(domain: "RawOptions", code: 4, userInfo: [NSLocalizedDescriptionKey: "The JPEG file could not be written."])
        }
    }

    private func exportPNG8(image: CIImage, bounds: CGRect, context: CIContext, to destination: URL) throws {
        let width = Int(bounds.width)
        let height = Int(bounds.height)
        guard width > 0, height > 0 else {
            throw NSError(domain: "RawOptions", code: 5, userInfo: [NSLocalizedDescriptionKey: "The image has an empty extent."])
        }
        let rowBytes = width * 4
        var pixels = Data(count: rowBytes * height)
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        pixels.withUnsafeMutableBytes { buffer in
            context.render(image, toBitmap: buffer.baseAddress!, rowBytes: rowBytes, bounds: bounds, format: .RGBA8, colorSpace: colorSpace)
        }
        guard let provider = CGDataProvider(data: pixels as CFData),
              let cgImage = CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: rowBytes, space: colorSpace, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue), provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent) else {
            throw NSError(domain: "RawOptions", code: 6, userInfo: [NSLocalizedDescriptionKey: "The 8-bit PNG image could not be created."])
        }
        guard let destinationRef = CGImageDestinationCreateWithURL(destination as CFURL, UTType.png.identifier as CFString, 1, nil) else {
            throw NSError(domain: "RawOptions", code: 7, userInfo: [NSLocalizedDescriptionKey: "The PNG destination could not be created."])
        }
        CGImageDestinationAddImage(destinationRef, cgImage, nil)
        if !CGImageDestinationFinalize(destinationRef) {
            throw NSError(domain: "RawOptions", code: 8, userInfo: [NSLocalizedDescriptionKey: "The PNG file could not be written."])
        }
    }
}

struct ContentView: View {
    @StateObject private var model = RawOptionsModel()

    var body: some View {
        GeometryReader { geometry in
            Group {
                if geometry.size.width < 780 {
                    VStack(spacing: 0) {
                        DropPane(model: model).frame(minHeight: 250, maxHeight: 330)
                        Divider()
                        OptionsPane(model: model)
                    }
                } else {
                    HStack(spacing: 0) {
                        DropPane(model: model).frame(minWidth: 260, idealWidth: 340, maxWidth: 420)
                        Divider()
                        OptionsPane(model: model)
                    }
                }
            }
        }
        .frame(minWidth: 620, minHeight: 560)
        .onChange(of: model.mode) { _, _ in model.loadDefaultsForSelection() }
        .onChange(of: model.selectedFileID) { _, _ in model.loadDefaultsForSelection() }
    }
}

struct DropPane: View {
    @ObservedObject var model: RawOptionsModel

    var body: some View {
        VStack(spacing: 12) {
            dropZone
            if model.files.isEmpty {
                Spacer(minLength: 0)
                Text("No files loaded").font(.callout).foregroundStyle(.secondary)
                Spacer(minLength: 0)
            } else {
                List(selection: $model.selectedFileID) {
                    ForEach(model.files) { file in
                        HStack(spacing: 10) {
                            ThumbnailView(image: model.thumbnail(for: file))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(file.name).font(.system(.body, design: .rounded)).lineLimit(1)
                                Text(file.folder).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                            }
                        }
                        .padding(.vertical, 4)
                        .tag(file.id)
                    }
                }
                .listStyle(.sidebar)
            }
            HStack {
                Button("Add") { model.chooseFiles() }
                Button("Remove") { model.removeSelectedFile() }.disabled(model.selectedFile == nil)
                Spacer()
                Button("Clear") { model.clearFiles() }.disabled(model.files.isEmpty)
            }
            .padding([.horizontal, .bottom], 14)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var dropZone: some View {
        VStack(spacing: 8) {
            Image(systemName: "photo.badge.plus").font(.system(size: 30, weight: .semibold)).foregroundStyle(model.isDropTargeted ? Color.accentColor : Color.secondary)
            Text("Drop RAW / DNG files").font(.headline).lineLimit(1).minimumScaleFactor(0.8)
            Text("One or more photos").font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity).frame(minHeight: 118).padding(.horizontal, 12)
        .background(RoundedRectangle(cornerRadius: 8).fill(model.isDropTargeted ? Color.accentColor.opacity(0.14) : Color(nsColor: .textBackgroundColor)))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(model.isDropTargeted ? Color.accentColor : Color.secondary.opacity(0.28), style: StrokeStyle(lineWidth: 1.5, dash: [7, 5])))
        .padding(14)
        .onDrop(of: [UTType.fileURL.identifier], isTargeted: $model.isDropTargeted) { model.addDroppedProviders($0) }
    }
}

struct ThumbnailView: View {
    let image: NSImage?
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6).fill(Color.secondary.opacity(0.12))
            if let image {
                Image(nsImage: image).resizable().scaledToFill().frame(width: 46, height: 46).clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                Image(systemName: "photo").font(.system(size: 18, weight: .medium)).foregroundStyle(.secondary)
            }
        }
        .frame(width: 46, height: 46)
        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color.secondary.opacity(0.18)))
    }
}

struct OptionsPane: View {
    @ObservedObject var model: RawOptionsModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            if model.mode == .raw9, model.selectedFile != nil, !model.support.decoder {
                Raw9WarningView { model.mode = .raw8 }
                Divider()
            }
            if model.selectedFile == nil {
                ContentUnavailableView("No RAW selected", systemImage: "slider.horizontal.3", description: Text("Drop a RAW file on the left to inspect and edit decoder settings."))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView { settingsControls.padding(18) }
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.statusText).font(.headline)
                    if !model.metadataText.isEmpty { Text(model.metadataText).font(.caption).foregroundStyle(.secondary).lineLimit(1) }
                }
                Spacer()
                Toggle(isOn: Binding(get: { model.mode == .raw9 }, set: { model.mode = $0 ? .raw9 : .raw8 })) {
                    Text(model.mode.rawValue).font(.system(.body, design: .rounded).weight(.semibold)).frame(width: 62, alignment: .trailing)
                }
                .toggleStyle(.switch)
            }
            HStack(spacing: 10) {
                StatusPill(title: "RAW 8", isSelected: model.mode == .raw8)
                StatusPill(title: "RAW 9", isSelected: model.mode == .raw9)
                Spacer()
                Picker("", selection: $model.exportFormat) { ForEach(ExportFormat.allCases) { Text($0.rawValue).tag($0) } }
                    .pickerStyle(.menu).frame(width: 112).disabled(model.selectedFile == nil || !model.support.decoder)
                Button("Reset") { model.resetToDefaults() }.disabled(model.selectedFile == nil || !model.support.decoder)
                Button("Export") { model.exportSelectedFile() }.buttonStyle(.borderedProminent).disabled(model.selectedFile == nil || !model.support.decoder)
            }
        }
        .padding(18)
    }

    private var settingsControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Available means Core Image accepts the setting for this file and decoder. It does not guarantee a visible pixel difference.").font(.caption).foregroundStyle(.secondary)
            SectionTitle("Decoder Settings")
            ToggleRow("Draft mode", isOn: $model.settings.draftModeEnabled, isEnabled: model.support.decoder)
            FloatRow("Scale factor", value: $model.settings.scaleFactor, range: 0.1...1, step: 0.05, isEnabled: model.support.decoder)
            SectionTitle("Tone")
            FloatRow("Exposure", value: $model.settings.exposure, range: -5...5, step: 0.05, isEnabled: model.support.decoder)
            FloatRow("Baseline exposure", value: $model.settings.baselineExposure, range: -5...5, step: 0.05, isEnabled: model.support.decoder)
            FloatRow("Shadow bias", value: $model.settings.shadowBias, range: -2...2, step: 0.05, isEnabled: model.support.decoder)
            FloatRow("Boost", value: $model.settings.boostAmount, range: 0...1, step: 0.01, isEnabled: model.support.decoder)
            FloatRow("Boost shadows", value: $model.settings.boostShadowAmount, range: 0...2, step: 0.01, isEnabled: model.support.decoder)
            ToggleRow("Highlight recovery", isOn: $model.settings.highlightRecoveryEnabled, isEnabled: model.support.decoder && model.support.highlightRecovery)
            ToggleRow("Gamut mapping", isOn: $model.settings.gamutMappingEnabled, isEnabled: model.support.decoder)
            FloatRow("Extended dynamic range", value: $model.settings.extendedDynamicRangeAmount, range: 0...2, step: 0.05, isEnabled: model.support.decoder)
            SectionTitle("Detail and Noise")
            ToggleRow("Lens correction", isOn: $model.settings.lensCorrectionEnabled, isEnabled: model.support.decoder && model.support.lensCorrection)
            FloatRow("Luminance noise reduction", value: $model.settings.luminanceNoiseReductionAmount, range: 0...1, step: 0.01, isEnabled: model.support.decoder && model.support.luminanceNoiseReduction)
            FloatRow("Color noise reduction", value: $model.settings.colorNoiseReductionAmount, range: 0...1, step: 0.01, isEnabled: model.support.decoder && model.support.colorNoiseReduction)
            FloatRow("Sharpness", value: $model.settings.sharpnessAmount, range: 0...1, step: 0.01, isEnabled: model.support.decoder && model.support.sharpness)
            FloatRow("Local contrast", value: $model.settings.contrastAmount, range: 0...1, step: 0.01, isEnabled: model.support.decoder && model.support.contrast)
            FloatRow("Detail", value: $model.settings.detailAmount, range: 0...3, step: 0.05, isEnabled: model.support.decoder && model.support.detail)
            FloatRow("Moire reduction", value: $model.settings.moireReductionAmount, range: 0...1, step: 0.01, isEnabled: model.support.decoder && model.support.moireReduction)
            FloatRow("Despeckle", value: $model.settings.despeckleAmount, range: 0...1, step: 0.01, isEnabled: model.support.decoder && model.support.despeckle)
            FloatRow("Local tone map", value: $model.settings.localToneMapAmount, range: 0...1, step: 0.01, isEnabled: model.support.decoder && model.support.localToneMap)
            SectionTitle("White Balance")
            FloatRow("Temperature", value: $model.settings.neutralTemperature, range: 2000...50000, step: 50, isEnabled: model.support.decoder, decimals: 0)
            FloatRow("Tint", value: $model.settings.neutralTint, range: -150...150, step: 1, isEnabled: model.support.decoder, decimals: 0)
        }
    }
}

struct Raw9WarningView: View {
    let switchToRaw8: () -> Void
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill").font(.title3).foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 3) {
                Text("RAW 9 is not available for this camera or file.").font(.callout.weight(.semibold))
                Text("The current RAW cannot be processed with the RAW 9 decoder on this system.").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button("Use RAW 8", action: switchToRaw8)
        }
        .padding(.horizontal, 18).padding(.vertical, 12).background(Color.orange.opacity(0.10))
    }
}

struct StatusPill: View {
    let title: String
    let isSelected: Bool
    var body: some View {
        Text(title).font(.caption.weight(.semibold)).padding(.horizontal, 8).padding(.vertical, 4)
            .background(isSelected ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.12))
            .foregroundStyle(isSelected ? Color.accentColor : Color.secondary).clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

struct SectionTitle: View {
    let title: String
    init(_ title: String) { self.title = title }
    var body: some View { Text(title).font(.headline).padding(.top, 6) }
}

struct ToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    let isEnabled: Bool
    init(_ title: String, isOn: Binding<Bool>, isEnabled: Bool) { self.title = title; self._isOn = isOn; self.isEnabled = isEnabled }
    var body: some View {
        HStack(spacing: 12) {
            Text(title)
            Spacer()
            AdjustmentStateBadge(isApplied: isEnabled)
            Toggle("", isOn: $isOn).labelsHidden().disabled(!isEnabled)
        }
        .opacity(isEnabled ? 1 : 0.42)
    }
}

struct FloatRow: View {
    let title: String
    @Binding var value: Float
    let range: ClosedRange<Float>
    let step: Float
    let isEnabled: Bool
    let decimals: Int

    init(_ title: String, value: Binding<Float>, range: ClosedRange<Float>, step: Float, isEnabled: Bool, decimals: Int = 2) {
        self.title = title; self._value = value; self.range = range; self.step = step; self.isEnabled = isEnabled; self.decimals = decimals
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(title).frame(minWidth: 170, alignment: .leading)
            Slider(value: Binding(get: { Double(value) }, set: { value = min(max(Float($0), range.lowerBound), range.upperBound) }), in: Double(range.lowerBound)...Double(range.upperBound), step: Double(step)).disabled(!isEnabled)
            AdjustmentStateBadge(isApplied: isEnabled)
            TextField("", value: Binding(get: { Double(value) }, set: { value = min(max(Float($0), range.lowerBound), range.upperBound) }), formatter: numberFormatter)
                .textFieldStyle(.roundedBorder).font(.system(.body, design: .monospaced)).multilineTextAlignment(.trailing).frame(width: 82).disabled(!isEnabled)
        }
        .opacity(isEnabled ? 1 : 0.42)
    }

    private var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = decimals
        formatter.maximumFractionDigits = decimals
        formatter.minimum = NSNumber(value: range.lowerBound)
        formatter.maximum = NSNumber(value: range.upperBound)
        formatter.allowsFloats = decimals > 0
        formatter.usesGroupingSeparator = false
        return formatter
    }
}

struct AdjustmentStateBadge: View {
    let isApplied: Bool
    var body: some View {
        Text(isApplied ? "Available" : "Unavailable").font(.caption2.weight(.semibold))
            .foregroundStyle(isApplied ? Color.green : Color.secondary).frame(width: 72, alignment: .trailing)
            .help(isApplied ? "Core Image reports that this setting is available in the selected decoder pipeline." : "Core Image reports that this setting is unavailable in the selected decoder pipeline.")
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        let iconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns") ?? Bundle.main.url(forResource: "AppIcon", withExtension: "png")
        if let iconURL, let icon = NSImage(contentsOf: iconURL) { NSApplication.shared.applicationIconImage = icon }
    }
}

@main
struct RawOptionsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    var body: some Scene {
        WindowGroup("Apple RAW 9 Tester") { ContentView() }.windowStyle(.titleBar)
    }
}
