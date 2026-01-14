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

    // MARK: - Built-in Palettes

    static var builtInPalettes: [Palette] {
        [
            natureGrey, natureStone, natureRed, natureBlue, natureYellow,
            natureOlive, natureGreen, natureTeal, naturePurple, natureOrange,
            natureSkinTones, fiveColorOption1, atlas1, atlas2, fourColorOption1,
            rColorBrewerPaired, twoColorOption1, twoColorOption2, twoColorOption3
        ]
    }

    static var natureGrey: Palette {
        Palette(name: "Nature-Grey", colors: [
            PaletteColor(hex: "#E5E5E9"),
            PaletteColor(hex: "#C5CAD7"),
            PaletteColor(hex: "#96A0B3"),
            PaletteColor(hex: "#6E788D"),
            PaletteColor(hex: "#435469"),
            PaletteColor(hex: "#1C2A43")
        ])
    }

    static var natureStone: Palette {
        Palette(name: "Nature-Stone", colors: [
            PaletteColor(hex: "#F7F2EF"),
            PaletteColor(hex: "#E1DCCA"),
            PaletteColor(hex: "#C6C1A5"),
            PaletteColor(hex: "#A5A083"),
            PaletteColor(hex: "#888365"),
            PaletteColor(hex: "#5E5948")
        ])
    }

    static var natureRed: Palette {
        Palette(name: "Nature-Red", colors: [
            PaletteColor(hex: "#F6CFCA"),
            PaletteColor(hex: "#EAA0A5"),
            PaletteColor(hex: "#DC6464"),
            PaletteColor(hex: "#C5373D"),
            PaletteColor(hex: "#9B251C"),
            PaletteColor(hex: "#730C0D")
        ])
    }

    static var natureBlue: Palette {
        Palette(name: "Nature-Blue", colors: [
            PaletteColor(hex: "#C5E5FB"),
            PaletteColor(hex: "#9BCAE9"),
            PaletteColor(hex: "#5497CE"),
            PaletteColor(hex: "#016FAE"),
            PaletteColor(hex: "#00488D"),
            PaletteColor(hex: "#002359")
        ])
    }

    static var natureYellow: Palette {
        Palette(name: "Nature-Yellow", colors: [
            PaletteColor(hex: "#FFEEC1"),
            PaletteColor(hex: "#F6DC87"),
            PaletteColor(hex: "#E9C64E"),
            PaletteColor(hex: "#CA9B24"),
            PaletteColor(hex: "#9B740A"),
            PaletteColor(hex: "#69540A")
        ])
    }

    static var natureOlive: Palette {
        Palette(name: "Nature-Olive", colors: [
            PaletteColor(hex: "#F3EEB4"),
            PaletteColor(hex: "#DCDC64"),
            PaletteColor(hex: "#C5C500"),
            PaletteColor(hex: "#96A008"),
            PaletteColor(hex: "#647314"),
            PaletteColor(hex: "#304415")
        ])
    }

    static var natureGreen: Palette {
        Palette(name: "Nature-Green", colors: [
            PaletteColor(hex: "#D7E5C5"),
            PaletteColor(hex: "#A1CA78"),
            PaletteColor(hex: "#5EB342"),
            PaletteColor(hex: "#429130"),
            PaletteColor(hex: "#1B6F2A"),
            PaletteColor(hex: "#0E3716")
        ])
    }

    static var natureTeal: Palette {
        Palette(name: "Nature-Teal", colors: [
            PaletteColor(hex: "#CAE5EE"),
            PaletteColor(hex: "#96CFD3"),
            PaletteColor(hex: "#49BCBC"),
            PaletteColor(hex: "#0096A0"),
            PaletteColor(hex: "#016579"),
            PaletteColor(hex: "#003648")
        ])
    }

    static var naturePurple: Palette {
        Palette(name: "Nature-Purple", colors: [
            PaletteColor(hex: "#EAD3E9"),
            PaletteColor(hex: "#D4A9CE"),
            PaletteColor(hex: "#B778B3"),
            PaletteColor(hex: "#A54991"),
            PaletteColor(hex: "#7A2473"),
            PaletteColor(hex: "#430B4E")
        ])
    }

    static var natureOrange: Palette {
        Palette(name: "Nature-Orange", colors: [
            PaletteColor(hex: "#FBDCBC"),
            PaletteColor(hex: "#FCBC7E"),
            PaletteColor(hex: "#F29743"),
            PaletteColor(hex: "#E96A00"),
            PaletteColor(hex: "#B34A00"),
            PaletteColor(hex: "#832A00")
        ])
    }

    static var natureSkinTones: Palette {
        Palette(name: "Nature-Skin Tones", colors: [
            PaletteColor(hex: "#F6E5D3"),
            PaletteColor(hex: "#DCBCA1"),
            PaletteColor(hex: "#BC9778"),
            PaletteColor(hex: "#916954"),
            PaletteColor(hex: "#734E3D"),
            PaletteColor(hex: "#432A17")
        ])
    }

    static var fiveColorOption1: Palette {
        Palette(name: "5-Color-Option-1", colors: [
            PaletteColor(hex: "#6DCDDD"),
            PaletteColor(hex: "#FB954B"),
            PaletteColor(hex: "#0092AD"),
            PaletteColor(hex: "#FBC797"),
            PaletteColor(hex: "#76C692")
        ])
    }

    static var atlas1: Palette {
        Palette(name: "Atlas-1", colors: [
            PaletteColor(hex: "#E5191D"),
            PaletteColor(hex: "#4376AC"),
            PaletteColor(hex: "#4AA75A"),
            PaletteColor(hex: "#87648F"),
            PaletteColor(hex: "#D77F32"),
            PaletteColor(hex: "#727690"),
            PaletteColor(hex: "#D690C6"),
            PaletteColor(hex: "#B17B7D"),
            PaletteColor(hex: "#857B74"),
            PaletteColor(hex: "#4386BF"),
            PaletteColor(hex: "#204B75"),
            PaletteColor(hex: "#588257"),
            PaletteColor(hex: "#B7DB7B"),
            PaletteColor(hex: "#E3BD05"),
            PaletteColor(hex: "#FA9C93"),
            PaletteColor(hex: "#E9358C"),
            PaletteColor(hex: "#A1094E"),
            PaletteColor(hex: "#999999"),
            PaletteColor(hex: "#6FCDDC"),
            PaletteColor(hex: "#BD5E95"),
            PaletteColor(hex: "#D0AFB2"),
            PaletteColor(hex: "#8EADCD"),
            PaletteColor(hex: "#92CB9C"),
            PaletteColor(hex: "#B8A1BC"),
            PaletteColor(hex: "#E7BCDD"),
            PaletteColor(hex: "#D89FC0")
        ])
    }

    static var atlas2: Palette {
        Palette(name: "Atlas-2", colors: [
            PaletteColor(hex: "#A1DAC8"),
            PaletteColor(hex: "#9BBBCD"),
            PaletteColor(hex: "#7C8EA9"),
            PaletteColor(hex: "#DA8F9F"),
            PaletteColor(hex: "#BB969F"),
            PaletteColor(hex: "#EAC697"),
            PaletteColor(hex: "#E4D282"),
            PaletteColor(hex: "#E4A1AA"),
            PaletteColor(hex: "#AFA5B7"),
            PaletteColor(hex: "#85C8B0"),
            PaletteColor(hex: "#B8D8E9"),
            PaletteColor(hex: "#EEC450"),
            PaletteColor(hex: "#BD9D42"),
            PaletteColor(hex: "#C6E1C5"),
            PaletteColor(hex: "#78B677")
        ])
    }

    static var fourColorOption1: Palette {
        Palette(name: "4-Color-Option-1", colors: [
            PaletteColor(hex: "#D7D8D9"),
            PaletteColor(hex: "#E6B481"),
            PaletteColor(hex: "#DBDB61"),
            PaletteColor(hex: "#445598")
        ])
    }

    static var rColorBrewerPaired: Palette {
        Palette(name: "RColorBrewer: Paired", colors: [
            PaletteColor(hex: "#A6CEE3"),
            PaletteColor(hex: "#1F78B4"),
            PaletteColor(hex: "#B2DF8A"),
            PaletteColor(hex: "#33A02C"),
            PaletteColor(hex: "#FB9A99"),
            PaletteColor(hex: "#E31A1C"),
            PaletteColor(hex: "#FDBF6F"),
            PaletteColor(hex: "#FF7F00"),
            PaletteColor(hex: "#CAB2D6"),
            PaletteColor(hex: "#6A3D9A"),
            PaletteColor(hex: "#FFFF99"),
            PaletteColor(hex: "#B15928")
        ])
    }

    static var twoColorOption1: Palette {
        Palette(name: "2-Color-Option-1", colors: [
            PaletteColor(hex: "#87648F"),
            PaletteColor(hex: "#D3D478")
        ])
    }

    static var twoColorOption2: Palette {
        Palette(name: "2-Color-Option-2", colors: [
            PaletteColor(hex: "#6480BB"),
            PaletteColor(hex: "#CE6095")
        ])
    }

    static var twoColorOption3: Palette {
        Palette(name: "2-Color-Option-3", colors: [
            PaletteColor(hex: "#8DCBC1"),
            PaletteColor(hex: "#F69A92")
        ])
    }
}
