import AppKit
import SwiftUI

struct PaletteColor: Identifiable, Codable, Hashable {
    var id: UUID
    var hex: String
    var name: String?

    init(id: UUID = UUID(), hex: String, name: String? = nil) {
        self.id = id
        self.hex = hex
        self.name = name
    }

    var normalizedHex: String {
        ColorUtils.normalizeHex(hex) ?? hex
    }

    var nsColor: NSColor? {
        ColorUtils.nsColor(from: normalizedHex)
    }

    var luminance: Double {
        ColorUtils.luminance(for: nsColor)
    }

    var hsb: (hue: Double, saturation: Double, brightness: Double) {
        ColorUtils.hsb(for: nsColor)
    }

    var tooltipText: String {
        if let name, !name.isEmpty {
            return "\(normalizedHex) • \(name)"
        }
        return normalizedHex
    }
}
