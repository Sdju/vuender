import SwiftUI

struct FileContextMenu: View {
    let file: FileItem
    let viewModel: FileBrowserViewModel

    var body: some View {
        Group {
            Button("Открыть") {
                viewModel.openFile(file)
            }

            if file.isDirectory {
                Button("Открыть в новом окне") {
                    viewModel.openInNewWindow(file)
                }
            }

            Divider()

            Menu("Скопировать") {
                Button("Имя") {
                    viewModel.copyFileName(file)
                }
                Button("Файл") {
                    viewModel.copyFile(file)
                }
                Button("Путь") {
                    viewModel.copyFilePath(file)
                }
                Button("Имя с путём") {
                    viewModel.copyFileNameWithPath(file)
                }
            }

            Divider()

            Button("Удалить") {
                viewModel.deleteFile(file)
            }
            .foregroundColor(.red)
        }
    }
}

