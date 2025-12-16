import Foundation

struct FileItem: Identifiable, Equatable {
    let id: URL
    let name: String
    let isDirectory: Bool
    let url: URL
    let size: Int64
    let modificationDate: Date?
    let fileType: String
    let isHidden: Bool
    
    init(url: URL, resourceValues: URLResourceValues?) {
        self.url = url
        self.id = url
        self.name = url.lastPathComponent
        self.isDirectory = resourceValues?.isDirectory ?? false
        self.size = Int64(resourceValues?.fileSize ?? 0)
        self.modificationDate = resourceValues?.contentModificationDate
        self.fileType = url.pathExtension.isEmpty ? (isDirectory ? "Папка" : "") : url.pathExtension.uppercased()
        // Файл считается скрытым, если его имя начинается с точки
        self.isHidden = url.lastPathComponent.hasPrefix(".")
    }
    
    // Форматированный размер файла
    var formattedSize: String {
        if isDirectory {
            return "--"
        }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    // Форматированная дата
    var formattedDate: String {
        guard let date = modificationDate else { return "--" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // Дата для сортировки (неопциональная)
    var sortableDate: Date {
        modificationDate ?? Date.distantPast
    }
}

