import AppKit
import SwiftUI

final class WindowManager: NSObject, ObservableObject, NSWindowDelegate {
    static let shared = WindowManager()

    @Published private(set) var isVisible = true

    private weak var window: NSWindow?
    private var lastExpandedFrame: CGRect?
    private var isCollapsed = false

    func attach(window: NSWindow) {
        guard self.window !== window else { return }
        self.window = window
        configure(window: window)
    }

    func toggleVisibility() {
        guard let window else { return }
        if window.isVisible {
            window.orderOut(nil)
            isVisible = false
        } else {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            isVisible = true
        }
    }

    func setCollapsed(_ collapsed: Bool) {
        guard let window, collapsed != isCollapsed else { return }

        if collapsed {
            lastExpandedFrame = window.frame
            let targetSize = CGSize(width: window.frame.width, height: 44)
            window.setContentSize(targetSize)
        } else if let frame = lastExpandedFrame {
            window.setFrame(frame, display: true, animate: true)
        }

        isCollapsed = collapsed
    }

    private func configure(window: NSWindow) {
        window.level = .floating
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.styleMask.insert(.fullSizeContentView)
        window.styleMask.insert(.resizable)
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.backgroundColor = .clear
        window.isOpaque = false
        window.delegate = self

        let autosaveName = "PaletteFloaterWindow"
        window.setFrameAutosaveName(autosaveName)
        let autosaveKey = "NSWindow Frame \(autosaveName)"
        if UserDefaults.standard.string(forKey: autosaveKey) == nil {
            // Only apply the default size when the window has never been moved.
            let defaultSize = CGSize(width: 330, height: 90)
            window.setContentSize(defaultSize)
            if let screen = window.screen ?? NSScreen.main {
                let origin = CGPoint(
                    x: screen.visibleFrame.midX - defaultSize.width / 2,
                    y: screen.visibleFrame.midY - defaultSize.height / 2
                )
                window.setFrameOrigin(origin)
            }
        }
    }

    func windowDidResize(_ notification: Notification) {
        guard !isCollapsed, let window else { return }
        lastExpandedFrame = window.frame
    }

    func windowWillClose(_ notification: Notification) {
        isVisible = false
    }
}
