import SwiftUI
import AppKit

struct KeyboardShortcutHandler: NSViewRepresentable {
    @ObservedObject var viewModel: FileBrowserViewModel
    @Binding var isCommandPressed: Bool
    @Binding var isShiftPressed: Bool
    @Binding var creationMode: FileCreationMode
    @Binding var fileToRename: FileItem.ID?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(
            isCommandPressed: $isCommandPressed,
            isShiftPressed: $isShiftPressed,
            creationMode: $creationMode,
            fileToRename: $fileToRename
        )
    }
    
    func makeNSView(context: Context) -> NSView {
        let view = KeyboardHandlerView()
        view.viewModel = viewModel
        let coordinator = context.coordinator
        view.onCommandChange = { value in
            coordinator.isCommandPressed.wrappedValue = value
        }
        view.onShiftChange = { value in
            coordinator.isShiftPressed.wrappedValue = value
        }
        view.onCreateFile = {
            coordinator.creationMode.wrappedValue = .file
        }
        view.onCreateDirectory = {
            coordinator.creationMode.wrappedValue = .directory
        }
        view.onRename = { id in
            coordinator.fileToRename.wrappedValue = id
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        if let handlerView = nsView as? KeyboardHandlerView {
            handlerView.viewModel = viewModel
            handlerView.onCommandChange = { value in
                context.coordinator.isCommandPressed.wrappedValue = value
            }
            handlerView.onShiftChange = { value in
                context.coordinator.isShiftPressed.wrappedValue = value
            }
            handlerView.onCreateFile = {
                context.coordinator.creationMode.wrappedValue = .file
            }
            handlerView.onCreateDirectory = {
                context.coordinator.creationMode.wrappedValue = .directory
            }
            handlerView.onRename = { id in
                context.coordinator.fileToRename.wrappedValue = id
            }
        }
    }
    
    class Coordinator {
        var isCommandPressed: Binding<Bool>
        var isShiftPressed: Binding<Bool>
        var creationMode: Binding<FileCreationMode>
        var fileToRename: Binding<FileItem.ID?>
        
        init(
            isCommandPressed: Binding<Bool>,
            isShiftPressed: Binding<Bool>,
            creationMode: Binding<FileCreationMode>,
            fileToRename: Binding<FileItem.ID?>
        ) {
            self.isCommandPressed = isCommandPressed
            self.isShiftPressed = isShiftPressed
            self.creationMode = creationMode
            self.fileToRename = fileToRename
        }
    }
}

class KeyboardHandlerView: NSView {
    weak var viewModel: FileBrowserViewModel?
    var onCommandChange: ((Bool) -> Void)?
    var onShiftChange: ((Bool) -> Void)?
    var onCreateFile: (() -> Void)?
    var onCreateDirectory: (() -> Void)?
    var onRename: ((FileItem.ID) -> Void)?
    
    private var eventMonitor: Any?
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        
        guard let window = window else {
            if let monitor = eventMonitor {
                NSEvent.removeMonitor(monitor)
                eventMonitor = nil
            }
            return
        }
        
        // Используем локальный монитор для перехвата событий клавиатуры
        // Локальный монитор может перехватывать и блокировать события
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self, weak window] event in
            // Обрабатываем только если наше окно активно
            guard let window = window, (window.isKeyWindow || window.isMainWindow) else {
                return event
            }
            return self?.handleKeyEvent(event) ?? event
        }
    }
    
    override func viewWillMove(toWindow newWindow: NSWindow?) {
        super.viewWillMove(toWindow: newWindow)
        
        if newWindow == nil, let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
    
    private func handleKeyEvent(_ event: NSEvent) -> NSEvent? {
        guard let viewModel = viewModel,
              let window = window,
              (window.isKeyWindow || window.isMainWindow) else {
            return event
        }
        
        // Обновляем состояние модификаторов
        if event.type == .flagsChanged {
            let isCmd = event.modifierFlags.contains(.command)
            let isShift = event.modifierFlags.contains(.shift)
            onCommandChange?(isCmd)
            onShiftChange?(isShift)
            return event
        }
        
        guard event.type == .keyDown else { return event }
        
        // Проверяем, не находится ли пользователь в режиме редактирования текста
        if isEditingText(in: window) {
            // Если редактируется текст, пропускаем обработку Backspace и Enter
            let keyCode = event.keyCode
            if keyCode == 51 || keyCode == 117 || keyCode == 36 || keyCode == 76 {
                return event
            }
        }
        
        let isCmd = event.modifierFlags.contains(.command)
        let isShift = event.modifierFlags.contains(.shift)
        let keyCode = event.keyCode
        
        // Используем keyCode для более надежного определения клавиш
        // Key codes: O=31, N=45, C=8, V=9, R=15
        
        // Enter / Return (keyCode 36 или 76)
        if keyCode == 36 || keyCode == 76 {
            if !isCmd && !isShift {
                if let firstSelectedID = viewModel.selectedFileIDs.first,
                   let file = viewModel.files.first(where: { $0.id == firstSelectedID }) {
                    DispatchQueue.main.async {
                        viewModel.navigateTo(file)
                    }
                    return nil
                }
            }
        }
        
        // Delete / Backspace (keyCode 51 или 117)
        if keyCode == 51 || keyCode == 117 {
            if !isCmd {
                if !viewModel.selectedFileIDs.isEmpty {
                    DispatchQueue.main.async {
                        viewModel.deleteSelectedFiles()
                    }
                    return nil
                } else if keyCode == 51 {
                    DispatchQueue.main.async {
                        viewModel.navigateUp()
                    }
                    return nil
                }
            }
        }
        
        // Обрабатываем только если нажата Cmd
        guard isCmd else { return event }
        
        // Cmd+O - открыть файл (keyCode 31)
        if keyCode == 31 && !isShift {
            if let firstSelectedID = viewModel.selectedFileIDs.first,
               let file = viewModel.files.first(where: { $0.id == firstSelectedID }) {
                DispatchQueue.main.async {
                    viewModel.openFile(file)
                }
                return nil
            }
        }
        
        // Cmd+N - создать файл (keyCode 45)
        if keyCode == 45 && !isShift {
            DispatchQueue.main.async { [weak self] in
                self?.onCreateFile?()
            }
            return nil
        }
        
        // Cmd+Shift+N - создать директорию (keyCode 45)
        if keyCode == 45 && isShift {
            DispatchQueue.main.async { [weak self] in
                self?.onCreateDirectory?()
            }
            return nil
        }
        
        // Cmd+C - копировать (keyCode 8)
        if keyCode == 8 && !viewModel.selectedFileIDs.isEmpty {
            DispatchQueue.main.async {
                viewModel.copySelectedFiles()
            }
            return nil
        }
        
        // Cmd+V - вставить (keyCode 9)
        if keyCode == 9 {
            DispatchQueue.main.async {
                viewModel.pasteFiles()
            }
            return nil
        }
        
        // Cmd+R - переименовать (keyCode 15)
        if keyCode == 15 {
            if let firstSelectedID = viewModel.selectedFileIDs.first {
                DispatchQueue.main.async { [weak self] in
                    self?.onRename?(firstSelectedID)
                }
                return nil
            }
        }
        
        return event
    }
    
    override var acceptsFirstResponder: Bool {
        return false
    }
    
    /// Проверяет, находится ли пользователь в режиме редактирования текста
    private func isEditingText(in window: NSWindow) -> Bool {
        guard let firstResponder = window.firstResponder else {
            return false
        }
        
        // Проверяем, является ли first responder текстовым полем или текстовым view
        if firstResponder is NSTextView {
            return true
        }
        
        if let textField = firstResponder as? NSTextField {
            // Проверяем, что текстовое поле действительно редактируется
            return textField.isEditable && window.fieldEditor(false, for: textField) != nil
        }
        
        // Проверяем через responder chain
        var responder: NSResponder? = firstResponder
        while let current = responder {
            if current is NSTextView || current is NSTextField {
                return true
            }
            responder = current.nextResponder
        }
        
        return false
    }
}

