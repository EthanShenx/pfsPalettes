import AppKit
import SwiftUI

struct SwatchView: View {
    @EnvironmentObject private var store: PaletteStore

    let color: PaletteColor
    let size: CGFloat
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var isHovered = false
    @State private var showCopied = false

    private var isStarred: Bool {
        store.isColorStarred(color.hex)
    }

    var body: some View {
        let displayColor = color.nsColor.map { Color(nsColor: $0) } ?? Color.gray

        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(displayColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                )

            if showCopied {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.black.opacity(0.35))
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }

            // Star icon (top-right corner)
            if isHovered || isStarred {
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                store.toggleStarColor(color.hex, name: color.name)
                            }
                        } label: {
                            Image(systemName: isStarred ? "star.fill" : "star")
                                .font(.system(size: 8, weight: .semibold))
                                .foregroundColor(isStarred ? .yellow : .white.opacity(0.7))
                                .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
                        }
                        .buttonStyle(.plain)
                        .padding(3)
                    }
                    Spacer()
                }
            }
        }
        .frame(width: size, height: size)
        .scaleEffect(isHovered ? 1.06 : 1)
        .animation(.spring(response: 0.22, dampingFraction: 0.7), value: isHovered)
        .shadow(color: Color.black.opacity(isHovered ? 0.18 : 0.1), radius: 4, x: 0, y: 2)
        .onHover { isHovered = $0 }
        .onTapGesture {
            ClipboardManager.copy(color.normalizedHex)
            showCopyFeedback()
        }
        .contextMenu {
            Button {
                store.toggleStarColor(color.hex, name: color.name)
            } label: {
                Label(isStarred ? "Unstar Color" : "Star Color", systemImage: isStarred ? "star.slash" : "star")
            }
            Divider()
            Button("Edit Hex...") {
                onEdit()
            }
            Button("Remove Color", role: .destructive) {
                onDelete()
            }
        }
        .help(color.tooltipText)
    }

    private func showCopyFeedback() {
        NSSound(named: "Tink")?.play()
        withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
            showCopied = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeOut(duration: 0.2)) {
                showCopied = false
            }
        }
    }
}

enum ClipboardManager {
    static func copy(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}
