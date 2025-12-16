import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = FileBrowserViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            navigationBar
            Divider()
            fileTable
        }
        .frame(minWidth: 800, minHeight: 500)
    }
    
    private var navigationBar: some View {
        HStack {
            Button(action: {
                viewModel.navigateUp()
            }) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 16))
            }
            .disabled(!viewModel.canNavigateUp())
            .buttonStyle(.bordered)
            
            Text(viewModel.currentDirectory.path)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
            
            Spacer()
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    @ViewBuilder
    private var fileTable: some View {
        if viewModel.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.files.isEmpty {
            VStack {
                Text("Папка пуста")
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
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
        }
        .width(min: 80, ideal: 100)
    }
    
    private var dateColumn: some TableColumnContent<FileItem, KeyPathComparator<FileItem>> {
        TableColumn("Дата изменения", value: \.sortableDate) { file in
            Text(file.formattedDate)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .width(min: 150, ideal: 200)
    }
    
    private var typeColumn: some TableColumnContent<FileItem, KeyPathComparator<FileItem>> {
        TableColumn("Тип", value: \.fileType) { file in
            Text(file.fileType)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .width(min: 80, ideal: 100)
    }
}

struct FileNameView: View {
    let file: FileItem
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: file.isDirectory ? "folder.fill" : "doc.fill")
                .foregroundColor(file.isDirectory ? .blue : .gray)
                .frame(width: 16)
            
            Text(file.name)
                .font(.system(size: 13))
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

