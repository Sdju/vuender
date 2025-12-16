import SwiftUI

struct FileTableView: View {
    @ObservedObject var viewModel: FileBrowserViewModel

    var body: some View {
        Table(viewModel.files, selection: .constant(nil), sortOrder: $viewModel.sortOrder) {
            nameColumn
            sizeColumn
            dateColumn
            typeColumn
        }
        .tableStyle(.inset)
        .onChange(of: viewModel.sortOrder) { _, _ in
            viewModel.loadFiles()
        }
    }

    private var nameColumn: some TableColumnContent<FileItem, KeyPathComparator<FileItem>> {
        TableColumn("Имя", value: \.name) { file in
            FileNameView(file: file) {
                viewModel.navigateTo(file)
            }
        }
        .width(min: 200, ideal: 300)
    }

    private var sizeColumn: some TableColumnContent<FileItem, KeyPathComparator<FileItem>> {
        TableColumn("Размер", value: \.size) { file in
            Text(file.formattedSize)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .monospacedDigit()
                .opacity(file.isHidden ? 0.7 : 1.0)
        }
        .width(min: 80, ideal: 100)
    }

    private var dateColumn: some TableColumnContent<FileItem, KeyPathComparator<FileItem>> {
        TableColumn("Дата изменения", value: \.sortableDate) { file in
            Text(file.formattedDate)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .opacity(file.isHidden ? 0.7 : 1.0)
        }
        .width(min: 150, ideal: 200)
    }

    private var typeColumn: some TableColumnContent<FileItem, KeyPathComparator<FileItem>> {
        TableColumn("Тип", value: \.fileType) { file in
            Text(file.fileType)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .opacity(file.isHidden ? 0.7 : 1.0)
        }
        .width(min: 80, ideal: 100)
    }
}

