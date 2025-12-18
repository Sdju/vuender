import AppKit
import UniformTypeIdentifiers

class FileItemPasteboardWriter: NSObject, NSItemProviderWriting {
    let urls: [URL]

    init(urls: [URL]) {
        self.urls = urls
    }

    static var writableTypeIdentifiersForItemProvider: [String] {
        return [UTType.fileURL.identifier]
    }

    func loadData(withTypeIdentifier typeIdentifier: String, forItemProviderCompletionHandler completionHandler: @escaping (Data?, Error?) -> Void) -> Progress? {
        if typeIdentifier == UTType.fileURL.identifier {
            if urls.count == 1, let url = urls.first {
                if let data = url.absoluteString.data(using: .utf8) {
                    completionHandler(data, nil)
                } else {
                    completionHandler(nil, NSError(domain: "FileItemPasteboardWriter", code: 1))
                }
            } else {
                let urlStrings = urls.map { $0.absoluteString }
                let data = urlStrings.joined(separator: "\n").data(using: .utf8)
                completionHandler(data, nil)
            }
        } else {
            completionHandler(nil, NSError(domain: "FileItemPasteboardWriter", code: 2))
        }
        return nil
    }
}

