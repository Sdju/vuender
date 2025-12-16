import Foundation
import AppKit

final class FileManagerService: @unchecked Sendable {
    static let shared = FileManagerService()
    private let fileManager = FileManager.default
    private let workspace = NSWorkspace.shared

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
                options: []
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

    func openFile(at url: URL) {
        workspace.open(url)
    }

    func copyFile(at sourceURL: URL, to destinationURL: URL) throws {
        // Если файл с таким именем уже существует, добавляем номер
        var finalDestination = destinationURL
        var counter = 1
        while fileManager.fileExists(atPath: finalDestination.path) {
            let nameWithoutExtension = destinationURL.deletingPathExtension().lastPathComponent
            let extension_ = destinationURL.pathExtension
            let newName = "\(nameWithoutExtension) copy \(counter).\(extension_)"
            finalDestination = destinationURL.deletingLastPathComponent().appendingPathComponent(newName)
            counter += 1
        }

        try fileManager.copyItem(at: sourceURL, to: finalDestination)
    }

    func deleteFile(at url: URL) throws {
        try fileManager.removeItem(at: url)
    }
}

