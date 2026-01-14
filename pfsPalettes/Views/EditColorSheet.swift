import AppKit
import SwiftUI

struct EditColorSheet: View {
    let color: PaletteColor
    let onSave: (String, String?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var hexText: String
    @State private var nameText: String
    @State private var pickedColor: Color

    init(color: PaletteColor, onSave: @escaping (String, String?) -> Void) {
        self.color = color
        self.onSave = onSave
        _hexText = State(initialValue: color.normalizedHex)
        _nameText = State(initialValue: color.name ?? "")
        _pickedColor = State(initialValue: color.nsColor.map { Color(nsColor: $0) } ?? .white)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Edit Color")
                .font(.headline)

            TextField("Hex", text: $hexText)
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .textFieldStyle(.roundedBorder)

            TextField("Name (optional)", text: $nameText)
                .textFieldStyle(.roundedBorder)

            ColorPicker("", selection: $pickedColor, supportsOpacity: false)
                .labelsHidden()
                .onChange(of: pickedColor) { newValue in
                    let nsColor = NSColor(newValue)
                    hexText = ColorUtils.hexString(from: nsColor)
                }

            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                Button("Save") {
                    onSave(hexText, nameText.isEmpty ? nil : nameText)
                    dismiss()
                }
                .disabled(ColorUtils.normalizeHex(hexText) == nil)
            }
        }
        .padding(20)
        .frame(width: 320)
    }
}
