import SwiftUI

struct PathInputView: View {
    @ObservedObject var viewModel: FileBrowserViewModel
    @State private var isEditing = false
    @State private var inputText = ""
    @State private var suggestions: [String] = []
    @FocusState private var isFocused: Bool
    
    private let autocompleteService = PathAutocompleteService.shared
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            if isEditing {
                editingView
            } else {
                displayView
            }
        }
    }
    
    private var displayView: some View {
        Text(viewModel.currentDirectory.path)
            .font(.system(size: 12))
            .foregroundColor(.secondary)
            .lineLimit(1)
            .truncationMode(.middle)
            .contentShape(Rectangle())
            .onTapGesture {
                startEditing()
            }
    }
    
    private var editingView: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField("Введите путь", text: $inputText)
                .textFieldStyle(.plain)
                .font(.system(size: 12, design: .monospaced))
                .padding(4)
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(4)
                .focused($isFocused)
                .onChange(of: inputText) { _, newValue in
                    updateSuggestions(for: newValue)
                }
                .onSubmit {
                    navigateToPath()
                }
                .onKeyPress(.escape) {
                    cancelEditing()
                    return .handled
                }
            
            if !suggestions.isEmpty {
                PathAutocompleteView(suggestions: suggestions) { selectedPath in
                    inputText = selectedPath
                    navigateToPath(selectedPath)
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: 500)
        .onAppear {
            isFocused = true
            inputText = viewModel.currentDirectory.path
        }
    }
    
    private func startEditing() {
        isEditing = true
        inputText = viewModel.currentDirectory.path
        suggestions = []
    }
    
    private func cancelEditing() {
        isEditing = false
        inputText = ""
        suggestions = []
    }
    
    private func updateSuggestions(for text: String) {
        suggestions = autocompleteService.autocomplete(text)
    }
    
    private func navigateToPath(_ path: String? = nil) {
        let pathToNavigate = path ?? inputText
        viewModel.navigateToPath(pathToNavigate)
        cancelEditing()
    }
}

