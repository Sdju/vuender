import SwiftUI
import AppKit

struct TableRowView: View {
    let file: FileItem
    let viewModel: FileBrowserViewModel
    let content: AnyView
    @Binding private var selectedFileIDs: Set<FileItem.ID>
    @Binding private var isShiftPressed: Bool
    @Binding private var isCommandPressed: Bool
    @Binding private var lastSelectedIndex: Int?
    let files: [FileItem]

    private var fileIndex: Int? {
        files.firstIndex(where: { $0.id == file.id })
    }

    init<Content: View>(
        file: FileItem,
        viewModel: FileBrowserViewModel,
        selectedFileIDs: Binding<Set<FileItem.ID>>,
        isShiftPressed: Binding<Bool>,
        isCommandPressed: Binding<Bool>,
        lastSelectedIndex: Binding<Int?>,
        files: [FileItem],
        @ViewBuilder content: () -> Content
    ) {
        self.file = file
        self.viewModel = viewModel
        self.content = AnyView(content())
        _selectedFileIDs = selectedFileIDs
        _isShiftPressed = isShiftPressed
        _isCommandPressed = isCommandPressed
        _lastSelectedIndex = lastSelectedIndex
        self.files = files
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                handleTap()
            }
            .highPriorityGesture(
                TapGesture(count: 2).onEnded {
                    viewModel.navigateTo(file)
                }
            )
            .onDrag {
                createDragProvider()
            }
    }

    private func createDragProvider() -> NSItemProvider {
        let filesToDrag: [FileItem]
        if selectedFileIDs.contains(file.id) && selectedFileIDs.count > 1 {
            filesToDrag = files.filter { selectedFileIDs.contains($0.id) }
        } else {
            filesToDrag = [file]
        }

        let urls = filesToDrag.map { $0.url }

        let provider = NSItemProvider()

        if let firstURL = urls.first {
            provider.registerDataRepresentation(forTypeIdentifier: "public.file-url", visibility: .all) { completion in
                if let data = firstURL.absoluteString.data(using: .utf8) {
                    completion(data, nil)
                } else {
                    completion(nil, NSError(domain: "TableRowView", code: 1))
                }
                return nil
            }
        }

        let pasteboardWriter = FileItemPasteboardWriter(urls: urls)
        provider.registerObject(pasteboardWriter, visibility: .all)

        return provider
    }

    private func handleTap() {
        guard let currentIndex = fileIndex else { return }

        let isCurrentlySelected = selectedFileIDs.contains(file.id)

        if isCurrentlySelected && !isShiftPressed && !isCommandPressed {
            return
        }

        if isShiftPressed {
            if let lastIndex = lastSelectedIndex {
                let range = lastIndex < currentIndex ? lastIndex...currentIndex : currentIndex...lastIndex
                var newSelection = isCommandPressed ? selectedFileIDs : Set<FileItem.ID>()

                for index in range {
                    newSelection.insert(files[index].id)
                }

                selectedFileIDs = newSelection
            } else {
                selectedFileIDs = [file.id]
                lastSelectedIndex = currentIndex
            }
        } else if isCommandPressed {
            if isCurrentlySelected {
                selectedFileIDs.remove(file.id)
                if lastSelectedIndex == currentIndex {
                    if let firstSelectedID = selectedFileIDs.first,
                       let newAnchorIndex = files.firstIndex(where: { $0.id == firstSelectedID }) {
                        lastSelectedIndex = newAnchorIndex
                    } else {
                        lastSelectedIndex = nil
                    }
                }
            } else {
                selectedFileIDs.insert(file.id)
                lastSelectedIndex = currentIndex
            }
        } else {
            selectedFileIDs = [file.id]
            lastSelectedIndex = currentIndex
        }
    }
}

