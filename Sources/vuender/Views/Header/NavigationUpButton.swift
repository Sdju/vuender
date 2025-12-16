import SwiftUI

struct NavigationUpButton: View {
    let isEnabled: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Image(systemName: "arrow.up")
                .font(.system(size: 16))
        }
        .disabled(!isEnabled)
        .buttonStyle(.bordered)
    }
}

