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
