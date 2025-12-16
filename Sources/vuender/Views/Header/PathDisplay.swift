import SwiftUI

struct PathDisplay: View {
    let path: String
    
    var body: some View {
        Text(path)
            .font(.system(size: 12))
            .foregroundColor(.secondary)
            .lineLimit(1)
            .truncationMode(.middle)
    }
}

