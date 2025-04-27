//
//  MacClipboardApp.swift
//  MacClipboard
//
//  Created by Hung-Chun Tsai on 2025-03-30.
//

import SwiftUI

@main
struct MacClipboardApp: App {
    @StateObject private var clipboardManager = ClipboardManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(clipboardManager)
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About MacClipboard") {
                    NSApplication.shared.orderFrontStandardAboutPanel()
                }
            }
            
            CommandGroup(replacing: .newItem) {}  // Remove the "New" menu item
            
            CommandGroup(after: .appInfo) {
                Button("Quit MacClipboard") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("Q", modifiers: [.command])
            }
        }
        
        MenuBarExtra("Clipboard", systemImage: "clipboard") {
            MenuBarContentView(clipboardManager: clipboardManager)
        }
    }
}
