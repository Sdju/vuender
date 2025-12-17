import SwiftUI

struct NavigationBar: View {
    @ObservedObject var viewModel: FileBrowserViewModel

    var body: some View {
        HStack {
            NavigationBackButton(
                isEnabled: viewModel.canNavigateBack,
                onTap: {
                    viewModel.navigateBack()
                }
            )
            
            NavigationForwardButton(
                isEnabled: viewModel.canNavigateForward,
                onTap: {
                    viewModel.navigateForward()
                }
            )
            
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
