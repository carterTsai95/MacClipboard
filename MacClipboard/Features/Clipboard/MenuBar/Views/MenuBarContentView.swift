import SwiftUI

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