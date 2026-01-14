import AppKit
import Foundation

enum ColorUtils {
    static func normalizeHex(_ input: String) -> String? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let raw = trimmed.hasPrefix("#") ? String(trimmed.dropFirst()) : trimmed
        guard raw.count == 3 || raw.count == 6 else { return nil }
        guard raw.unicodeScalars.allSatisfy({ CharacterSet.pfsHexDigits.contains($0) }) else { return nil }

        let expanded: String
        if raw.count == 3 {
            expanded = raw.map { "\($0)\($0)" }.joined()
        } else {
            expanded = raw
        }
        return "#\(expanded.uppercased())"
    }

    static func nsColor(from hex: String) -> NSColor? {
        guard let normalized = normalizeHex(hex) else { return nil }
        let startIndex = normalized.index(normalized.startIndex, offsetBy: 1)
        let hexValue = String(normalized[startIndex...])
        let scanner = Scanner(string: hexValue)
        var rgb: UInt64 = 0
        guard scanner.scanHexInt64(&rgb) else { return nil }

        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0
        return NSColor(srgbRed: red, green: green, blue: blue, alpha: 1.0)
    }

    static func hexString(from color: NSColor) -> String {
        guard let rgb = color.usingColorSpace(.sRGB) else { return "#000000" }
        let red = Int(round(rgb.redComponent * 255))
        let green = Int(round(rgb.greenComponent * 255))
        let blue = Int(round(rgb.blueComponent * 255))
        return String(format: "#%02X%02X%02X", red, green, blue)
    }

    static func luminance(for color: NSColor?) -> Double {
        guard let color, let rgb = color.usingColorSpace(.sRGB) else { return 0 }

        func adjust(_ value: CGFloat) -> Double {
            let v = Double(value)
            if v <= 0.03928 {
                return v / 12.92
            }
            return pow((v + 0.055) / 1.055, 2.4)
        }

        let r = adjust(rgb.redComponent)
        let g = adjust(rgb.greenComponent)
        let b = adjust(rgb.blueComponent)
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }

    /// Returns HSB components: (hue: 0-360, saturation: 0-1, brightness: 0-1)
    static func hsb(for color: NSColor?) -> (hue: Double, saturation: Double, brightness: Double) {
        guard let color, let rgb = color.usingColorSpace(.sRGB) else {
            return (hue: 0, saturation: 0, brightness: 0)
        }
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        rgb.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return (hue: Double(h) * 360, saturation: Double(s), brightness: Double(b))
    }

    /// Creates a tint (lighter) version of a color by mixing with white.
    /// - Parameter percentage: 0.0 to 1.0, where 1.0 is pure white
    static func tint(_ color: NSColor, percentage: Double) -> NSColor {
        guard let rgb = color.usingColorSpace(.sRGB) else { return color }
        let factor = CGFloat(max(0, min(1, percentage)))
        let r = rgb.redComponent + (1 - rgb.redComponent) * factor
        let g = rgb.greenComponent + (1 - rgb.greenComponent) * factor
        let b = rgb.blueComponent + (1 - rgb.blueComponent) * factor
        return NSColor(srgbRed: r, green: g, blue: b, alpha: 1.0)
    }

    /// Creates a shade (darker) version of a color by mixing with black.
    /// - Parameter percentage: 0.0 to 1.0, where 1.0 is pure black
    static func shade(_ color: NSColor, percentage: Double) -> NSColor {
        guard let rgb = color.usingColorSpace(.sRGB) else { return color }
        let factor = CGFloat(max(0, min(1, 1 - percentage)))
        let r = rgb.redComponent * factor
        let g = rgb.greenComponent * factor
        let b = rgb.blueComponent * factor
        return NSColor(srgbRed: r, green: g, blue: b, alpha: 1.0)
    }

    /// Generates an array of tints and shades for a color.
    /// - Parameters:
    ///   - color: Base color
    ///   - tintShadeValue: -1.0 (full shade) to +1.0 (full tint), 0 is base
    ///   - steps: Number of color variations to generate
    static func generateTintShadeScale(from color: NSColor, value: Double, steps: Int = 9) -> [NSColor] {
        var colors: [NSColor] = []
        let stepSize = 2.0 / Double(steps - 1)  // From -1 to +1

        for i in 0..<steps {
            let position = -1.0 + (Double(i) * stepSize)
            let adjustedPosition = position + value
            let clampedPosition = max(-1.0, min(1.0, adjustedPosition))

            if clampedPosition >= 0 {
                colors.append(tint(color, percentage: clampedPosition))
            } else {
                colors.append(shade(color, percentage: -clampedPosition))
            }
        }
        return colors
    }
}

extension CharacterSet {
    static let pfsHexDigits = CharacterSet(charactersIn: "0123456789ABCDEFabcdef")
}
