import SwiftUI

struct PaletteCommands: Commands {
    @ObservedObject private var windowManager = WindowManager.shared

    var body: some Commands {
        CommandGroup(after: .appInfo) {
            Button(windowManager.isVisible ? "Hide Palette Floater" : "Show Palette Floater") {
                windowManager.toggleVisibility()
            }
            .keyboardShortcut("c", modifiers: [.command, .shift])
        }
    }
}
