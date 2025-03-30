//
//  ContentView.swift
//  MacClipboard
//
//  Created by Hung-Chun Tsai on 2025-03-30.
//

import SwiftUI

struct ToastView: View {
    let message: String
    
    var body: some View {
        Text(message)
            .padding()
            .background(Color.black.opacity(0.75))
            .foregroundColor(.white)
            .cornerRadius(10)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .padding(.bottom, 20)
    }
}

struct ClipboardListView: View {
    @EnvironmentObject private var clipboardManager: ClipboardManager
    @Binding var selectedItemId: UUID?
    let onCopy: () -> Void
    
    var body: some View {
        List(selection: $selectedItemId) {
            if let latestItem = clipboardManager.clipboardItems.first {
                Section(header: Text("Current Clipboard")) {
                    ClipboardItemRow(item: latestItem, 
                                   clipboardManager: clipboardManager, 
                                   isLatest: true,
                                   isSelected: selectedItemId == latestItem.id,
                                   onCopy: onCopy)
                    .tag(latestItem.id)
                }
            }
            
            if clipboardManager.clipboardItems.count > 1 {
                Section(header: Text("History")) {
                    ForEach(Array(clipboardManager.clipboardItems.dropFirst())) { item in
                        ClipboardItemRow(item: item, 
                                       clipboardManager: clipboardManager, 
                                       isLatest: false,
                                       isSelected: selectedItemId == item.id,
                                       onCopy: onCopy)
                        .tag(item.id)
                    }
                }
            }
        }
        .listStyle(InsetListStyle())
    }
}

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
            setupNotifications()
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

struct ClipboardItemRow: View {
    let item: ClipboardItem
    @ObservedObject var clipboardManager: ClipboardManager
    let isLatest: Bool
    let isSelected: Bool
    let onCopy: () -> Void
    @State private var showingPreview = false
    @State private var isCopyHovered = false
    @State private var isDeleteHovered = false
    
    var body: some View {
        HStack {
            // Content area with selection highlight
            HStack {
                VStack(alignment: .leading) {
                    switch item.content {
                    case .text(let string):
                        Text(string)
                            .lineLimit(2)
                    case .image(let data):
                        if let nsImage = NSImage(data: data) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 40)
                                .onTapGesture {
                                    showingPreview.toggle()
                                }
                                .popover(isPresented: $showingPreview, arrowEdge: .leading) {
                                    ImagePreviewView(imageData: data)
                                        .frame(width: 600, height: 400)
                                }
                        }
                    }
                    
                    Text(item.timestamp, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.vertical, 4)
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
            .cornerRadius(6)
            
            // Action buttons outside the selection highlight
            HStack(spacing: 12) {
                Button(action: {
                    clipboardManager.copyToClipboard(item)
                    onCopy()
                }) {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(isCopyHovered ? .white : .blue)
                        .padding(4)
                        .background(isCopyHovered ? Color.blue : Color.clear)
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    isCopyHovered = hovering
                }
                
                Button(action: {
                    clipboardManager.deleteItem(item)
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(isDeleteHovered ? .white : .red)
                        .padding(4)
                        .background(isDeleteHovered ? Color.red : Color.clear)
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
                .disabled(isLatest)
                .opacity(isLatest ? 0.5 : 1.0)
                .onHover { hovering in
                    isDeleteHovered = hovering && !isLatest
                }
            }
            .padding(.leading, 8)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ClipboardManager())
}
