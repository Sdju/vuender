import SwiftUI

struct FileNameInputView: View {
    let placeholder: String
    let iconName: String
    let iconColor: Color
    let onSubmit: (String) -> Void
    let onCancel: () -> Void

    @State private var name: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack {
            Image(systemName: iconName)
                .foregroundColor(iconColor)
                .frame(width: 16)

            TextField(placeholder, text: $name)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .focused($isFocused)
                .onSubmit {
                    confirmCreate()
                }
                .onKeyPress(.escape) {
                    onCancel()
                    return .handled
                }
                .onAppear {
                    isFocused = true
                }
        }
    }

    private func confirmCreate() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        if !trimmedName.isEmpty {
            onSubmit(trimmedName)
        } else {
            onCancel()
        }
    }
}

