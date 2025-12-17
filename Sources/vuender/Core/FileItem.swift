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
        self.isHidden = url.lastPathComponent.hasPrefix(".")
    }

    var formattedSize: String {
        if isDirectory {
            return "--"
        }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var formattedDate: String {
        guard let date = modificationDate else { return "--" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var sortableDate: Date {
        modificationDate ?? Date.distantPast
    }
}

