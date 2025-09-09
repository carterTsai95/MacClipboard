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
                            .font(.caption)
                            .fontWeight(selectedTags.contains(tag) ? .bold : .regular)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                selectedTags.contains(tag)
                                    ? colorForTag(tag)
                                    : Color.secondary.opacity(0.15)
                            )
                            .foregroundColor(selectedTags.contains(tag) ? .white : .primary)
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(selectedTags.contains(tag) ? colorForTag(tag) : Color.clear, lineWidth: 1.5)
                            )
                            .shadow(color: selectedTags.contains(tag) ? colorForTag(tag).opacity(0.3) : .clear, radius: selectedTags.contains(tag) ? 3 : 0)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
}
