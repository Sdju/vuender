import SwiftUI

struct PathInputView: View {
    @ObservedObject var viewModel: FileBrowserViewModel
    @State private var isEditing = false
    @State private var inputText = ""
    @State private var suggestions: [String] = []
    @State private var selectedSuggestionIndex: Int = -1
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
                    selectedSuggestionIndex = -1
                }
                .onSubmit {
                    if selectedSuggestionIndex >= 0 && selectedSuggestionIndex < suggestions.count {
                        navigateToPath(suggestions[selectedSuggestionIndex])
                    } else {
                        navigateToPath()
                    }
                }
                .onKeyPress(.escape) {
                    cancelEditing()
                    return .handled
                }
                .onKeyPress(.downArrow) {
                    if !suggestions.isEmpty {
                        selectedSuggestionIndex = min(selectedSuggestionIndex + 1, suggestions.count - 1)
                        return .handled
                    }
                    return .ignored
                }
                .onKeyPress(.upArrow) {
                    if !suggestions.isEmpty {
                        selectedSuggestionIndex = max(selectedSuggestionIndex - 1, -1)
                        return .handled
                    }
                    return .ignored
                }
            
            if !suggestions.isEmpty {
                PathAutocompleteView(
                    suggestions: suggestions,
                    selectedIndex: selectedSuggestionIndex
                ) { selectedPath in
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
        selectedSuggestionIndex = -1
    }
    
    private func cancelEditing() {
        isEditing = false
        inputText = ""
        suggestions = []
        selectedSuggestionIndex = -1
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

