import SwiftUI

struct FileContextMenu: View {
    let file: FileItem
    let viewModel: FileBrowserViewModel
    
    var body: some View {
        Group {
            Button("Открыть") {
                viewModel.openFile(file)
            }
            
            Divider()
            
            Button("Скопировать") {
                viewModel.copyFile(file)
            }
            
            Divider()
            
            Button("Удалить") {
                viewModel.deleteFile(file)
            }
            .foregroundColor(.red)
        }
    }
}

