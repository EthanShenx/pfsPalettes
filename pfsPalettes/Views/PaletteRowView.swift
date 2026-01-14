import SwiftUI
import UniformTypeIdentifiers

struct PaletteRowView: View {
    @EnvironmentObject private var store: PaletteStore
    @State private var isDropTargeted = false
    @State private var editingColor: PaletteColor?

    private let swatchSize: CGFloat = 30

    var body: some View {
        let colors = store.selectedPalette?.colors ?? []
        let sortedColors = store.sortedColors(colors)

        HStack(spacing: 6) {
            // Sort toggle button
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    store.toggleSortMode()
                }
            } label: {
                Image(systemName: store.sortMode.iconName)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .frame(width: 16, height: 16)
            }
            .buttonStyle(.borderless)
            .help("Sort by \(store.sortMode == .brightness ? "Hue" : "Brightness")")

            Group {
                if sortedColors.isEmpty {
                    EmptyStateView {
                        store.focusAddField()
                    }
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(sortedColors) { color in
                                SwatchView(
                                    color: color,
                                    size: swatchSize,
                                    onEdit: { editingColor = color },
                                    onDelete: { store.removeColor(color) }
                                )
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                }
            }

            // Color count indicator
            if !colors.isEmpty {
                Text("\(colors.count)")
                    .font(.system(size: 9, weight: .medium).monospacedDigit())
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.secondary.opacity(0.15))
                    )
            }
        }
        .frame(height: swatchSize + 6)
        .onDrop(of: UTType.pfsColorTypes + [.text], isTargeted: $isDropTargeted) { providers in
            store.handleDrop(providers: providers)
        }
        .sheet(item: $editingColor) { color in
            EditColorSheet(color: color) { newHex, newName in
                store.updateColor(color, newHex: newHex, newName: newName)
            }
        }
    }
}
