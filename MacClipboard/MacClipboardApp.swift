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
                Button("Clear History") {
                    NotificationCenter.default.post(name: NSNotification.Name("ClearHistory"), object: nil)
                }
                .keyboardShortcut("K", modifiers: [.command])
                
                Divider()
                
                Button("Quit MacClipboard") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("Q", modifiers: [.command])
            }
            
            CommandGroup(after: .textEditing) {
                Button("Copy Selected") {
                    NotificationCenter.default.post(name: NSNotification.Name("CopySelected"), object: nil)
                }
                .keyboardShortcut("C", modifiers: [.command])
            }
        }
        
        MenuBarExtra("Clipboard", systemImage: "clipboard") {
            if let latestItem = clipboardManager.clipboardItems.first {
                switch latestItem.content {
                case .text(let string):
                    Text(string)
                        .lineLimit(2)
                        .font(.system(size: 12))
                case .image(let data):
                    if let nsImage = NSImage(data: data) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 40)
                    }
                }
                
                Button("Copy Current") {
                    clipboardManager.copyToClipboard(latestItem)
                }
                .keyboardShortcut("C", modifiers: [.command])
                
                Divider()
            }
            
            ForEach(clipboardManager.clipboardItems.dropFirst().prefix(5)) { item in
                Button(action: {
                    clipboardManager.copyToClipboard(item)
                }) {
                    switch item.content {
                    case .text(let string):
                        Text(string)
                            .lineLimit(1)
                    case .image:
                        Text("Image")
                            .lineLimit(1)
                    }
                }
            }
            
            if clipboardManager.clipboardItems.count > 1 {
                Divider()
            }
            
            Button("Clear History") {
                clipboardManager.clearHistory()
            }
            .keyboardShortcut("K", modifiers: [.command])
            .disabled(clipboardManager.clipboardItems.isEmpty)
            
            Divider()
            
            Button("Show Clipboard Manager") {
                NSApp.activate(ignoringOtherApps: true)
                NSApp.windows.first?.makeKeyAndOrderFront(nil)
            }
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("Q", modifiers: [.command])
        }
    }
}
