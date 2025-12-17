import SwiftUI

struct NavigationBackButton: View {
    let isEnabled: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Image(systemName: "chevron.left")
                .font(.system(size: 16))
        }
        .disabled(!isEnabled)
        .buttonStyle(.bordered)
    }
}

