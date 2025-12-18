import Foundation
import SwiftUI
import AppKit


@MainActor
class FileBrowserViewModel: ObservableObject {
    @Published var currentDirectory: URL
    @Published var files: [FileItem] = []
    @Published var isLoading = false
    @Published var sortOrder: [KeyPathComparator<FileItem>] = [
        .init(\.name, order: .forward)
    ]
    @Published var selectedFileIDs: Set<FileItem.ID> = []

    private var history: [URL] = []
    private var currentHistoryIndex: Int = -1
    @Published var canNavigateBack: Bool = false
    @Published var canNavigateForward: Bool = false

    private let fileService = FileManagerService.shared

    init(initialPath: String? = nil) {
        let autocompleteService = PathAutocompleteService.shared

        if let path = initialPath, let url = autocompleteService.validatePath(path) {
            self.currentDirectory = url
            history.append(url)
            currentHistoryIndex = 0
        } else {
            let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
            self.currentDirectory = homeDirectory
            history.append(homeDirectory)
            currentHistoryIndex = 0
        }

        loadFiles()
    }

    func loadFiles() {
        isLoading = true
        let loadedFiles = fileService.getContents(of: currentDirectory)

        let directories = loadedFiles.filter { $0.isDirectory }
        let regularFiles = loadedFiles.filter { !$0.isDirectory }

        var sortedDirectories = directories
        var sortedFiles = regularFiles

        sortedDirectories.sort(using: sortOrder)
        sortedFiles.sort(using: sortOrder)

        files = sortedDirectories + sortedFiles
        isLoading = false
    }

    func navigateTo(_ fileItem: FileItem) {
        guard fileItem.isDirectory else { return }
        navigateToDirectory(fileItem.url)
    }

    private func navigateToDirectory(_ url: URL) {
        if url != currentDirectory {
            if currentHistoryIndex < history.count - 1 {
                history.removeSubrange((currentHistoryIndex + 1)...)
            }
            history.append(url)
            currentHistoryIndex = history.count - 1
            updateNavigationState()
            selectedFileIDs.removeAll()
        }
        currentDirectory = url
        loadFiles()
    }

    func navigateUp() {
        if let parent = fileService.getParentDirectory(of: currentDirectory) {
            navigateToDirectory(parent)
        }
    }

    func navigateBack() {
        guard canNavigateBack, currentHistoryIndex > 0 else { return }
        currentHistoryIndex -= 1
        let previousDirectory = history[currentHistoryIndex]
        currentDirectory = previousDirectory
        updateNavigationState()
        loadFiles()
    }

    func navigateForward() {
        guard canNavigateForward, currentHistoryIndex < history.count - 1 else { return }
        currentHistoryIndex += 1
        let nextDirectory = history[currentHistoryIndex]
        currentDirectory = nextDirectory
        updateNavigationState()
        loadFiles()
    }

    private func updateNavigationState() {
        canNavigateBack = currentHistoryIndex > 0
        canNavigateForward = currentHistoryIndex < history.count - 1
    }

    func canNavigateUp() -> Bool {
        return fileService.getParentDirectory(of: currentDirectory) != nil
    }

    func openFile(_ fileItem: FileItem) {
        if fileItem.isDirectory {
            navigateTo(fileItem)
        } else {
            fileService.openFile(at: fileItem.url)
        }
    }

    func copyFile(_ fileItem: FileItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([fileItem.url as NSPasteboardWriting])
    }

    func copyFileName(_ fileItem: FileItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(fileItem.name, forType: .string)
    }

    func copyFilePath(_ fileItem: FileItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(fileItem.url.path, forType: .string)
    }

    func copyFileNameWithPath(_ fileItem: FileItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString("\(fileItem.name) (\(fileItem.url.path))", forType: .string)
    }

    func deleteFile(_ fileItem: FileItem) {
        do {
            try fileService.deleteFile(at: fileItem.url)
            loadFiles()
        } catch {
            print("Ошибка удаления файла: \(error)")
        }
    }

    func navigateToPath(_ path: String) {
        let autocompleteService = PathAutocompleteService.shared
        if let url = autocompleteService.validatePath(path) {
            navigateToDirectory(url)
        } else {
            print("Неверный путь: \(path)")
        }
    }

    func renameFile(_ fileItem: FileItem, to newName: String) {
        do {
            try fileService.renameFile(at: fileItem.url, to: newName)
            loadFiles()
        } catch {
            print("Ошибка переименования файла: \(error)")
        }
    }

    func handleDrop(providers: [NSItemProvider]) -> Bool {
        var hasValidFiles = false
        let group = DispatchGroup()

        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                hasValidFiles = true
                group.enter()
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (data, error) in
                    defer { group.leave() }

                    if let error = error {
                        print("Ошибка загрузки файла: \(error)")
                        return
                    }

                    if let data = data as? Data,
                       let urlString = String(data: data, encoding: .utf8) {
                        let urlStrings = urlString.components(separatedBy: "\n").filter { !$0.isEmpty }

                        for urlString in urlStrings {
                            guard let sourceURL = URL(string: urlString) else { continue }

                            Task { @MainActor in
                                do {
                                    try self.fileService.moveFile(at: sourceURL, to: self.currentDirectory)
                                } catch {
                                    print("Ошибка перемещения файла \(sourceURL.lastPathComponent): \(error)")
                                }
                            }
                        }
                    } else if let url = data as? URL {
                        Task { @MainActor in
                            do {
                                try self.fileService.moveFile(at: url, to: self.currentDirectory)
                            } catch {
                                print("Ошибка перемещения файла \(url.lastPathComponent): \(error)")
                            }
                        }
                    }
                }
            }
        }

        group.notify(queue: .main) {
            self.loadFiles()
        }

        return hasValidFiles
    }

    func createFile(name: String) {
        do {
            try fileService.createFile(at: currentDirectory, name: name)
            loadFiles()
        } catch {
            print("Ошибка создания файла: \(error)")
        }
    }

    func createDirectory(name: String) {
        do {
            try fileService.createDirectory(at: currentDirectory, name: name)
            loadFiles()
        } catch {
            print("Ошибка создания директории: \(error)")
        }
    }

    func openTerminal() {
        fileService.openTerminal(at: currentDirectory)
    }

    func openInNewWindow(_ fileItem: FileItem) {
        guard fileItem.isDirectory else { return }
        WindowManager.shared.openWindow(at: fileItem.url.path, reuseExisting: false)
    }

    func deleteSelectedFiles() {
        for fileID in selectedFileIDs {
            if let file = files.first(where: { $0.id == fileID }) {
                deleteFile(file)
            }
        }
        selectedFileIDs.removeAll()
    }

    func copySelectedFiles() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        let urls = selectedFileIDs.compactMap { id in
            files.first(where: { $0.id == id })?.url
        }
        pasteboard.writeObjects(urls as [NSPasteboardWriting])
    }

    func pasteFiles() {
        let pasteboard = NSPasteboard.general
        guard let items = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] else {
            return
        }

        for sourceURL in items {
            do {
                try fileService.copyFile(at: sourceURL, to: currentDirectory)
            } catch {
                print("Ошибка копирования файла \(sourceURL.lastPathComponent): \(error)")
            }
        }
        loadFiles()
    }

}

