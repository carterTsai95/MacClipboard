//
//  TagFilterBar.swift
//  MacClipboard
//
//  Created by Hung-Chun Tsai on 2025-09-08.
//
import SwiftUI

struct TagFilterBar: View {
    let allTags: [String]
    @Binding var selectedTags: Set<String>
    let colorForTag: (String) -> Color

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button(action: { selectedTags.removeAll() }) {
                    Text("All")
                        .font(.caption)
                        .fontWeight(selectedTags.isEmpty ? .bold : .regular)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(selectedTags.isEmpty ? Color.accentColor : Color.secondary.opacity(0.2))
                        .foregroundColor(selectedTags.isEmpty ? .white : .primary)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                ForEach(allTags, id: \.self) { tag in
                    Button(action: {
                        if selectedTags.contains(tag) {
                            selectedTags.remove(tag)
                        } else {
                            selectedTags.insert(tag)
                        }
                    }) {
                        Text(tag)
                            .modifier(TagStyleModifier(color: colorForTag(tag)))
                            .fontWeight(selectedTags.contains(tag) ? .bold : .regular)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
}
