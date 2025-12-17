import SwiftUI
import SwiftTerm
import AppKit

struct SwiftTermView: NSViewRepresentable {
    @Binding var isRunning: Bool
    
    func makeNSView(context: Context) -> LocalProcessTerminalView {
        let terminalView = LocalProcessTerminalView(frame: .zero)
        context.coordinator.isRunningBinding = $isRunning
        terminalView.processDelegate = context.coordinator
        
        // Преобразуем словарь environment в массив строк формата "KEY=VALUE"
        let envArray = ProcessInfo.processInfo.environment.map { "\($0.key)=\($0.value)" }
        
        // Запуск zsh
        terminalView.startProcess(
            executable: "/bin/zsh",
            args: ["-l"],
            environment: envArray,
            execName: "zsh"
        )
        
        Task { @MainActor in
            isRunning = true
        }
        
        return terminalView
    }
    
    func updateNSView(_ nsView: LocalProcessTerminalView, context: Context) {
        // Обновление представления при необходимости
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, LocalProcessTerminalViewDelegate {
        var isRunningBinding: Binding<Bool>?
        
        nonisolated func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {
            // Терминал изменил размер - можно обновить UI при необходимости
        }
        
        nonisolated func setTerminalTitle(source: LocalProcessTerminalView, title: String) {
            // Заголовок терминала изменился - можно обновить UI при необходимости
        }
        
        nonisolated func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {
            // Рабочая директория изменилась - можно обновить UI при необходимости
        }
        
        nonisolated func processTerminated(source: TerminalView, exitCode: Int32?) {
            let binding = isRunningBinding
            Task { @MainActor in
                binding?.wrappedValue = false
            }
        }
    }
}

