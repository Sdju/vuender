import SwiftUI

enum FileCreationMode {
    case none
    case file
    case directory
}

struct EmptyAreaContextMenu: View {
    let viewModel: FileBrowserViewModel
    @Binding var creationMode: FileCreationMode
    
    var body: some View {
        Group {
            Button("Новый файл") {
                creationMode = .file
            }
            
            Button("Новая директория") {
                creationMode = .directory
            }
            
            Divider()
            
            Button("Терминал") {
                viewModel.openTerminal()
            }
        }
    }
}

