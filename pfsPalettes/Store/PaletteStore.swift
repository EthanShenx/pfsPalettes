import AppKit
import SwiftUI
import UniformTypeIdentifiers

enum ColorSortMode: String, CaseIterable {
    case brightness = "brightness"
    case hue = "hue"

    var label: String {
        switch self {
        case .brightness: return "Brightness"
        case .hue: return "Hue"
        }
    }

    var iconName: String {
        switch self {
        case .brightness: return "circle.lefthalf.filled"
        case .hue: return "circle.hexagongrid"
        }
    }
}

final class PaletteStore: ObservableObject {
    @Published var palettes: [Palette] {
        didSet {
            persistPalettes()
        }
    }

    @Published var selectedPaletteID: UUID {
        didSet {
            persistSelection()
        }
    }

    @Published var wantsAddFieldFocus = false

    @AppStorage("windowBackgroundOpacity") var windowBackgroundOpacity: Double = 0.92
    @AppStorage("isCollapsed") var isCollapsed: Bool = false
    @AppStorage("colorSortMode") private var sortModeRaw: String = ColorSortMode.brightness.rawValue

    var sortMode: ColorSortMode {
        get { ColorSortMode(rawValue: sortModeRaw) ?? .brightness }
        set { sortModeRaw = newValue.rawValue }
    }

    private let palettesKey = "pfsPalettes.palettes"
    private let selectedPaletteKey = "pfsPalettes.selectedPaletteID"

    init() {
        let initialPalettes: [Palette]
        if let data = UserDefaults.standard.data(forKey: palettesKey),
           let saved = try? JSONDecoder().decode([Palette].self, from: data),
           !saved.isEmpty {
            initialPalettes = saved
        } else {
            initialPalettes = [Palette.starter]
        }

        let initialSelectedID: UUID
        if let storedID = UserDefaults.standard.string(forKey: selectedPaletteKey),
           let uuid = UUID(uuidString: storedID),
           initialPalettes.contains(where: { $0.id == uuid }) {
            initialSelectedID = uuid
        } else {
            initialSelectedID = initialPalettes.first?.id ?? UUID()
        }

        palettes = initialPalettes
        selectedPaletteID = initialSelectedID
    }

    var selectedPalette: Palette? {
        palettes.first(where: { $0.id == selectedPaletteID })
    }

    func focusAddField() {
        wantsAddFieldFocus = true
    }

    func sortedColors(_ colors: [PaletteColor]) -> [PaletteColor] {
        switch sortMode {
        case .brightness:
            return colors.sorted { $0.luminance > $1.luminance }
        case .hue:
            // Sort by hue, then by saturation (grays at the end), then by brightness
            return colors.sorted { c1, c2 in
                let hsb1 = c1.hsb
                let hsb2 = c2.hsb
                // Put low-saturation colors (grays) at the end
                let isGray1 = hsb1.saturation < 0.1
                let isGray2 = hsb2.saturation < 0.1
                if isGray1 != isGray2 {
                    return isGray2 // non-grays first
                }
                if isGray1 && isGray2 {
                    // Sort grays by brightness (light to dark)
                    return hsb1.brightness > hsb2.brightness
                }
                // Sort by hue first
                if abs(hsb1.hue - hsb2.hue) > 5 {
                    return hsb1.hue < hsb2.hue
                }
                // Within same hue family, sort by brightness
                return hsb1.brightness > hsb2.brightness
            }
        }
    }

    func toggleSortMode() {
        sortMode = sortMode == .brightness ? .hue : .brightness
    }

    /// Intelligently samples colors from a palette to get a balanced subset.
    /// Uses a k-means-like approach in HSB color space to select well-distributed colors.
    func sampleColors(count targetCount: Int) -> [PaletteColor] {
        guard let palette = selectedPalette else { return [] }
        let colors = palette.colors
        guard targetCount > 0, targetCount < colors.count else { return colors }

        // Convert colors to HSB space for better perceptual distribution
        struct ColorPoint {
            let color: PaletteColor
            let h: Double  // 0-360
            let s: Double  // 0-1
            let b: Double  // 0-1

            // Distance in cylindrical HSB space
            func distance(to other: ColorPoint) -> Double {
                // Convert hue to radians for circular distance
                let h1 = h * .pi / 180
                let h2 = other.h * .pi / 180
                // Use cylindrical coordinates: x = s*cos(h), y = s*sin(h), z = b
                let x1 = s * cos(h1), y1 = s * sin(h1)
                let x2 = other.s * cos(h2), y2 = other.s * sin(h2)
                let dx = x1 - x2, dy = y1 - y2, dz = b - other.b
                return sqrt(dx*dx + dy*dy + dz*dz)
            }
        }

        let points = colors.map { color -> ColorPoint in
            let hsb = color.hsb
            return ColorPoint(color: color, h: hsb.hue, s: hsb.saturation, b: hsb.brightness)
        }

        // Greedy selection: start with most saturated or brightest color,
        // then repeatedly select the color furthest from all selected colors
        var selected: [ColorPoint] = []
        var remaining = points

        // Start with the most vibrant color (high saturation + mid brightness)
        if let startIdx = remaining.indices.max(by: {
            let score1 = remaining[$0].s * (1 - abs(remaining[$0].b - 0.5))
            let score2 = remaining[$1].s * (1 - abs(remaining[$1].b - 0.5))
            return score1 < score2
        }) {
            selected.append(remaining.remove(at: startIdx))
        }

        // Greedily select remaining colors
        while selected.count < targetCount && !remaining.isEmpty {
            // Find the color with maximum minimum distance to selected colors
            var bestIdx = 0
            var bestMinDist = -Double.infinity

            for (idx, candidate) in remaining.enumerated() {
                let minDist = selected.map { candidate.distance(to: $0) }.min() ?? 0
                if minDist > bestMinDist {
                    bestMinDist = minDist
                    bestIdx = idx
                }
            }

            selected.append(remaining.remove(at: bestIdx))
        }

        // Return in hue order for visual consistency
        return selected
            .sorted { $0.h < $1.h }
            .map { $0.color }
    }

    /// Creates a new palette with sampled colors from the current palette.
    func createSampledPalette(count: Int) {
        let sampled = sampleColors(count: count)
        guard !sampled.isEmpty else { return }
        let baseName = selectedPalette?.name ?? "Palette"
        addPalette(name: "\(baseName) (\(count) colors)", colors: sampled)
    }

    func addPalette(name: String, colors: [PaletteColor] = []) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let paletteName = uniquePaletteName(trimmed.isEmpty ? "Untitled Palette" : trimmed)
        let palette = Palette(name: paletteName, colors: sanitizedColors(colors))
        palettes.append(palette)
        selectedPaletteID = palette.id
    }

    func renameSelectedPalette(to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        updateSelectedPalette { palette in
            palette.name = uniquePaletteName(trimmed, excluding: palette.id)
        }
    }

    func deleteSelectedPalette() {
        guard palettes.count > 1 else { return }
        guard let index = palettes.firstIndex(where: { $0.id == selectedPaletteID }) else { return }
        palettes.remove(at: index)
        selectedPaletteID = palettes[min(index, palettes.count - 1)].id
    }

    func addColors(fromText text: String) {
        let matches = extractHexColors(from: text)
        guard !matches.isEmpty else { return }
        for hex in matches {
            addColor(hex: hex)
        }
    }

    func addColor(hex: String) {
        guard let normalized = ColorUtils.normalizeHex(hex) else { return }
        updateSelectedPalette { palette in
            guard !palette.colors.contains(where: { $0.normalizedHex == normalized }) else { return }
            palette.colors.append(PaletteColor(hex: normalized))
        }
    }

    func addColor(from color: NSColor) {
        let hex = ColorUtils.hexString(from: color)
        addColor(hex: hex)
    }

    func updateColor(_ color: PaletteColor, newHex: String, newName: String?) {
        guard let normalized = ColorUtils.normalizeHex(newHex) else { return }
        let trimmedName = newName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedName = (trimmedName?.isEmpty ?? true) ? nil : trimmedName
        updateSelectedPalette { palette in
            guard let index = palette.colors.firstIndex(where: { $0.id == color.id }) else { return }
            palette.colors[index].hex = normalized
            palette.colors[index].name = normalizedName
        }
    }

    func removeColor(_ color: PaletteColor) {
        updateSelectedPalette { palette in
            palette.colors.removeAll { $0.id == color.id }
        }
    }

    func handleDrop(providers: [NSItemProvider]) -> Bool {
        var handled = false
        for provider in providers {
            if loadColor(from: provider) {
                handled = true
            } else if provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { data, _ in
                    if let text = data as? String {
                        DispatchQueue.main.async {
                            self.addColors(fromText: text)
                        }
                    } else if let data = data as? Data, let text = String(data: data, encoding: .utf8) {
                        DispatchQueue.main.async {
                            self.addColors(fromText: text)
                        }
                    }
                }
                handled = true
            }
        }
        return handled
    }

    private func loadColor(from provider: NSItemProvider) -> Bool {
        for identifier in UTType.pfsColorTypeIdentifiers {
            guard provider.hasItemConformingToTypeIdentifier(identifier) else { continue }
            provider.loadItem(forTypeIdentifier: identifier, options: nil) { item, _ in
                let color: NSColor?
                if let data = item as? Data {
                    color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: data)
                } else if let data = item as? NSData {
                    color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: data as Data)
                } else {
                    color = item as? NSColor
                }
                guard let color else { return }
                DispatchQueue.main.async {
                    self.addColor(from: color)
                }
            }
            return true
        }
        return false
    }


    func exportPayload() -> PalettesPayload {
        PalettesPayload(palettes: palettes)
    }

    func importFromURL(_ url: URL) throws -> String {
        if url.pathExtension.lowercased() == "clr" {
            try importColorList(from: url)
            return "Imported color list."
        }

        let data = try Data(contentsOf: url)
        let payload = try JSONDecoder().decode(PalettesPayload.self, from: data)
        importPalettes(payload.palettes)
        return "Imported \(payload.palettes.count) palette(s)."
    }

    func exportCurrentPaletteAsCLR() {
        guard let palette = selectedPalette else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType.colorList]
        panel.nameFieldStringValue = "\(palette.name).clr"
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            let colorList = NSColorList(name: palette.name)
            for color in palette.colors {
                guard let nsColor = color.nsColor else { continue }
                colorList.setColor(nsColor, forKey: color.name ?? color.normalizedHex)
            }
            do {
                try colorList.write(to: url)
            } catch {
                NSLog("Failed to export .clr: %@", error.localizedDescription)
            }
        }
    }

    private func importPalettes(_ newPalettes: [Palette]) {
        var merged = palettes
        var existingNames = Set(palettes.map { $0.name.lowercased() })
        for palette in newPalettes {
            let renamed = uniquePaletteName(palette.name, existingNames: existingNames)
            existingNames.insert(renamed.lowercased())
            var copy = palette
            copy.id = UUID()
            copy.name = renamed
            copy.colors = sanitizedColors(palette.colors)
            merged.append(copy)
        }
        palettes = merged
        if let last = merged.last {
            selectedPaletteID = last.id
        }
    }

    private func importColorList(from url: URL) throws {
        let baseName = url.deletingPathExtension().lastPathComponent
        guard let colorList = NSColorList(name: baseName, fromFile: url.path) else {
            throw PaletteImportError.invalidColorList
        }

        let listName = colorList.name ?? baseName
        let paletteName = listName.isEmpty ? baseName : listName
        var colors: [PaletteColor] = []
        for key in colorList.allKeys {
            if let color = colorList.color(withKey: key) {
                let hex = ColorUtils.hexString(from: color)
                colors.append(PaletteColor(hex: hex, name: key))
            }
        }

        addPalette(name: paletteName, colors: colors)
    }

    private func updateSelectedPalette(_ update: (inout Palette) -> Void) {
        guard let index = palettes.firstIndex(where: { $0.id == selectedPaletteID }) else { return }
        var palette = palettes[index]
        update(&palette)
        palettes[index] = palette
    }

    private func uniquePaletteName(_ name: String, excluding excludedID: UUID? = nil) -> String {
        let existingNames = Set(
            palettes
                .filter { $0.id != excludedID }
                .map { $0.name.lowercased() }
        )
        return uniquePaletteName(name, existingNames: existingNames)
    }

    private func uniquePaletteName(_ name: String, existingNames: Set<String>) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = trimmed.isEmpty ? "Untitled Palette" : trimmed
        var candidate = base
        var counter = 2

        while existingNames.contains(candidate.lowercased()) {
            candidate = "\(base) \(counter)"
            counter += 1
        }
        return candidate
    }

    private func sanitizedColors(_ colors: [PaletteColor]) -> [PaletteColor] {
        var seen = Set<String>()
        var result: [PaletteColor] = []

        for color in colors {
            guard let normalized = ColorUtils.normalizeHex(color.hex) else { continue }
            guard !seen.contains(normalized) else { continue }
            seen.insert(normalized)

            let trimmedName = color.name?.trimmingCharacters(in: .whitespacesAndNewlines)
            let normalizedName = (trimmedName?.isEmpty ?? true) ? nil : trimmedName
            result.append(PaletteColor(hex: normalized, name: normalizedName))
        }
        return result
    }

    private func extractHexColors(from text: String) -> [String] {
        // Allow pasting a blob of text and extracting multiple hex colors.
        let pattern = "#?[0-9A-Fa-f]{3}([0-9A-Fa-f]{3})?"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return [] }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.matches(in: text, options: [], range: range).compactMap { match in
            guard let range = Range(match.range, in: text) else { return nil }
            let candidate = String(text[range])
            return ColorUtils.normalizeHex(candidate)
        }
    }

    private func persistPalettes() {
        guard let data = try? JSONEncoder().encode(palettes) else { return }
        UserDefaults.standard.set(data, forKey: palettesKey)
    }

    private func persistSelection() {
        UserDefaults.standard.set(selectedPaletteID.uuidString, forKey: selectedPaletteKey)
    }
}

enum PaletteImportError: LocalizedError {
    case invalidColorList

    var errorDescription: String? {
        switch self {
        case .invalidColorList:
            return "The selected .clr file could not be read."
        }
    }
}

extension UTType {
    static var colorList: UTType {
        UTType(filenameExtension: "clr") ?? .data
    }

    static var pfsColor: UTType {
        UTType(importedAs: "com.apple.color")
    }

    static var pfsColorFallback: UTType {
        UTType(importedAs: "public.color")
    }

    static var pfsColorTypeIdentifiers: [String] {
        [pfsColor.identifier, pfsColorFallback.identifier]
    }

    static var pfsColorTypes: [UTType] {
        [pfsColor, pfsColorFallback]
    }
}
