import Foundation
import AppKit
import SwiftUI

@MainActor
final class WindowManager: ObservableObject {
    static let shared = WindowManager()

    private var windows: [String: NSWindow] = [:]

    private init() {}

    /// Открывает окно с указанным путем
    /// - Parameters:
    ///   - path: Путь к директории для открытия
    ///   - reuseExisting: Если true, использует существующее окно, если false - создает новое
    func openWindow(at path: String, reuseExisting: Bool = false) {
        let normalizedPath = normalizePath(path)

        if reuseExisting, let existingWindow = windows[normalizedPath] {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let encodedPath = normalizedPath.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? normalizedPath
        if let url = URL(string: "vuender://open/\(encodedPath)") {
            NSWorkspace.shared.open(url)
        }
    }

    func registerWindow(_ window: NSWindow, for path: String) {
        let normalizedPath = normalizePath(path)
        windows[normalizedPath] = window

        let normalizedPathForClosure = normalizedPath
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.windows.removeValue(forKey: normalizedPathForClosure)
            }
        }
    }

    private func normalizePath(_ path: String) -> String {
        let url: URL

        if path.hasPrefix("/") {
            url = URL(fileURLWithPath: path)
        } else {
            let currentDir = FileManager.default.currentDirectoryPath
            url = URL(fileURLWithPath: currentDir).appendingPathComponent(path)
        }

        guard let resolvedURL = try? FileManager.default.destinationOfSymbolicLink(atPath: url.path) else {
            return url.path
        }

        return resolvedURL
    }

    func getAllWindows() -> [NSWindow] {
        return Array(windows.values)
    }

    func hasWindow(for path: String) -> Bool {
        let normalizedPath = normalizePath(path)
        return windows[normalizedPath] != nil
    }
}

