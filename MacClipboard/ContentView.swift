//
//  ContentView.swift
//  MacClipboard
//
//  Created by Hung-Chun Tsai on 2025-03-30.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var clipboardManager: ClipboardManager
    
    var body: some View {
        List {
            if let latestItem = clipboardManager.clipboardItems.first {
                Section(header: Text("Current Clipboard")) {
                    ClipboardItemRow(item: latestItem, clipboardManager: clipboardManager, isLatest: true)
                }
            }
            
            if clipboardManager.clipboardItems.count > 1 {
                Section(header: Text("History")) {
                    ForEach(Array(clipboardManager.clipboardItems.dropFirst())) { item in
                        ClipboardItemRow(item: item, clipboardManager: clipboardManager, isLatest: false)
                    }
                }
            }
        }
        .listStyle(InsetListStyle())
        .frame(minWidth: 400, minHeight: 400)
        .navigationTitle("Clipboard History")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    clipboardManager.clearHistory()
                }) {
                    Label("Clear History", systemImage: "trash")
                }
                .disabled(clipboardManager.clipboardItems.isEmpty)
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    NSApp.terminate(nil)
                }) {
                    Label("Quit", systemImage: "power")
                }
            }
        }
        .onAppear {
            setupNotifications()
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ClearHistory"),
            object: nil,
            queue: .main
        ) { _ in
            clipboardManager.clearHistory()
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("CopySelected"),
            object: nil,
            queue: .main
        ) { _ in
            if let selectedItem = clipboardManager.clipboardItems.first {
                clipboardManager.copyToClipboard(selectedItem)
            }
        }
    }
}

struct ClipboardItemRow: View {
    let item: ClipboardItem
    @ObservedObject var clipboardManager: ClipboardManager
    let isLatest: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(item.content)
                    .lineLimit(2)
                Text(item.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                clipboardManager.copyToClipboard(item)
            }) {
                Image(systemName: "doc.on.doc")
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
            
            Button(action: {
                clipboardManager.deleteItem(item)
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
            .disabled(isLatest)
            .opacity(isLatest ? 0.5 : 1.0)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
        .environmentObject(ClipboardManager())
}
