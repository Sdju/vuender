import SwiftUI

struct FileTableView: View {
    @ObservedObject var viewModel: FileBrowserViewModel
    @State private var selectedFileID: FileItem.ID?

    var body: some View {
        Table(
            of: FileItem.self,
            selection: $selectedFileID,
            sortOrder: $viewModel.sortOrder,
        ) {
            nameColumn
            sizeColumn
            dateColumn
            typeColumn
        } rows: {
            ForEach(viewModel.files) { file in
                TableRow(file)
                    .contextMenu {
                        FileContextMenu(file: file, viewModel: viewModel)
                    }
            }
        }
        .tableStyle(.inset)
        .onChange(of: viewModel.sortOrder) { _, _ in
            viewModel.loadFiles()
        }
        .onKeyPress(.return) {
            if let selectedID = selectedFileID,
               let file = viewModel.files.first(where: { $0.id == selectedID }) {
                viewModel.navigateTo(file)
                return .handled
            }
            return .ignored
        }
    }

    private var nameColumn: some TableColumnContent<FileItem, KeyPathComparator<FileItem>> {
        TableColumn("Имя", value: \.name) { file in
            TableRowView(file: file, viewModel: viewModel, selectedFileID: $selectedFileID) {
                FileNameView(
                    file: file,
                    isSelected: selectedFileID == file.id,
                    onSingleTap: {
                        selectedFileID = file.id
                    },
                    onDoubleTap: {
                        viewModel.navigateTo(file)
                    },
                    onRename: { newName in
                        viewModel.renameFile(file, to: newName)
                    }
                )
            }
        }
        .width(min: 200, ideal: 300)
    }

    private var sizeColumn: some TableColumnContent<FileItem, KeyPathComparator<FileItem>> {
        TableColumn("Размер", value: \.size) { file in
            TableRowView(file: file, viewModel: viewModel, selectedFileID: $selectedFileID) {
                Text(file.formattedSize)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .monospacedDigit()
                    .opacity(file.isHidden ? 0.7 : 1.0)
            }
        }
        .width(min: 80, ideal: 100)
    }

    private var dateColumn: some TableColumnContent<FileItem, KeyPathComparator<FileItem>> {
        TableColumn("Дата изменения", value: \.sortableDate) { file in
            TableRowView(file: file, viewModel: viewModel, selectedFileID: $selectedFileID) {
                Text(file.formattedDate)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .opacity(file.isHidden ? 0.7 : 1.0)
            }
        }
        .width(min: 150, ideal: 200)
    }

    private var typeColumn: some TableColumnContent<FileItem, KeyPathComparator<FileItem>> {
        TableColumn("Тип", value: \.fileType) { file in
            TableRowView(file: file, viewModel: viewModel, selectedFileID: $selectedFileID) {
                Text(file.fileType)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .opacity(file.isHidden ? 0.7 : 1.0)
            }
        }
        .width(min: 80, ideal: 100)
    }
}

