import SwiftUI
import AppKit

struct ResizableDivider: View {
    @Binding var height: CGFloat
    @State private var isDragging: Bool = false
    
    private let minHeight: CGFloat = 100
    private let maxHeight: CGFloat = 600
    
    var body: some View {
        Rectangle()
            .fill(isDragging ? Color.accentColor : Color(NSColor.separatorColor))
            .frame(height: isDragging ? 2 : 1)
            .overlay(
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 8)
                    .contentShape(Rectangle())
            )
            .cursor(NSCursor.resizeUpDown)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        isDragging = true
                        let newHeight = height - value.translation.height
                        height = min(max(newHeight, minHeight), maxHeight)
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
    }
}

extension View {
    func cursor(_ cursor: NSCursor) -> some View {
        self.onContinuousHover { phase in
            switch phase {
            case .active:
                cursor.push()
            case .ended:
                NSCursor.pop()
            }
        }
    }
}


