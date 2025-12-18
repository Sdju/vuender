import SwiftUI
import SwiftTerm
import AppKit

struct SwiftTermView: NSViewRepresentable {
    @Binding var isRunning: Bool
    let currentDirectory: URL
    let onDirectoryChange: @Sendable (URL) -> Void
    let enableDebugLogs: Bool

    func makeNSView(context: Context) -> LocalProcessTerminalView {
        let terminalView = LocalProcessTerminalView(frame: .zero)
        terminalView.processDelegate = context.coordinator
        context.coordinator.terminalView = terminalView

        var envArray = ProcessInfo.processInfo.environment.map { "\($0.key)=\($0.value)" }
        envArray.append("TERM=xterm-256color")

        terminalView.startProcess(executable: "/bin/zsh", args: ["-l"], environment: envArray, execName: "zsh")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            context.coordinator.setupTerminal(currentDirectory: currentDirectory)
        }

        Task { @MainActor in
            isRunning = true
        }

        return terminalView
    }

    func updateNSView(_ nsView: LocalProcessTerminalView, context: Context) {
        if context.coordinator.currentDirectory != currentDirectory {
            context.coordinator.currentDirectory = currentDirectory
            context.coordinator.sendCdCommand(to: currentDirectory)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onDirectoryChange: onDirectoryChange, currentDirectory: currentDirectory, debugLogs: enableDebugLogs)
    }

    @MainActor
    class Coordinator: NSObject, LocalProcessTerminalViewDelegate {
        var isRunningBinding: Binding<Bool>?
        weak var terminalView: LocalProcessTerminalView?
        var currentDirectory: URL
        let onDirectoryChange: @Sendable (URL) -> Void
        let debugLogs: Bool
        private var lastSyncedDirectory: URL?
        private var lastTerminalDirectory: String?

        init(onDirectoryChange: @escaping @Sendable (URL) -> Void, currentDirectory: URL, debugLogs: Bool) {
            self.onDirectoryChange = onDirectoryChange
            self.currentDirectory = currentDirectory
            self.debugLogs = debugLogs
            super.init()
        }

        private func log(_ message: String) {
            if debugLogs {
                print("[Terminal] \(message)")
            }
        }

        func setupTerminal(currentDirectory: URL) {
            guard let terminalView = terminalView else { return }

            DispatchQueue.main.async { [weak self] in
                terminalView.send(source: terminalView, data: ArraySlice("bindkey '\\e[3~' delete-char\n".utf8))

                let osc7Setup = """
                if [[ -n "$TERM" ]] && [[ "$TERM" != "dumb" ]]; then
                    chpwd() {
                        print -n "\\033]7;file://$HOSTNAME$PWD\\033\\\\"
                    }
                    chpwd
                fi
                \n
                """
                terminalView.send(source: terminalView, data: ArraySlice(osc7Setup.utf8))
                terminalView.send(source: terminalView, data: ArraySlice("cd '\(currentDirectory.path)'\n".utf8))
                terminalView.send(source: terminalView, data: ArraySlice("clear\n".utf8))
                self?.lastSyncedDirectory = currentDirectory
                self?.log("Терминал настроен")
            }
        }

        func sendCdCommand(to url: URL) {
            guard let terminalView = terminalView, url != lastSyncedDirectory else { return }

            DispatchQueue.main.async { [weak self] in
                terminalView.send(source: terminalView, data: ArraySlice("cd '\(url.path)'\n".utf8))
                self?.lastSyncedDirectory = url
                self?.log("cd: \(url.path)")
            }
        }

        nonisolated func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {}

        nonisolated func setTerminalTitle(source: LocalProcessTerminalView, title: String) {}

        nonisolated func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {
            guard let directory = directory else { return }

            var path = directory
            if path.hasPrefix("file://") {
                path = String(path.dropFirst(7))
                if let hostEndIndex = path.firstIndex(of: "/") {
                    path = String(path[hostEndIndex...])
                }
            }

            guard let url = URL(fileURLWithPath: path, isDirectory: true) as URL? else { return }

            let capturedCallback = onDirectoryChange
            let shouldLog = debugLogs

            Task { @MainActor in
                if self.lastTerminalDirectory != directory {
                    if shouldLog {
                        print("[Terminal] OSC 7: \(directory) -> \(url.path)")
                    }
                    self.lastTerminalDirectory = directory
                    self.lastSyncedDirectory = url
                    capturedCallback(url)
                }
            }
        }

        nonisolated func processTerminated(source: TerminalView, exitCode: Int32?) {
            Task { @MainActor in
                self.isRunningBinding?.wrappedValue = false
            }
        }
    }
}
