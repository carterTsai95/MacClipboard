import SwiftUI

struct ClipboardSearchBar: View {
    @Binding var searchText: String
    @FocusState.Binding var isSearchFocused: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Search clipboard items...", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .focused($isSearchFocused)
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var searchText = ""
        @FocusState private var isSearchFocused: Bool
        
        var body: some View {
            VStack {
                ClipboardSearchBar(searchText: $searchText, isSearchFocused: $isSearchFocused)
                
                Text("Search text: \(searchText)")
                    .padding()
                
                Button("Toggle Focus") {
                    isSearchFocused.toggle()
                }
                .padding()
            }
            .frame(width: 400)
            .padding()
        }
    }
    
    return PreviewWrapper()
} 