import Foundation

final class FileManagerService: @unchecked Sendable {
    static let shared = FileManagerService()
    private let fileManager = FileManager.default
    
    private init() {}
    
    func getContents(of directory: URL) -> [FileItem] {
        do {
            let keys: [URLResourceKey] = [
                .isDirectoryKey,
                .fileSizeKey,
                .contentModificationDateKey
            ]
            
            let urls = try fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: keys,
                options: [.skipsHiddenFiles]
            )
            
            return urls.compactMap { url -> FileItem? in
                let resourceValues = try? url.resourceValues(forKeys: Set(keys))
                return FileItem(url: url, resourceValues: resourceValues)
            }
        } catch {
            print("Ошибка чтения директории: \(error)")
            return []
        }
    }
    
    func getParentDirectory(of url: URL) -> URL? {
        let parent = url.deletingLastPathComponent()
        // Проверяем, что не поднялись выше корня
        if parent.path == url.path {
            return nil
        }
        return parent
    }
}

