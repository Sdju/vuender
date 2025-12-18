import SwiftUI

struct PathInputView: View {
    @ObservedObject var viewModel: FileBrowserViewModel
    @State private var isEditing = false
    @State private var inputText = ""
    @State private var suggestions: [String] = []
    @State private var selectedSuggestionIndex: Int = -1
    @State private var activeDropdownIndex: Int? = nil
    @FocusState private var isFocused: Bool

    private let autocompleteService = PathAutocompleteService.shared

    var body: some View {
        Group {
            if isEditing {
                editingView
            } else {
                displayView
            }
        }
        .background {
            if !isEditing, activeDropdownIndex != nil {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        activeDropdownIndex = nil
                    }
            }
        }
        .background(alignment: .topLeading) {
            if !isEditing, let dropdownIndex = activeDropdownIndex {
                let segments = PathSegmentHelper.pathSegments(from: viewModel.currentDirectory.path)
                let targetSegmentIndex = dropdownIndex + 1
                if targetSegmentIndex < segments.count {
                    let targetSegment = segments[targetSegmentIndex]
                    PathDropdownMenu(
                        alternatives: PathSegmentHelper.getSiblingDirectories(for: targetSegment.fullPath),
                        onSelect: { selectedPath in
                            viewModel.navigateToPath(selectedPath)
                            activeDropdownIndex = nil
                        },
                        onDismiss: {
                            activeDropdownIndex = nil
                        }
                    )
                    .padding(.top, 32)
                    .padding(.leading, CGFloat(dropdownIndex * 70 + 10))
                    .zIndex(1000)
                }
            }
        }
    }

    private var displayView: some View {
        PathBreadcrumbView(
            path: viewModel.currentDirectory.path,
            onNavigate: { path in
                viewModel.navigateToPath(path)
            },
            onEditRequest: {
                startEditing()
            },
            activeDropdownIndex: $activeDropdownIndex
        )
    }

    private var editingView: some View {
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
            .onKeyPress(.tab) {
                if !suggestions.isEmpty {
                    let indexToUse = selectedSuggestionIndex >= 0 ? selectedSuggestionIndex : 0
                    if indexToUse < suggestions.count {
                        inputText = suggestions[indexToUse]
                        updateSuggestions(for: inputText)
                        selectedSuggestionIndex = -1
                    }
                    return .handled
                }
                return .ignored
            }
            .overlay(alignment: .topLeading) {
                if !suggestions.isEmpty {
                    PathAutocompleteView(
                        suggestions: suggestions,
                        selectedIndex: selectedSuggestionIndex
                    ) { selectedPath in
                        inputText = selectedPath
                        navigateToPath(selectedPath)
                    }
                    .padding(.top, 32)
                    .frame(maxWidth: 500)
                    .zIndex(1000)
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

