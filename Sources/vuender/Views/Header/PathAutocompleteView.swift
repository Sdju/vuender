import SwiftUI

struct PathAutocompleteView: View {
    let suggestions: [String]
    let selectedIndex: Int
    let onSelect: (String) -> Void
    
    var body: some View {
        if !suggestions.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(suggestions.enumerated()), id: \.element) { index, suggestion in
                    Button(action: {
                        onSelect(suggestion)
                    }) {
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 12))
                            
                            Text(suggestion)
                                .font(.system(size: 12))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                    .background(index == selectedIndex ? Color(NSColor.selectedControlColor) : Color(NSColor.controlBackgroundColor))
                    
                    if suggestion != suggestions.last {
                        Divider()
                    }
                }
            }
            .background(Color(NSColor.windowBackgroundColor))
            .cornerRadius(4)
            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            .frame(maxWidth: 500)
        }
    }
}

