import SwiftUI

struct TableRowView: View {
    let file: FileItem
    let viewModel: FileBrowserViewModel
    let content: AnyView
    @Binding private var selectedFileID: FileItem.ID?

    init<Content: View>(file: FileItem, viewModel: FileBrowserViewModel, selectedFileID: Binding<FileItem.ID?>, @ViewBuilder content: () -> Content) {
        self.file = file
        self.viewModel = viewModel
        self.content = AnyView(content())
        _selectedFileID = selectedFileID
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                selectedFileID = file.id
            }
            .highPriorityGesture(
                TapGesture(count: 2).onEnded {
                    viewModel.navigateTo(file)
                }
            )
    }
}

