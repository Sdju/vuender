import Foundation

final class PathAutocompleteService: @unchecked Sendable {
    static let shared = PathAutocompleteService()
    private let fileManager = FileManager.default

    private init() {}

    func autocomplete(_ input: String) -> [String] {
        guard !input.isEmpty else { return [] }

        let trimmedInput = input.trimmingCharacters(in: .whitespaces)
        var baseURL: URL
        var searchTerm: String
        var isAbsolute = false

        // Обрабатываем разные форматы путей
        if trimmedInput.hasPrefix("/") {
            // Абсолютный путь
            isAbsolute = true
            let components = trimmedInput.split(separator: "/")
            if components.isEmpty {
                baseURL = URL(fileURLWithPath: "/")
                searchTerm = ""
            } else {
                // Находим существующую часть пути
                var existingPath = "/"
                var remainingComponents: [String] = []

                for component in components {
                    let testPath = existingPath + (existingPath == "/" ? "" : "/") + component
                    if fileManager.fileExists(atPath: testPath) {
                        existingPath = testPath
                    } else {
                        remainingComponents.append(String(component))
                        break
                    }
                }

                baseURL = URL(fileURLWithPath: existingPath)
                searchTerm = remainingComponents.joined(separator: "/")
            }
        } else if trimmedInput.hasPrefix("~") {
            // Путь с тильдой
            isAbsolute = true
            let homePath = fileManager.homeDirectoryForCurrentUser.path
            if trimmedInput == "~" {
                baseURL = fileManager.homeDirectoryForCurrentUser
                searchTerm = ""
            } else {
                let pathAfterTilde = String(trimmedInput.dropFirst())

                // Находим существующую часть
                var existingPath = homePath
                let components = pathAfterTilde.split(separator: "/")
                var remainingComponents: [String] = []

                for component in components {
                    let testPath = existingPath + "/" + component
                    if fileManager.fileExists(atPath: testPath) {
                        existingPath = testPath
                    } else {
                        remainingComponents.append(String(component))
                        break
                    }
                }

                baseURL = URL(fileURLWithPath: existingPath)
                searchTerm = remainingComponents.joined(separator: "/")
            }
        } else {
            // Относительный путь - используем домашнюю директорию как базу
            baseURL = fileManager.homeDirectoryForCurrentUser
            searchTerm = trimmedInput
        }

        // Получаем содержимое директории
        guard let directoryContents = try? fileManager.contentsOfDirectory(
            at: baseURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: []
        ) else {
            return []
        }

        // Фильтруем только директории и по поисковому запросу
        let lowerSearchTerm = searchTerm.lowercased()
        let matchingDirs = directoryContents
            .filter { url in
                var isDir: ObjCBool = false
                guard fileManager.fileExists(atPath: url.path, isDirectory: &isDir),
                      isDir.boolValue else { return false }

                if lowerSearchTerm.isEmpty {
                    return true
                }
                return url.lastPathComponent.lowercased().hasPrefix(lowerSearchTerm)
            }
            .prefix(10)

        // Формируем полные пути
        var suggestions: [String] = []
        for item in matchingDirs {
            let fullPath = item.path
            if isAbsolute || trimmedInput.hasPrefix("~") {
                suggestions.append(fullPath)
            } else {
                // Для относительных путей возвращаем только имя
                suggestions.append(item.lastPathComponent)
            }
        }

        return suggestions.sorted()
    }

    func validatePath(_ path: String) -> URL? {
        let trimmedPath = path.trimmingCharacters(in: .whitespaces)
        guard !trimmedPath.isEmpty else { return nil }

        var normalizedPath: String

        // Заменяем ~ на домашнюю директорию
        if trimmedPath.hasPrefix("~") {
            let homePath = fileManager.homeDirectoryForCurrentUser.path
            if trimmedPath == "~" {
                normalizedPath = homePath
            } else {
                normalizedPath = homePath + String(trimmedPath.dropFirst())
            }
        } else if trimmedPath.hasPrefix("/") {
            // Абсолютный путь
            normalizedPath = trimmedPath
        } else {
            // Относительный путь - относительно домашней директории
            let homePath = fileManager.homeDirectoryForCurrentUser.path
            normalizedPath = homePath + "/" + trimmedPath
        }

        // Нормализуем путь (убираем .. и .)
        let url = URL(fileURLWithPath: normalizedPath).standardizedFileURL
        var isDirectory: ObjCBool = false

        // Проверяем, существует ли путь и является ли он директорией
        if fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue {
            return url
        }

        return nil
    }
}

