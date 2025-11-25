//
//  LaunchPadApp.swift
//  LaunchPad
//
//  Created by ex_liuzp9 on 2025/11/25.
//

import SwiftUI

@main
struct LaunchPadApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .windowStyle(.hiddenTitleBar)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let win = NSApp.windows.first else { return }
        self.window = win
        activateFakeFullscreen(win)
    }

    private func activateFakeFullscreen(_ window: NSWindow) {
        // Hide macOS menu bar and Dock
        NSMenu.setMenuBarVisible(false)
        NSApp.presentationOptions = [.hideDock, .hideMenuBar]

        // Allow window to appear above other spaces (no new desktop)
        window.collectionBehavior = [.fullScreenAuxiliary, .canJoinAllSpaces]

        // Remove system fullscreen
        window.collectionBehavior.remove(.fullScreenPrimary)

        // Hide title bar
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.styleMask.insert(.fullSizeContentView)
        window.styleMask.remove(.titled)

        // Resize to fill the screen
        if let screen = NSScreen.main {
            window.setFrame(screen.frame, display: true, animate: false)
        }

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
