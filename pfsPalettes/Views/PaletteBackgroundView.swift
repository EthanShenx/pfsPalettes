import AppKit
import SwiftUI

struct PaletteBackgroundView: View {
    @EnvironmentObject private var store: PaletteStore

    var body: some View {
        ZStack {
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow, state: .active)
                .opacity(store.windowBackgroundOpacity)
            Rectangle()
                .fill(Color(nsColor: .windowBackgroundColor).opacity(store.windowBackgroundOpacity))
        }
    }
}
