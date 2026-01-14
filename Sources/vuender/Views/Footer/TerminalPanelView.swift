import SwiftUI
import AppKit

struct TerminalPanelView: View {
    let currentDirectory: URL
    let onDirectoryChange: @Sendable (URL) -> Void
    @State private var isRunning: Bool = false

    private var shellDisplayName: String {
        let shellPath = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        return URL(fileURLWithPath: shellPath).lastPathComponent
    }

    var body: some View {
        VStack(spacing: 8) {
            header
            SwiftTermView(
                isRunning: $isRunning,
                currentDirectory: currentDirectory,
                onDirectoryChange: onDirectoryChange,
                enableDebugLogs: true
            )
            .frame(minHeight: 150)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(4)
            .focusable()
        }
        .padding(10)
        .background(Color(NSColor.controlBackgroundColor))
    }

    private var header: some View {
        HStack(spacing: 8) {
            Label("Терминал (\(shellDisplayName))", systemImage: "terminal.fill")
                .font(.system(size: 12))
            if isRunning {
                Text("работает")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            } else {
                Text("остановлен")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }
}
