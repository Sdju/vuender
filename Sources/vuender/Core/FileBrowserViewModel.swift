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

    init() {
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        self.currentDirectory = homeDirectory
        history.append(homeDirectory)
        currentHistoryIndex = 0
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
            // Проверяем, что провайдер может предоставить файл
            if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                hasValidFiles = true
                group.enter()
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (data, error) in
                    defer { group.leave() }

                    if let error = error {
                        print("Ошибка загрузки файла: \(error)")
                        return
                    }

                    // Обрабатываем данные
                    if let data = data as? Data,
                       let urlString = String(data: data, encoding: .utf8) {
                        // Может быть один URL или несколько, разделенных новой строкой
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
                        // Прямой URL объект
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

        // Обновляем список файлов после завершения всех операций
        group.notify(queue: .main) {
            self.loadFiles()
        }

        return hasValidFiles
    }
}

