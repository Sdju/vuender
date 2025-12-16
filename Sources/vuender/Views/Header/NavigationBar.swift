import SwiftUI

struct NavigationBar: View {
    @ObservedObject var viewModel: FileBrowserViewModel

    var body: some View {
        HStack {
            NavigationUpButton(
                isEnabled: viewModel.canNavigateUp(),
                onTap: {
                    viewModel.navigateUp()
                }
            )

            PathInputView(viewModel: viewModel)

            Spacer()
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
}
