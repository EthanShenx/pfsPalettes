import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: PaletteStore
    @EnvironmentObject private var windowManager: WindowManager

    var body: some View {
        VStack(spacing: 8) {
            HeaderView()
            if !store.isCollapsed {
                PaletteRowView()
                AddColorView()
            }
        }
        .padding(8)
        .frame(minWidth: 260, maxWidth: .infinity)
        .background(PaletteBackgroundView())
        .onAppear {
            windowManager.setCollapsed(store.isCollapsed)
        }
        .onChange(of: store.isCollapsed) { newValue in
            windowManager.setCollapsed(newValue)
        }
    }
}
