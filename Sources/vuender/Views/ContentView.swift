import SwiftUI
import AppKit

struct ContentView: View {
    @StateObject private var viewModel: FileBrowserViewModel
    @Environment(\.openURL) private var openURL
    @State private var isTerminalVisible: Bool = false
    @State private var terminalHeight: CGFloat = 220

    init(initialPath: String? = nil) {
        _viewModel = StateObject(wrappedValue: FileBrowserViewModel(initialPath: initialPath))
    }

    var body: some View {
        VStack(spacing: 0) {
            navigationBar
                .zIndex(100)
            Divider()
            fileTable
            if isTerminalVisible {
                ResizableDivider(height: $terminalHeight)
                TerminalPanelView(
                    currentDirectory: viewModel.currentDirectory,
                    onDirectoryChange: { @Sendable url in
                        Task { @MainActor in
                            viewModel.navigateToPath(url.path)
                        }
                    }
                )
                .frame(height: terminalHeight)
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



