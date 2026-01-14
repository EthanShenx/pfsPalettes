import SwiftUI

@main
struct PaletteFloaterApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = PaletteStore()
    @StateObject private var windowManager = WindowManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(windowManager)
                .background(WindowAccessor { window in
                    windowManager.attach(window: window)
                })
        }
        .commands {
            PaletteCommands()
        }
    }
}
