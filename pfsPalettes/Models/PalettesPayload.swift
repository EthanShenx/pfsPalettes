import Foundation

struct PalettesPayload: Codable {
    var version: Int
    var palettes: [Palette]

    init(version: Int = 1, palettes: [Palette]) {
        self.version = version
        self.palettes = palettes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1
        palettes = try container.decode([Palette].self, forKey: .palettes)
    }
}
