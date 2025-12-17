import Foundation
import AppKit
import OSLog

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
        if parent.path == url.path {
            return nil
        }
        return parent
    }

    func openFile(at url: URL) {
        workspace.open(url)
    }

    func copyFile(at sourceURL: URL, to destinationURL: URL) throws {
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

    func renameFile(at url: URL, to newName: String) throws {
        let parentDirectory = url.deletingLastPathComponent()
        let newURL = parentDirectory.appendingPathComponent(newName)

        guard !newName.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw NSError(domain: "FileManagerService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Имя файла не может быть пустым"])
        }

        if fileManager.fileExists(atPath: newURL.path) {
            throw NSError(domain: "FileManagerService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Файл с таким именем уже существует"])
        }

        try fileManager.moveItem(at: url, to: newURL)
    }

    func moveFile(at sourceURL: URL, to destinationDirectory: URL) throws {
        let fileName = sourceURL.lastPathComponent
        let destinationURL = destinationDirectory.appendingPathComponent(fileName)

        if sourceURL == destinationURL {
            return
        }

        if sourceURL.hasDirectoryPath {
            let sourcePath = sourceURL.path
            let destinationPath = destinationURL.path
            if destinationPath.hasPrefix(sourcePath) && destinationPath != sourcePath {
                throw NSError(domain: "FileManagerService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Нельзя переместить директорию внутрь самой себя"])
            }
        }

        var finalDestination = destinationURL
        var counter = 1
        while fileManager.fileExists(atPath: finalDestination.path) {
            let nameWithoutExtension = destinationURL.deletingPathExtension().lastPathComponent
            let extension_ = destinationURL.pathExtension
            let newName = extension_.isEmpty
                ? "\(nameWithoutExtension) copy \(counter)"
                : "\(nameWithoutExtension) copy \(counter).\(extension_)"
            finalDestination = destinationURL.deletingLastPathComponent().appendingPathComponent(newName)
            counter += 1
        }

        try fileManager.moveItem(at: sourceURL, to: finalDestination)
    }

    func createFile(at directory: URL, name: String) throws {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            throw NSError(domain: "FileManagerService", code: 4, userInfo: [NSLocalizedDescriptionKey: "Имя файла не может быть пустым"])
        }

        let fileURL = directory.appendingPathComponent(trimmedName)

        guard !fileManager.fileExists(atPath: fileURL.path) else {
            throw NSError(domain: "FileManagerService", code: 5, userInfo: [NSLocalizedDescriptionKey: "Файл с таким именем уже существует"])
        }

        fileManager.createFile(atPath: fileURL.path, contents: nil, attributes: nil)
    }

    func createDirectory(at directory: URL, name: String) throws {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            throw NSError(domain: "FileManagerService", code: 6, userInfo: [NSLocalizedDescriptionKey: "Имя директории не может быть пустым"])
        }

        let dirURL = directory.appendingPathComponent(trimmedName)

        guard !fileManager.fileExists(atPath: dirURL.path) else {
            throw NSError(domain: "FileManagerService", code: 7, userInfo: [NSLocalizedDescriptionKey: "Директория с таким именем уже существует"])
        }

        try fileManager.createDirectory(at: dirURL, withIntermediateDirectories: false, attributes: nil)
    }

    func openTerminal(at path: URL) {
        // Используем AppleScript для открытия Terminal с правильной директорией
        let escapedPath = path.path.replacingOccurrences(of: "'", with: "\\'")
        let script = """
        tell application "Terminal"
            activate
            do script "cd '\(escapedPath)'"
        end tell
        """

        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
            if let error = error {
                print("Ошибка открытия терминала: \(error)")
            }
        }
    }
}

