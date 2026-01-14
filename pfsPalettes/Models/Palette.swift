import Foundation

struct Palette: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var colors: [PaletteColor]
    var isFavorite: Bool
    var isSystemManaged: Bool  // For auto-generated palettes like "Starred Colors"

    init(id: UUID = UUID(), name: String, colors: [PaletteColor], isFavorite: Bool = false, isSystemManaged: Bool = false) {
        self.id = id
        self.name = name
        self.colors = colors
        self.isFavorite = isFavorite
        self.isSystemManaged = isSystemManaged
    }
}

extension Palette {
    static var starter: Palette {
        Palette(
            name: "Starter Palette",
            colors: [
                PaletteColor(hex: "#F5F5F7", name: "Pearl"),
                PaletteColor(hex: "#C3D0DB", name: "Fog"),
                PaletteColor(hex: "#7FA3B8", name: "Sky"),
                PaletteColor(hex: "#436A86", name: "Slate"),
                PaletteColor(hex: "#1F2D3A", name: "Ink")
            ]
        )
    }
}
