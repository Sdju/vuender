import SwiftUI

struct FileNameView: View {
    let file: FileItem
    let isSelected: Bool
    let onSingleTap: () -> Void
    let onDoubleTap: () -> Void
    let onRename: (String) -> Void

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
                    // Двойной клик - навигация (отменяет переименование)
                    pendingRename = false
                    isRenaming = false
                    onDoubleTap()
                }
                .onTapGesture(count: 1) {
                    // Одинарный клик по уже выделенному элементу - переименование
                    if isSelected {
                        // Небольшая задержка, чтобы отличить от двойного клика
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
            }
        }
    }
}
