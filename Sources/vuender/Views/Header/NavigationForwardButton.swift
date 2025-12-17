import SwiftUI

struct NavigationForwardButton: View {
    let isEnabled: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Image(systemName: "chevron.right")
                .font(.system(size: 16))
        }
        .disabled(!isEnabled)
        .buttonStyle(.bordered)
    }
}

