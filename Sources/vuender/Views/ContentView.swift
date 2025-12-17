import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = FileBrowserViewModel()

    var body: some View {
        VStack(spacing: 0) {
            navigationBar
            Divider()
            fileTable
            Divider()
            footer
        }
        .frame(minWidth: 800, minHeight: 500)
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
            selectedItems: viewModel.selectedFileIDs.count
        )
    }
}



