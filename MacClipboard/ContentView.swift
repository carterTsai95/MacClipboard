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
    @FocusState private var isSearchFocused: Bool
    @State private var searchText = ""
    @State private var selectedTab: Tab = .all
    
    var filteredItems: [ClipboardItem] {
        if searchText.isEmpty {
            return clipboardManager.clipboardItems
        }
        return clipboardManager.clipboardItems.filter { item in
            switch item.content {
            case .text(let string):
                return string.localizedCaseInsensitiveContains(searchText)
            case .image:
                return false // Images are not searchable
            }
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack {
                ClipboardListView(selectedItemId: $selectedItemId, 
                                isSearchFocused: $isSearchFocused,
                                searchText: $searchText,
                                selectedTab: $selectedTab,
                                onCopy: showCopyFeedback)
                    .frame(minWidth: 400, minHeight: 400)
                    .navigationTitle("Clipboard History")
                    .onChange(of: selectedTab) { newTab in
                        updateSelectionForTab(newTab)
                    }
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
        .onChange(of: searchText) { _ in
            // When search text changes, update selection to first filtered item if current selection is not in filtered results
            if let currentId = selectedItemId, !filteredItems.contains(where: { $0.id == currentId }) {
                selectedItemId = filteredItems.first?.id
            }
        }
    }
    
    private func moveSelection(up: Bool) {
        let items = clipboardManager.clipboardItems
        guard !items.isEmpty else { return }
        
        // Filter items based on the current tab
        let navigableItems = selectedTab == .all ? items : items.filter { $0.isFavorite }
        guard !navigableItems.isEmpty else { return }
        
        if let currentIndex = navigableItems.firstIndex(where: { $0.id == selectedItemId }) {
            let newIndex = up ? 
                (currentIndex - 1 + navigableItems.count) % navigableItems.count : 
                (currentIndex + 1) % navigableItems.count
            selectedItemId = navigableItems[newIndex].id
        } else {
            selectedItemId = navigableItems[0].id
        }
    }
    
    private func updateSelectionForTab(_ tab: Tab) {
        // If we're switching to favorites tab and no favorite item is selected
        if tab == .favorites {
            let favoriteItems = clipboardManager.favoriteItems
            
            // If no favorite items, do nothing
            guard !favoriteItems.isEmpty else { return }
            
            // If current selection is not in favorites, select the first favorite
            if let currentId = selectedItemId, !favoriteItems.contains(where: { $0.id == currentId }) {
                selectedItemId = favoriteItems.first?.id
            } else if selectedItemId == nil {
                // If nothing is selected, select the first favorite
                selectedItemId = favoriteItems.first?.id
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

#Preview {
    ContentView()
        .environmentObject(ClipboardManager())
}
