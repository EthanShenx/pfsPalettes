import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct HeaderView: View {
    @EnvironmentObject private var store: PaletteStore

    @State private var showingNewPalette = false
    @State private var showingRenamePalette = false
    @State private var showingImport = false
    @State private var showingExportJSON = false
    @State private var showingOpacityPopover = false
    @State private var showingSamplePopover = false
    @State private var alertMessage: String?
    @State private var showingAlert = false

    var body: some View {
        HStack(spacing: 8) {
            Picker(selection: $store.selectedPaletteID) {
                ForEach(store.palettes) { palette in
                    PaletteMenuRow(palette: palette)
                        .tag(palette.id)
                }
            } label: {
                PalettePickerLabel(palette: store.selectedPalette)
            }
            .labelsHidden()
            .frame(minWidth: 160)
            .pickerStyle(.menu)

            Menu {
                Button("New Palette...") {
                    showingNewPalette = true
                }
                Button("Rename Palette...") {
                    showingRenamePalette = true
                }
                .disabled(store.selectedPalette == nil)
                Button("Delete Palette") {
                    store.deleteSelectedPalette()
                }
                .disabled(store.palettes.count < 2)

                Divider()

                Button("Import Palettes...") {
                    showingImport = true
                }
                Button("Export Palettes (JSON)...") {
                    showingExportJSON = true
                }
                Button("Export Current Palette (.clr)...") {
                    store.exportCurrentPaletteAsCLR()
                }
                .disabled(store.selectedPalette == nil)

                Divider()

                Button("Sample Colors...") {
                    showingSamplePopover = true
                }
                .disabled((store.selectedPalette?.colors.count ?? 0) < 3)
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .menuStyle(.borderlessButton)

            Spacer(minLength: 0)

            // Sample colors button
            if (store.selectedPalette?.colors.count ?? 0) >= 3 {
                Button {
                    showingSamplePopover.toggle()
                } label: {
                    Image(systemName: "square.3.layers.3d.down.left")
                        .font(.system(size: 10))
                }
                .buttonStyle(.borderless)
                .popover(isPresented: $showingSamplePopover) {
                    SampleColorsPopover()
                        .environmentObject(store)
                        .padding(10)
                        .frame(width: 180)
                }
                .help("Sample balanced colors from palette")
            }

            Button {
                showingOpacityPopover.toggle()
            } label: {
                Image(systemName: "slider.horizontal.3")
            }
            .buttonStyle(.borderless)
            .popover(isPresented: $showingOpacityPopover) {
                OpacityPopover()
                    .environmentObject(store)
                    .padding(10)
                    .frame(width: 180)
            }

            Button {
                store.isCollapsed.toggle()
            } label: {
                Image(systemName: store.isCollapsed ? "chevron.down" : "chevron.up")
            }
            .buttonStyle(.borderless)
        }
        .font(.system(size: 12))
        .fileImporter(
            isPresented: $showingImport,
            allowedContentTypes: [.json, .colorList],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                do {
                    let message = try store.importFromURL(url)
                    alertMessage = message
                    showingAlert = true
                } catch {
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            case .failure(let error):
                alertMessage = error.localizedDescription
                showingAlert = true
            }
        }
        .fileExporter(
            isPresented: $showingExportJSON,
            document: PalettesDocument(payload: store.exportPayload()),
            contentType: .json,
            defaultFilename: "Palettes"
        ) { result in
            if case .failure(let error) = result {
                alertMessage = error.localizedDescription
                showingAlert = true
            }
        }
        .sheet(isPresented: $showingNewPalette) {
            PaletteNameSheet(title: "New Palette", initialName: "") { name in
                store.addPalette(name: name)
            }
        }
        .sheet(isPresented: $showingRenamePalette) {
            PaletteNameSheet(title: "Rename Palette", initialName: store.selectedPalette?.name ?? "") { name in
                store.renameSelectedPalette(to: name)
            }
        }
        .alert("Palette Import", isPresented: $showingAlert, presenting: alertMessage) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
    }
}

private struct OpacityPopover: View {
    @EnvironmentObject var store: PaletteStore

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Background Opacity")
                .font(.caption)
            Slider(value: $store.windowBackgroundOpacity, in: 0.0...1.0)
        }
    }
}

private struct PalettePickerLabel: View {
    let palette: Palette?

    var body: some View {
        HStack(spacing: 6) {
            PaletteSwatch(color: middleColor(for: palette))
            Text(palette?.name ?? "Palette")
        }
    }

    private func middleColor(for palette: Palette?) -> PaletteColor? {
        guard let palette, !palette.colors.isEmpty else { return nil }
        let sorted = palette.colors.sorted { $0.luminance > $1.luminance }
        return sorted[sorted.count / 2]
    }
}

private struct PaletteMenuRow: View {
    let palette: Palette

    var body: some View {
        HStack(spacing: 6) {
            PaletteSwatch(color: middleColor(for: palette))
            Text(palette.name)
        }
    }

    private func middleColor(for palette: Palette) -> PaletteColor? {
        guard !palette.colors.isEmpty else { return nil }
        let sorted = palette.colors.sorted { $0.luminance > $1.luminance }
        return sorted[sorted.count / 2]
    }
}

private struct PaletteSwatch: View {
    let color: PaletteColor?

    var body: some View {
        let fillColor = color?.nsColor.map { Color(nsColor: $0) }

        RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(fillColor ?? Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .stroke(Color.secondary.opacity(0.4), lineWidth: fillColor == nil ? 1 : 0.5)
            )
            .frame(width: 12, height: 12)
    }
}

private struct SampleColorsPopover: View {
    @EnvironmentObject var store: PaletteStore
    @Environment(\.dismiss) private var dismiss
    @State private var sampleCount: Int = 5

    private var maxColors: Int {
        max(2, (store.selectedPalette?.colors.count ?? 2) - 1)
    }

    private var previewColors: [PaletteColor] {
        store.sampleColors(count: sampleCount)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Stepper(value: $sampleCount, in: 2...maxColors) {
                    Text("\(sampleCount)")
                        .font(.system(size: 12, weight: .medium).monospacedDigit())
                        .frame(width: 20, alignment: .trailing)
                }
                Text("colors")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Preview of sampled colors
            HStack(spacing: 3) {
                ForEach(previewColors.prefix(10)) { color in
                    if let nsColor = color.nsColor {
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(Color(nsColor: nsColor))
                            .frame(width: 12, height: 12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 2, style: .continuous)
                                    .stroke(Color.primary.opacity(0.15), lineWidth: 0.5)
                            )
                    }
                }
                if previewColors.count > 10 {
                    Text("+\(previewColors.count - 10)")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                }
            }

            Button {
                store.createSampledPalette(count: sampleCount)
                dismiss()
            } label: {
                Label("Create", systemImage: "plus.circle.fill")
                    .font(.caption)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
    }
}
