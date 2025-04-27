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
            MenuBarContentView(clipboardManager: clipboardManager)
        }
    }
}

struct MenuBarContentView: View {
    @ObservedObject var clipboardManager: ClipboardManager
    
    var body: some View {
        VStack {
            if let latestItem = clipboardManager.clipboardItems.first {
                LatestItemView(item: latestItem, clipboardManager: clipboardManager)
                Divider()
            }
            
            RecentItemsView(clipboardManager: clipboardManager)
            
            if clipboardManager.clipboardItems.count > 1 {
                Divider()
            }
            
            Button("Clear History") {
                clipboardManager.clearHistory()
            }
            .keyboardShortcut("K", modifiers: [.command])
            .disabled(clipboardManager.clipboardItems.isEmpty)
            
            if !clipboardManager.customGroups.isEmpty {
                Divider()
                CustomGroupsView(clipboardManager: clipboardManager)
            }
            
            Divider()
            
            Button("Show Clipboard Manager") {
                NSApp.activate(ignoringOtherApps: true)
                NSApp.windows.first?.makeKeyAndOrderFront(nil)
            }
            .keyboardShortcut("H", modifiers: .command)
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("Q", modifiers: .command)
        }
    }
}

struct LatestItemView: View {
    let item: ClipboardItem
    @ObservedObject var clipboardManager: ClipboardManager
    
    var body: some View {
        VStack {
            switch item.content {
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
                clipboardManager.copyToClipboard(item)
            }
            .keyboardShortcut("C", modifiers: [.command])
        }
    }
}

struct RecentItemsView: View {
    @ObservedObject var clipboardManager: ClipboardManager
    
    var body: some View {
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
    }
}

struct CustomGroupsView: View {
    @ObservedObject var clipboardManager: ClipboardManager
    
    var body: some View {
        Menu("Custom Groups") {
            ForEach(Array(clipboardManager.customGroups.enumerated()), id: \.element.id) { index, group in
                Group {
                    switch index {
                    case 0:
                        Menu(group.name) {
                            groupContent(for: group)
                        }
                        .keyboardShortcut("1", modifiers: .command)
                    case 1:
                        Menu(group.name) {
                            groupContent(for: group)
                        }
                        .keyboardShortcut("2", modifiers: .command)
                    case 2:
                        Menu(group.name) {
                            groupContent(for: group)
                        }
                        .keyboardShortcut("3", modifiers: .command)
                    case 3:
                        Menu(group.name) {
                            groupContent(for: group)
                        }
                        .keyboardShortcut("4", modifiers: .command)
                    case 4:
                        Menu(group.name) {
                            groupContent(for: group)
                        }
                        .keyboardShortcut("5", modifiers: .command)
                    case 5:
                        Menu(group.name) {
                            groupContent(for: group)
                        }
                        .keyboardShortcut("6", modifiers: .command)
                    case 6:
                        Menu(group.name) {
                            groupContent(for: group)
                        }
                        .keyboardShortcut("7", modifiers: .command)
                    case 7:
                        Menu(group.name) {
                            groupContent(for: group)
                        }
                        .keyboardShortcut("8", modifiers: .command)
                    case 8:
                        Menu(group.name) {
                            groupContent(for: group)
                        }
                        .keyboardShortcut("9", modifiers: .command)
                    default:
                        Menu(group.name) {
                            groupContent(for: group)
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func groupContent(for group: CustomGroup) -> some View {
        let items = clipboardManager.itemsInGroup(group)
        if items.isEmpty {
            Text("No items")
                .foregroundColor(.secondary)
        } else {
            ForEach(items.prefix(5)) { item in
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
        }
    }
}
