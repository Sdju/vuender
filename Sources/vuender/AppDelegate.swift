import AppKit
import SwiftUI

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)

        handleCommandLineArguments()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    private func createWindow(with path: String) {
        let contentView = ContentView(initialPath: path)
        let hostingController = NSHostingController(rootView: contentView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.contentViewController = hostingController
        window.title = "Vuender - \(path)"
        window.center()
        window.makeKeyAndOrderFront(nil)

        WindowManager.shared.registerWindow(window, for: path)

        NSApp.activate(ignoringOtherApps: true)
    }

    private func handleCommandLineArguments() {
        let arguments = CommandLine.arguments

        guard arguments.count > 1 else {
            return
        }

        var reuseExisting = false
        var paths: [String] = []

        for i in 1..<arguments.count {
            let arg = arguments[i]

            if arg == "--reuse" || arg == "-r" {
                reuseExisting = true
                continue
            }

            if arg.hasPrefix("-") {
                continue
            }

            paths.append(arg)
        }

        for path in paths {
            if reuseExisting && WindowManager.shared.hasWindow(for: path) {
                WindowManager.shared.openWindow(at: path, reuseExisting: true)
            } else {
                createWindow(with: path)
            }
        }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            if url.scheme == "vuender" {
                handleVuenderURL(url)
            } else if url.isFileURL {
                let path = url.path
                let directory: String

                var isDirectory: ObjCBool = false
                if FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) {
                    if isDirectory.boolValue {
                        directory = path
                    } else {
                        directory = (path as NSString).deletingLastPathComponent
                    }
                } else {
                    directory = path
                }

                createWindow(with: directory)
            }
        }
    }

    private func handleVuenderURL(_ url: URL) {
        var path: String?

        if url.pathComponents.count > 2 {
            let pathComponents = url.pathComponents.dropFirst(2)
            path = "/" + pathComponents.joined(separator: "/")
        } else if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let queryItems = components.queryItems,
                  let pathItem = queryItems.first(where: { $0.name == "path" }) {
            path = pathItem.value?.removingPercentEncoding
        }

        if let pathToOpen = path {
            createWindow(with: pathToOpen)
        }
    }
}

