import SwiftUI
import AppKit

struct TerminalPanelView: View {
    @State private var isRunning: Bool = false

    var body: some View {
        VStack(spacing: 8) {
            header
            SwiftTermView(isRunning: $isRunning)
                .frame(minHeight: 150)
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(4)
        }
        .padding(10)
        .background(Color(NSColor.controlBackgroundColor))
    }

    private var header: some View {
        HStack(spacing: 8) {
            Label("Терминал (zsh)", systemImage: "terminal.fill")
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


