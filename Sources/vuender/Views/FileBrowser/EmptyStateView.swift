import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        VStack {
            Text("Папка пуста")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

