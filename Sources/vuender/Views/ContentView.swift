import SwiftUI
import AppKit

struct ContentView: View {
    @StateObject private var viewModel: FileBrowserViewModel
    @Environment(\.openURL) private var openURL
    @State private var isTerminalVisible: Bool = false

    init(initialPath: String? = nil) {
        _viewModel = StateObject(wrappedValue: FileBrowserViewModel(initialPath: initialPath))
    }

    var body: some View {
        VStack(spacing: 0) {
            navigationBar
            Divider()
            fileTable
            if isTerminalVisible {
                Divider()
                TerminalPanelView(
                    currentDirectory: viewModel.currentDirectory,
                    onDirectoryChange: { @Sendable url in
                        Task { @MainActor in
                            viewModel.navigateToPath(url.path)
                        }
                    }
                )
                .frame(minHeight: 180, idealHeight: 220, maxHeight: 320)
            }
            Divider()
            footer
        }
        .frame(minWidth: 800, minHeight: 500)
        .onAppear {
            registerWindow()
        }
    }


    private func registerWindow() {
        if let window = NSApplication.shared.windows.first(where: { $0.isKeyWindow || $0.isMainWindow }) {
            WindowManager.shared.registerWindow(window, for: viewModel.currentDirectory.path)
        }
    }

    private var navigationBar: some View {
        NavigationBar(viewModel: viewModel)
    }

    private var fileTable: some View {
        FileBrowserView(viewModel: viewModel, viewMode: .table)
    }

    private var footer: some View {
        FooterView(
            totalItems: viewModel.files.count,
            selectedItems: viewModel.selectedFileIDs.count,
            isTerminalVisible: $isTerminalVisible
        )
    }
}



