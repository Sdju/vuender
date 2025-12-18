import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct FileTableView: View {
    @ObservedObject var viewModel: FileBrowserViewModel
    @State private var lastSelectedIndex: Int?
    @State private var isShiftPressed = false
    @State private var isCommandPressed = false
    @State private var isProgrammaticChange = false
    @State private var isHandlingSelection = false
    @State private var creationMode: FileCreationMode = .none
    @State private var fileToRename: FileItem.ID? = nil
    @State private var newlyCreatedFileName: String? = nil

    var body: some View {
        ZStack {
            tableWithModifiers
        }
    }

    private var tableWithModifiers: some View {
        tableBase
            .background(
                KeyboardShortcutHandler(
                    viewModel: viewModel,
                    isCommandPressed: $isCommandPressed,
                    isShiftPressed: $isShiftPressed,
                    creationMode: $creationMode,
                    fileToRename: $fileToRename
                )
                .frame(width: 0, height: 0)
                .allowsHitTesting(false)
            )
    }

    private var tableBase: some View {
        Table(
            of: FileItem.self,
            selection: $viewModel.selectedFileIDs,
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

            if creationMode != .none {
                TableRow(createPlaceholderFileItem())
            }
        }
        .tableStyle(.inset)
        .contextMenu {
            EmptyAreaContextMenu(viewModel: viewModel, creationMode: $creationMode)
        }
        .onChange(of: viewModel.sortOrder) { _, _ in
            viewModel.loadFiles()
        }
        .onChange(of: viewModel.selectedFileIDs) { oldValue, newValue in
            if !isHandlingSelection && !isProgrammaticChange {
                isHandlingSelection = true
                handleSelectionChange(oldValue: oldValue, newValue: newValue)
                DispatchQueue.main.async {
                    self.isHandlingSelection = false
                }
            }
        }
        .onChange(of: viewModel.files) { oldFiles, newFiles in
            // Если был создан новый файл/папка, активируем режим переименования
            if let newFileName = newlyCreatedFileName {
                if let newFile = newFiles.first(where: { $0.name == newFileName }) {
                    // Проверяем, что файл действительно новый (не был в старом списке)
                    let wasInOldList = oldFiles.contains(where: { $0.id == newFile.id })
                    if !wasInOldList {
                        DispatchQueue.main.async {
                            fileToRename = newFile.id
                            newlyCreatedFileName = nil
                        }
                    }
                }
            }
        }
        .background(KeyPressHandler(
            onShiftChange: { isShiftPressed = $0 },
            onCommandChange: { isCommandPressed = $0 }
        ))
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            viewModel.handleDrop(providers: providers)
        }
        .onChange(of: creationMode) { oldValue, newValue in
            if newValue != .none {
                viewModel.selectedFileIDs.removeAll()
            }
        }
    }

    private func createPlaceholderFileItem() -> FileItem {
        let placeholderName = "__CREATING__\(UUID().uuidString)"
        let placeholderURL = viewModel.currentDirectory.appendingPathComponent(placeholderName)

        return FileItem(url: placeholderURL, resourceValues: nil)
    }

    private var nameColumn: some TableColumnContent<FileItem, KeyPathComparator<FileItem>> {
        TableColumn("Имя", value: \.name) { file in
            if creationMode != .none && file.name.hasPrefix("__CREATING__") {
                FileNameInputView(
                    placeholder: creationMode == .file ? "Имя файла" : "Имя директории",
                    iconName: creationMode == .file ? "doc.fill" : "folder.fill",
                    iconColor: creationMode == .file ? .gray : .blue,
                    onSubmit: { name in
                        newlyCreatedFileName = name
                        if creationMode == .file {
                            viewModel.createFile(name: name)
                        } else {
                            viewModel.createDirectory(name: name)
                        }
                        creationMode = .none
                    },
                    onCancel: {
                        creationMode = .none
                    }
                )
            } else {
                TableRowView(
                    file: file,
                    viewModel: viewModel,
                    selectedFileIDs: $viewModel.selectedFileIDs,
                    isShiftPressed: $isShiftPressed,
                    isCommandPressed: $isCommandPressed,
                    lastSelectedIndex: $lastSelectedIndex,
                    files: viewModel.files
                ) {
                    FileNameView(
                        file: file,
                        isSelected: viewModel.selectedFileIDs.contains(file.id),
                        onSingleTap: {},
                        onDoubleTap: {
                            viewModel.navigateTo(file)
                        },
                        onRename: { newName in
                            viewModel.renameFile(file, to: newName)
                        },
                        forceRename: Binding(
                            get: { fileToRename == file.id },
                            set: { if !$0 { fileToRename = nil } }
                        )
                    )
                }
            }
        }
        .width(min: 200, ideal: 300)
    }

    private var sizeColumn: some TableColumnContent<FileItem, KeyPathComparator<FileItem>> {
        TableColumn("Размер", value: \.size) { file in
            TableRowView(
                file: file,
                viewModel: viewModel,
                selectedFileIDs: $viewModel.selectedFileIDs,
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
                selectedFileIDs: $viewModel.selectedFileIDs,
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
                selectedFileIDs: $viewModel.selectedFileIDs,
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



