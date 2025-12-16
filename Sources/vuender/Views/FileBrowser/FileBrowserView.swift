import SwiftUI

enum FileViewMode {
    case table
    // В будущем можно добавить: case list, case grid, case column
}

struct FileBrowserView: View {
    @ObservedObject var viewModel: FileBrowserViewModel
    var viewMode: FileViewMode = .table
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView()
            } else if viewModel.files.isEmpty {
                EmptyStateView()
            } else {
                contentView
            }
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        switch viewMode {
        case .table:
            FileTableView(viewModel: viewModel)
        }
    }
}

