import SwiftUI
import AppKit

struct FileTableView: View {
    @ObservedObject var viewModel: FileBrowserViewModel
    @State private var selectedFileIDs: Set<FileItem.ID> = []
    @State private var lastSelectedIndex: Int?
    @State private var isShiftPressed = false
    @State private var isCommandPressed = false
    @State private var isProgrammaticChange = false

    var body: some View {
        Table(
            of: FileItem.self,
            selection: $selectedFileIDs,
            sortOrder: $viewModel.sortOrder,
        ) {
            nameColumn
            sizeColumn
            dateColumn
            typeColumn
        } rows: {
            ForEach(Array(viewModel.files.enumerated()), id: \.element.id) { index, file in
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
        .onChange(of: selectedFileIDs) { oldValue, newValue in
            if !isProgrammaticChange {
                handleSelectionChange(oldValue: oldValue, newValue: newValue)
            }
        }
        .onKeyPress(.return) {
            if let firstSelectedID = selectedFileIDs.first,
               let file = viewModel.files.first(where: { $0.id == firstSelectedID }) {
                viewModel.navigateTo(file)
                return .handled
            }
            return .ignored
        }
        .background(KeyPressHandler(
            onShiftChange: { isShiftPressed = $0 },
            onCommandChange: { isCommandPressed = $0 }
        ))
    }

    private var nameColumn: some TableColumnContent<FileItem, KeyPathComparator<FileItem>> {
        TableColumn("Имя", value: \.name) { file in
            TableRowView(
                file: file,
                viewModel: viewModel,
                selectedFileIDs: $selectedFileIDs,
                isShiftPressed: $isShiftPressed,
                isCommandPressed: $isCommandPressed,
                lastSelectedIndex: $lastSelectedIndex,
                files: viewModel.files
            ) {
                FileNameView(
                    file: file,
                    isSelected: selectedFileIDs.contains(file.id),
                    onSingleTap: {},
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
            TableRowView(
                file: file,
                viewModel: viewModel,
                selectedFileIDs: $selectedFileIDs,
                isShiftPressed: $isShiftPressed,
                isCommandPressed: $isCommandPressed,
                lastSelectedIndex: $lastSelectedIndex,
                files: viewModel.files
            ) {
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
            TableRowView(
                file: file,
                viewModel: viewModel,
                selectedFileIDs: $selectedFileIDs,
                isShiftPressed: $isShiftPressed,
                isCommandPressed: $isCommandPressed,
                lastSelectedIndex: $lastSelectedIndex,
                files: viewModel.files
            ) {
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
            TableRowView(
                file: file,
                viewModel: viewModel,
                selectedFileIDs: $selectedFileIDs,
                isShiftPressed: $isShiftPressed,
                isCommandPressed: $isCommandPressed,
                lastSelectedIndex: $lastSelectedIndex,
                files: viewModel.files
            ) {
                Text(file.fileType)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .opacity(file.isHidden ? 0.7 : 1.0)
            }
        }
        .width(min: 80, ideal: 100)
    }

    private func handleSelectionChange(oldValue: Set<FileItem.ID>, newValue: Set<FileItem.ID>) {
        if newValue.isEmpty {
            lastSelectedIndex = nil
            return
        }

        if !isShiftPressed && !isCommandPressed {
            if newValue.count == 1, let newID = newValue.first {
                if let currentIndex = viewModel.files.firstIndex(where: { $0.id == newID }) {
                    lastSelectedIndex = currentIndex
                }
            }
        }
    }
}

