import SwiftUI

struct FileNameView: View {
    let file: FileItem
    let isSelected: Bool
    let onSingleTap: () -> Void
    let onDoubleTap: () -> Void
    let onRename: (String) -> Void
    @Binding var forceRename: Bool

    @State private var isRenaming = false
    @State private var pendingRename = false

    var body: some View {
        Group {
            if isRenaming {
                FileRenameView(
                    file: file,
                    onRename: { newName in
                        onRename(newName)
                        isRenaming = false
                    },
                    onCancel: {
                        isRenaming = false
                    }
                )
            } else {
                HStack {
                    Image(systemName: file.isDirectory ? "folder.fill" : "doc.fill")
                        .foregroundColor(file.isDirectory ? .blue : .gray)
                        .frame(width: 16)

                    Text(file.name)
                        .font(.system(size: 13))
                }
                .opacity(file.isHidden ? 0.7 : 1.0)
                .contentShape(Rectangle())
                .onTapGesture(count: 2) {
                    pendingRename = false
                    isRenaming = false
                    onDoubleTap()
                }
                .onTapGesture(count: 1) {
                    if isSelected {
                        pendingRename = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            if pendingRename && isSelected && !isRenaming {
                                isRenaming = true
                                pendingRename = false
                            }
                        }
                    } else {
                        onSingleTap()
                    }
                }
                .onChange(of: forceRename) { oldValue, newValue in
                    if newValue && isSelected && !oldValue {
                        isRenaming = true
                        forceRename = false
                    }
                }
            }
        }
    }
}
