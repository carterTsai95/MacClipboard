import SwiftUI

struct ClipboardGroupTabs: View {
    @ObservedObject var clipboardManager: ClipboardManager
    @Binding var selectedTab: Tab
    @State private var showingNewGroupSheet = false
    @State private var newGroupName = ""
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                // Default tabs
                DefaultTabsView(selectedTab: $selectedTab)
                
                // Custom groups
                if !clipboardManager.customGroups.isEmpty {
                    Divider()
                        .padding(.horizontal, 8)
                        .frame(height: 15)
                    
                    CustomGroupsTabsView(
                        clipboardManager: clipboardManager,
                        selectedTab: $selectedTab
                    )
                }
                
                // New group button
                NewGroupButton(
                    showingNewGroupSheet: $showingNewGroupSheet,
                    newGroupName: $newGroupName,
                    clipboardManager: clipboardManager,
                    selectedTab: $selectedTab
                )
            }
            .padding(.horizontal)
        }
    }
}

private struct DefaultTabsView: View {
    @Binding var selectedTab: Tab
    
    var body: some View {
        HStack {
            Button(action: { selectedTab = .all }) {
                Label("All", systemImage: "list.bullet")
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(selectedTab == .all ? Color.accentColor : Color.clear)
                    .foregroundColor(selectedTab == .all ? .white : .primary)
                    .contentShape(Rectangle())
            }
            .buttonStyle(FixedHeightButtonStyle())
            
            Button(action: { selectedTab = .favorites }) {
                Label("Favorites", systemImage: "star.fill")
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(selectedTab == .favorites ? Color.accentColor : Color.clear)
                    .foregroundColor(selectedTab == .favorites ? .white : .primary)
                    .contentShape(Rectangle())
            }
            .buttonStyle(FixedHeightButtonStyle())
        }
        .background(Color.secondary.opacity(0.2))
        .cornerRadius(6)
    }
}

private struct CustomGroupsTabsView: View {
    @ObservedObject var clipboardManager: ClipboardManager
    @Binding var selectedTab: Tab
    @State private var hoveredGroupId: UUID? = nil
    @State private var hoveredDeleteButtonId: UUID? = nil
    
    var body: some View {
        HStack {
            ForEach(clipboardManager.customGroups) { group in
                HStack(spacing: 0) {
                    Button(action: { selectedTab = .custom(group) }) {
                        Label(group.name, systemImage: "folder.fill")
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(
                                Group {
                                    if case .custom(let selectedGroup) = selectedTab,
                                       selectedGroup.id == group.id {
                                        Color.accentColor
                                    } else {
                                        Color.clear
                                    }
                                }
                            )
                            .foregroundColor(
                                (selectedTab == .custom(group)) ? .white : .primary
                            )
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(FixedHeightButtonStyle())
                    
                    if hoveredGroupId == group.id {
                        Button(action: {
                            clipboardManager.deleteCustomGroup(group)
                            if case .custom(let selectedGroup) = selectedTab,
                               selectedGroup.id == group.id {
                                selectedTab = .all
                            }
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill((hoveredDeleteButtonId == group.id) ? Color.red.opacity(0.15) : Color.clear)
                                    .frame(width: 28, height: 28)
                                    .animation(.easeInOut(duration: 0.2), value: hoveredDeleteButtonId)
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                        .buttonStyle(FixedHeightButtonStyle())
                        .onHover { hovering in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                hoveredDeleteButtonId = hovering ? group.id : nil
                            }
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .background(Color.secondary.opacity(0.2))
                .frame(height: 28)
                .cornerRadius(6)
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        hoveredGroupId = hovering ? group.id : nil
                    }
                }
            }
        }
    }
}

private struct NewGroupButton: View {
    @Binding var showingNewGroupSheet: Bool
    @Binding var newGroupName: String
    @ObservedObject var clipboardManager: ClipboardManager
    @Binding var selectedTab: Tab
    
    var body: some View {
        Button(action: {
            showingNewGroupSheet = true
        }) {
            Image(systemName: "plus.circle.fill")
                .foregroundColor(.accentColor)
                .padding(.leading, 8)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingNewGroupSheet) {
            NewGroupSheet(
                showingNewGroupSheet: $showingNewGroupSheet,
                newGroupName: $newGroupName,
                clipboardManager: clipboardManager,
                selectedTab: $selectedTab
            )
        }
    }
}

private struct NewGroupSheet: View {
    @Binding var showingNewGroupSheet: Bool
    @Binding var newGroupName: String
    @ObservedObject var clipboardManager: ClipboardManager
    @Binding var selectedTab: Tab
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Create New Group")
                .font(.headline)
            
            TextField("Group Name", text: $newGroupName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            HStack {
                Button("Cancel") {
                    showingNewGroupSheet = false
                    newGroupName = ""
                }
                
                Button("Create") {
                    if !newGroupName.isEmpty {
                        clipboardManager.createCustomGroup(name: newGroupName) { group in
                            selectedTab = .custom(group)
                            showingNewGroupSheet = false
                            newGroupName = ""
                        }
                    }
                }
                .disabled(newGroupName.isEmpty)
            }
        }
        .padding()
        .frame(width: 300)
    }
}

private struct FixedHeightButtonStyle: ButtonStyle {
    var height: CGFloat = 28
    var cornerRadius: CGFloat = 6

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(height: height)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.clear) // You can customize this
            )
    }
}

#Preview {
    struct PreviewWrapper: View {
        @StateObject private var clipboardManager = ClipboardManager()
        @State private var selectedTab: Tab = .all
        
        var body: some View {
            VStack {
                ClipboardGroupTabs(clipboardManager: clipboardManager, selectedTab: $selectedTab)
                
                Text("Selected Tab: \(String(describing: selectedTab))")
                    .padding()
                
                Button("Add Sample Group") {
                    clipboardManager.createCustomGroup(name: "Sample Group") { _ in }
                }
                .padding()
            }
            .frame(width: 600)
            .padding()
            .onAppear {
                // Add some sample data for preview
                clipboardManager.createCustomGroup(name: "Work") { _ in }
                clipboardManager.createCustomGroup(name: "Personal") { _ in }
            }
        }
    }
    
    return PreviewWrapper()
}
