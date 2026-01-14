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

    // Custom decoder for backwards compatibility with old saved data
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        colors = try container.decode([PaletteColor].self, forKey: .colors)
        // Provide defaults for new properties that may not exist in old data
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        isSystemManaged = try container.decodeIfPresent(Bool.self, forKey: .isSystemManaged) ?? false
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, colors, isFavorite, isSystemManaged
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
