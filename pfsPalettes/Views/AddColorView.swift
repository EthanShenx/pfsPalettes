import AppKit
import SwiftUI

struct AddColorView: View {
    @EnvironmentObject private var store: PaletteStore
    @FocusState private var hexFieldFocused: Bool

    @State private var hexInput = ""
    @State private var pickedColor = Color.white

    var body: some View {
        HStack(spacing: 8) {
            TextField("#RRGGBB or #RGB", text: $hexInput)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .frame(width: 140)
                .focused($hexFieldFocused)
                .onSubmit {
                    addFromText()
                }

            ColorPicker("", selection: $pickedColor, supportsOpacity: false)
                .labelsHidden()
                .scaleEffect(0.8)
                .frame(width: 22)
                .onChange(of: pickedColor) { newValue in
                    let nsColor = NSColor(newValue)
                    hexInput = ColorUtils.hexString(from: nsColor)
                }

            Button {
                addFromText()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 14))
            }
            .buttonStyle(.borderless)
            .disabled(hexInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .onChange(of: store.wantsAddFieldFocus) { wantsFocus in
            if wantsFocus {
                hexFieldFocused = true
                store.wantsAddFieldFocus = false
            }
        }
    }

    private func addFromText() {
        store.addColors(fromText: hexInput)
        hexInput = ""
    }
}
