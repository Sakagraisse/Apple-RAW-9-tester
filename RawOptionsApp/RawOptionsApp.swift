import AppKit
import CoreImage
import SwiftUI
import UniformTypeIdentifiers

enum RawMode: String, CaseIterable, Identifiable {
    case raw8 = "RAW 8"
    case raw9 = "RAW 9"

    var id: String { rawValue }
}

struct RawFile: Identifiable, Hashable {
    let id = UUID()
    let url: URL

    var name: String { url.lastPathComponent }
    var detail: String { url.deletingLastPathComponent().path }
    var isDNG: Bool { url.pathExtension.lowercased() == "dng" }
}

struct RawOption: Identifiable {
    enum Value {
        case float(Float)
        case bool(Bool)
        case point(CGPoint)
        case text(String)
        case unavailable

        var display: String {
            switch self {
            case .float(let value):
                if abs(value) >= 100 {
                    return String(format: "%.0f", value)
                }
                return String(format: "%.3f", value)
            case .bool(let value):
                return value ? "Oui" : "Non"
            case .point(let value):
                return String(format: "%.4f, %.4f", value.x, value.y)
            case .text(let value):
                return value
            case .unavailable:
                return "Indisponible"
            }
        }
    }

    let id: String
    let name: String
    let note: String
    let value: Value
    let isFunctional: Bool
}

final class RawOptionsModel: ObservableObject {
    @Published var files: [RawFile] = []
    @Published var selectedFileID: RawFile.ID?
    @Published var mode: RawMode = .raw8
    @Published var isDropTargeted = false
    @Published var options: [RawOption] = []
    @Published var statusText = "Dépose des fichiers RAW ou DNG"
    @Published var metadataText = ""

    private let rawExtensions: Set<String> = [
        "3fr", "arw", "cr2", "cr3", "dng", "erf", "fff", "iiq", "kdc",
        "mos", "mrw", "nef", "nrw", "orf", "pef", "raf", "raw", "rw2", "srw"
    ]

    var selectedFile: RawFile? {
        files.first { $0.id == selectedFileID }
    }

    var shouldShowDefaults: Bool {
        files.count == 1
    }

    func addDroppedProviders(_ providers: [NSItemProvider]) -> Bool {
        var accepted = false
        for provider in providers where provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            accepted = true
            provider.loadObject(ofClass: NSURL.self) { [weak self] item, _ in
                guard let url = item as? URL else { return }
                DispatchQueue.main.async {
                    self?.addURL(url)
                }
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
        selectedFileID = files.first?.id
        refreshOptions()
    }

    func clearFiles() {
        files = []
        selectedFileID = nil
        refreshOptions()
    }

    func refreshOptions() {
        guard let file = selectedFile else {
            options = []
            statusText = "Dépose des fichiers RAW ou DNG"
            metadataText = ""
            return
        }

        guard let filter = CIRAWFilter(imageURL: file.url) else {
            options = []
            statusText = "Core Image ne peut pas ouvrir ce fichier RAW."
            metadataText = file.name
            return
        }

        let decoder = decoderVersion(for: file, mode: mode)
        let supportedVersions = filter.supportedDecoderVersions
        metadataText = metadataSummary(for: filter, file: file)

        guard supportedVersions.contains(decoder) else {
            options = unavailableOptions()
            let versions = supportedVersions.map(\.rawValue).joined(separator: ", ")
            statusText = "\(mode.rawValue) indisponible pour \(file.name). Versions: \(versions)"
            return
        }

        filter.decoderVersion = decoder
        options = buildOptions(from: filter)
        statusText = shouldShowDefaults
            ? "Valeurs par défaut détectées pour \(mode.rawValue)"
            : "\(files.count) fichiers importés. Sélectionne un fichier pour inspecter ses valeurs."
    }

    private func addURL(_ url: URL) {
        let standardized = url.standardizedFileURL
        guard rawExtensions.contains(standardized.pathExtension.lowercased()) else {
            statusText = "Format ignoré: \(standardized.lastPathComponent)"
            return
        }
        guard !files.contains(where: { $0.url == standardized }) else {
            return
        }

        let file = RawFile(url: standardized)
        files.append(file)
        files.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        if selectedFileID == nil || files.count == 1 {
            selectedFileID = file.id
        }
        refreshOptions()
    }

    private func decoderVersion(for file: RawFile, mode: RawMode) -> CIRAWDecoderVersion {
        switch (mode, file.isDNG) {
        case (.raw8, true):
            return .version8DNG
        case (.raw8, false):
            return .version8
        case (.raw9, true):
            return .version9DNG
        case (.raw9, false):
            return .version9
        }
    }

    private func metadataSummary(for filter: CIRAWFilter, file: RawFile) -> String {
        let tiff = filter.properties[kCGImagePropertyTIFFDictionary as String] as? [String: Any]
        let model = tiff?[kCGImagePropertyTIFFModel as String] as? String ?? "Modèle inconnu"
        let width = Int(filter.nativeSize.width)
        let height = Int(filter.nativeSize.height)
        return "\(file.name) · \(model) · \(width) x \(height)"
    }

    private func buildOptions(from filter: CIRAWFilter) -> [RawOption] {
        [
            RawOption(id: "decoderVersion", name: "Décodeur", note: "Version Core Image utilisée", value: .text(filter.decoderVersion.rawValue), isFunctional: true),
            RawOption(id: "scaleFactor", name: "Échelle", note: "0 à 1", value: .float(filter.scaleFactor), isFunctional: true),
            RawOption(id: "draftMode", name: "Mode brouillon", note: "Décodage plus rapide", value: .bool(filter.isDraftModeEnabled), isFunctional: true),
            RawOption(id: "exposure", name: "Exposition", note: "EV appliqué au RAW", value: .float(filter.exposure), isFunctional: true),
            RawOption(id: "baselineExposure", name: "Baseline exposure", note: "Défaut dépendant du fichier", value: .float(filter.baselineExposure), isFunctional: true),
            RawOption(id: "shadowBias", name: "Shadow bias", note: "Correction des ombres", value: .float(filter.shadowBias), isFunctional: true),
            RawOption(id: "boostAmount", name: "Boost", note: "Courbe globale 0 à 1", value: .float(filter.boostAmount), isFunctional: true),
            RawOption(id: "boostShadowAmount", name: "Boost ombres", note: "Ombres 0 à 2", value: .float(filter.boostShadowAmount), isFunctional: true),
            RawOption(id: "highlightRecovery", name: "Récupération hautes lumières", note: "Selon fichier et décodeur", value: .bool(filter.isHighlightRecoveryEnabled), isFunctional: filter.isHighlightRecoverySupported),
            RawOption(id: "gamutMapping", name: "Gamut mapping", note: "Conversion des couleurs", value: .bool(filter.isGamutMappingEnabled), isFunctional: true),
            RawOption(id: "lensCorrection", name: "Correction optique", note: "Selon métadonnées objectif", value: .bool(filter.isLensCorrectionEnabled), isFunctional: filter.isLensCorrectionSupported),
            RawOption(id: "luminanceNR", name: "Réduction bruit luminance", note: "0 à 1", value: .float(filter.luminanceNoiseReductionAmount), isFunctional: filter.isLuminanceNoiseReductionSupported),
            RawOption(id: "colorNR", name: "Réduction bruit couleur", note: "0 à 1", value: .float(filter.colorNoiseReductionAmount), isFunctional: filter.isColorNoiseReductionSupported),
            RawOption(id: "sharpness", name: "Netteté", note: "0 à 1", value: .float(filter.sharpnessAmount), isFunctional: filter.isSharpnessSupported),
            RawOption(id: "contrast", name: "Contraste local", note: "0 à 1", value: .float(filter.contrastAmount), isFunctional: filter.isContrastSupported),
            RawOption(id: "detail", name: "Détail", note: "0 à 3", value: .float(filter.detailAmount), isFunctional: filter.isDetailSupported),
            RawOption(id: "moire", name: "Réduction moiré", note: "0 à 1", value: .float(filter.moireReductionAmount), isFunctional: filter.isMoireReductionSupported),
            RawOption(id: "despeckle", name: "Despeckle", note: "0 à 1", value: .float(filter.despeckleAmount), isFunctional: filter.isDespeckleSupported),
            RawOption(id: "localToneMap", name: "Local tone map", note: "0 à 1", value: .float(filter.localToneMapAmount), isFunctional: filter.isLocalToneMapSupported),
            RawOption(id: "edr", name: "Extended Dynamic Range", note: "0 à 2", value: .float(filter.extendedDynamicRangeAmount), isFunctional: true),
            RawOption(id: "neutralChromaticity", name: "Chromaticité neutre", note: "x, y", value: .point(filter.neutralChromaticity), isFunctional: true),
            RawOption(id: "neutralTemperature", name: "Température", note: "Kelvin", value: .float(filter.neutralTemperature), isFunctional: true),
            RawOption(id: "neutralTint", name: "Teinte", note: "-150 à 150", value: .float(filter.neutralTint), isFunctional: true)
        ]
    }

    private func unavailableOptions() -> [RawOption] {
        buildOptionNames().map {
            RawOption(id: $0.id, name: $0.name, note: $0.note, value: .unavailable, isFunctional: false)
        }
    }

    private func buildOptionNames() -> [(id: String, name: String, note: String)] {
        [
            ("decoderVersion", "Décodeur", "Version Core Image utilisée"),
            ("scaleFactor", "Échelle", "0 à 1"),
            ("draftMode", "Mode brouillon", "Décodage plus rapide"),
            ("exposure", "Exposition", "EV appliqué au RAW"),
            ("baselineExposure", "Baseline exposure", "Défaut dépendant du fichier"),
            ("shadowBias", "Shadow bias", "Correction des ombres"),
            ("boostAmount", "Boost", "Courbe globale 0 à 1"),
            ("boostShadowAmount", "Boost ombres", "Ombres 0 à 2"),
            ("highlightRecovery", "Récupération hautes lumières", "Selon fichier et décodeur"),
            ("gamutMapping", "Gamut mapping", "Conversion des couleurs"),
            ("lensCorrection", "Correction optique", "Selon métadonnées objectif"),
            ("luminanceNR", "Réduction bruit luminance", "0 à 1"),
            ("colorNR", "Réduction bruit couleur", "0 à 1"),
            ("sharpness", "Netteté", "0 à 1"),
            ("contrast", "Contraste local", "0 à 1"),
            ("detail", "Détail", "0 à 3"),
            ("moire", "Réduction moiré", "0 à 1"),
            ("despeckle", "Despeckle", "0 à 1"),
            ("localToneMap", "Local tone map", "0 à 1"),
            ("edr", "Extended Dynamic Range", "0 à 2"),
            ("neutralChromaticity", "Chromaticité neutre", "x, y"),
            ("neutralTemperature", "Température", "Kelvin"),
            ("neutralTint", "Teinte", "-150 à 150")
        ]
    }
}

struct ContentView: View {
    @StateObject private var model = RawOptionsModel()

    var body: some View {
        HStack(spacing: 0) {
            DropPane(model: model)
                .frame(minWidth: 320, idealWidth: 380, maxWidth: 460)
                .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            OptionsPane(model: model)
                .frame(minWidth: 520, maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(nsColor: .controlBackgroundColor))
        }
        .frame(minWidth: 900, minHeight: 560)
        .onChange(of: model.mode) { _, _ in model.refreshOptions() }
        .onChange(of: model.selectedFileID) { _, _ in model.refreshOptions() }
    }
}

struct DropPane: View {
    @ObservedObject var model: RawOptionsModel

    var body: some View {
        VStack(spacing: 14) {
            dropZone

            if model.files.isEmpty {
                Text("Aucun fichier importé")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(selection: $model.selectedFileID) {
                    ForEach(model.files) { file in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(file.name)
                                .font(.system(.body, design: .rounded))
                                .lineLimit(1)
                            Text(file.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        .padding(.vertical, 4)
                        .tag(file.id)
                    }
                }
                .listStyle(.sidebar)
            }

            HStack {
                Button("Ajouter") { model.chooseFiles() }
                Button("Retirer") { model.removeSelectedFile() }
                    .disabled(model.selectedFile == nil)
                Spacer()
                Button("Vider") { model.clearFiles() }
                    .disabled(model.files.isEmpty)
            }
            .padding([.horizontal, .bottom], 16)
        }
    }

    private var dropZone: some View {
        VStack(spacing: 10) {
            Image(systemName: "photo.badge.plus")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(model.isDropTargeted ? Color.accentColor : Color.secondary)
            Text("Glisse les RAW / DNG ici")
                .font(.headline)
            Text("Un ou plusieurs fichiers")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 150)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(model.isDropTargeted ? Color.accentColor.opacity(0.14) : Color(nsColor: .textBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(model.isDropTargeted ? Color.accentColor : Color.secondary.opacity(0.28), style: StrokeStyle(lineWidth: 1.5, dash: [7, 5]))
        )
        .padding(16)
        .onDrop(of: [UTType.fileURL.identifier], isTargeted: $model.isDropTargeted) { providers in
            model.addDroppedProviders(providers)
        }
    }
}

struct OptionsPane: View {
    @ObservedObject var model: RawOptionsModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            if model.options.isEmpty {
                ContentUnavailableView("Aucun RAW sélectionné", systemImage: "slider.horizontal.3", description: Text("Dépose un fichier à gauche pour lire les paramètres par défaut."))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(model.options) { option in
                    OptionRow(option: option, showValue: model.shouldShowDefaults)
                }
                .listStyle(.plain)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.statusText)
                        .font(.headline)
                    if !model.metadataText.isEmpty {
                        Text(model.metadataText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Toggle(isOn: Binding(
                    get: { model.mode == .raw9 },
                    set: { model.mode = $0 ? .raw9 : .raw8 }
                )) {
                    Text(model.mode.rawValue)
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .frame(width: 62, alignment: .trailing)
                }
                .toggleStyle(.switch)
            }

            HStack(spacing: 8) {
                ModeBadge(title: "RAW 8", isSelected: model.mode == .raw8)
                ModeBadge(title: "RAW 9", isSelected: model.mode == .raw9)
                Spacer()
                Text(model.shouldShowDefaults ? "Défauts du fichier" : "Valeurs affichées pour le fichier sélectionné")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
    }
}

struct ModeBadge: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isSelected ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.12))
            .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

struct OptionRow: View {
    let option: RawOption
    let showValue: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(option.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(option.isFunctional ? .primary : .secondary)
                Text(option.note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 12)

            Text(showValue || !option.isFunctional ? option.value.display : "Sélection")
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(option.isFunctional ? .primary : .secondary)
                .frame(minWidth: 118, alignment: .trailing)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .opacity(option.isFunctional ? 1 : 0.42)
    }
}

@main
struct RawOptionsApp: App {
    var body: some Scene {
        WindowGroup("RAW Options") {
            ContentView()
        }
        .windowStyle(.titleBar)
    }
}
