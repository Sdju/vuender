import SwiftUI

struct FileNameView: View {
    let file: FileItem
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: file.isDirectory ? "folder.fill" : "doc.fill")
                .foregroundColor(file.isDirectory ? .blue : .gray)
                .frame(width: 16)
            
            Text(file.name)
                .font(.system(size: 13))
        }
        .opacity(file.isHidden ? 0.7 : 1.0)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}