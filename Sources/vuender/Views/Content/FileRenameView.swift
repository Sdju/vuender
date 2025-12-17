import SwiftUI

struct FileRenameView: View {
    let file: FileItem
    let onRename: (String) -> Void
    let onCancel: () -> Void

    @State private var newName: String
    @FocusState private var isFocused: Bool

    init(file: FileItem, onRename: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
        self.file = file
        self.onRename = onRename
        self.onCancel = onCancel
        _newName = State(initialValue: file.name)
    }

    var body: some View {
        HStack {
            Image(systemName: file.isDirectory ? "folder.fill" : "doc.fill")
                .foregroundColor(file.isDirectory ? .blue : .gray)
                .frame(width: 16)

            TextField("", text: $newName)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .focused($isFocused)
                .onSubmit {
                    confirmRename()
                }
                .onKeyPress(.escape) {
                    onCancel()
                    return .handled
                }
                .onAppear {
                    isFocused = true
                }
        }
        .opacity(file.isHidden ? 0.7 : 1.0)
    }

    private func confirmRename() {
        let trimmedName = newName.trimmingCharacters(in: .whitespaces)
        if !trimmedName.isEmpty && trimmedName != file.name {
            onRename(trimmedName)
        } else {
            onCancel()
        }
    }
}

