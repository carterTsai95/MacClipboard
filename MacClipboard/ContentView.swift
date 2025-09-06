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
                    .onChange(of: selectedTab) { newTab, _ in
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
        .onChange(of: searchText) { _ in
            // When search text changes, update selection to first filtered item if current selection is not in filtered results
            if let currentId = selectedItemId, !filteredItems.contains(where: { $0.id == currentId }) {
                selectedItemId = filteredItems.first?.id
            }
        }
        .onKeyPress(phases: .down) { press in
            guard press.modifiers == .command else { return .ignored }
            if let keyChar = press.characters.first {
                let keyString = String(keyChar)
                let groupIndex: Int?
                if let intVal = Int(keyString), intVal >= 1 && intVal <= 9 {
                    groupIndex = intVal - 1
                } else if keyString == "0" {
                    groupIndex = 9
                } else {
                    groupIndex = nil
                }
                if let groupIndex, groupIndex < clipboardManager.customGroups.count {
                    selectedTab = .custom(clipboardManager.customGroups[groupIndex])
                    return .handled
                }
            }
            return .ignored
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
        print("🔄 ContentView - Updating selection for tab: \(tab)")
        
        let items: [ClipboardItem]
        switch tab {
        case .all:
            items = clipboardManager.clipboardItems
            print("📋 All items count: \(items.count)")
        case .favorites:
            items = clipboardManager.favoriteItems
            print("⭐️ Favorite items count: \(items.count)")
        case .custom(let group):
            items = clipboardManager.itemsInGroup(group)
            print("📁 Group '\(group.name)' items count: \(items.count)")
            print("📁 Group '\(group.name)' itemIds: \(group.itemIds)")
        }
        
        // If no items in the tab, do nothing
        guard !items.isEmpty else {
            print("❌ No items in tab, keeping current selection")
            return
        }
        
        print("🎯 Current selection ID: \(selectedItemId?.uuidString ?? "nil")")
        
        // If current selection is not in the tab's items, select the first item
        if let currentId = selectedItemId, !items.contains(where: { $0.id == currentId }) {
            selectedItemId = items.first?.id
            print("🔄 Selection not in tab, updating to: \(items.first?.id.uuidString ?? "nil")")
        } else if selectedItemId == nil {
            // If nothing is selected, select the first item
            selectedItemId = items.first?.id
            print("🆕 No current selection, setting to: \(items.first?.id.uuidString ?? "nil")")
        } else {
            print("✅ Keeping current selection: \(selectedItemId?.uuidString ?? "nil")")
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
