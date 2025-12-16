import Foundation
import SwiftUI


@MainActor
class FileBrowserViewModel: ObservableObject {
    @Published var currentDirectory: URL
    @Published var files: [FileItem] = []
    @Published var isLoading = false
    @Published var sortOrder: [KeyPathComparator<FileItem>] = [
        .init(\.name, order: .forward)
    ]
    
    private let fileService = FileManagerService.shared
    
    init() {
        // Начинаем с домашней директории пользователя
        self.currentDirectory = FileManager.default.homeDirectoryForCurrentUser
        loadFiles()
    }
    
    func loadFiles() {
        isLoading = true
        let loadedFiles = fileService.getContents(of: currentDirectory)
        
        // Сначала разделяем папки и файлы
        let directories = loadedFiles.filter { $0.isDirectory }
        let regularFiles = loadedFiles.filter { !$0.isDirectory }
        
        // Сортируем каждую группу отдельно
        var sortedDirectories = directories
        var sortedFiles = regularFiles
        
        // Применяем сортировку к каждой группе
        sortedDirectories.sort(using: sortOrder)
        sortedFiles.sort(using: sortOrder)
        
        // Объединяем: сначала папки, потом файлы
        files = sortedDirectories + sortedFiles
        isLoading = false
    }
    
    func navigateTo(_ fileItem: FileItem) {
        guard fileItem.isDirectory else { return }
        currentDirectory = fileItem.url
        loadFiles()
    }
    
    func navigateUp() {
        if let parent = fileService.getParentDirectory(of: currentDirectory) {
            currentDirectory = parent
            loadFiles()
        }
    }
    
    func canNavigateUp() -> Bool {
        return fileService.getParentDirectory(of: currentDirectory) != nil
    }
}

