//
//  ContentView.swift
//  MacClipboard
//
//  Created by Hung-Chun Tsai on 2025-03-30.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var clipboardManager: ClipboardManager
    @State private var selectedItemId: UUID?
    @State private var showCopyToast = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack {
                ClipboardListView(selectedItemId: $selectedItemId, onCopy: showCopyFeedback)
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
            }
            
            if showCopyToast {
                ToastView(message: "Copied to clipboard!")
            }
        }
        .animation(.easeInOut, value: showCopyToast)
        .onAppear {
            if let firstItem = clipboardManager.clipboardItems.first {
                selectedItemId = firstItem.id
            }
        }
        .onKeyPress(.upArrow) {
            moveSelection(up: true)
            return .handled
        }
        .onKeyPress(.downArrow) {
            moveSelection(up: false)
            return .handled
        }
        .onKeyPress(.return) {
            copySelectedItem()
            return .handled
        }
    }
    
    private func moveSelection(up: Bool) {
        let items = clipboardManager.clipboardItems
        guard !items.isEmpty else { return }
        
        if let currentIndex = items.firstIndex(where: { $0.id == selectedItemId }) {
            let newIndex = up ? 
                (currentIndex - 1 + items.count) % items.count : 
                (currentIndex + 1) % items.count
            selectedItemId = items[newIndex].id
        } else {
            selectedItemId = items[0].id
        }
    }
    
    private func copySelectedItem() {
        if let selectedId = selectedItemId,
           let selectedItem = clipboardManager.clipboardItems.first(where: { $0.id == selectedId }) {
            clipboardManager.copyToClipboard(selectedItem)
            showCopyFeedback()
        }
    }
    
    private func showCopyFeedback() {
        showCopyToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showCopyToast = false
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ClipboardManager())
}
