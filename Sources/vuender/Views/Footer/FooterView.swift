import SwiftUI
import AppKit

struct FooterView: View {
    let totalItems: Int
    let selectedItems: Int
    @Binding var isTerminalVisible: Bool

    var body: some View {
        HStack {
            Text("\(totalItems) объектов")
                .font(.system(size: 11))
                .foregroundColor(.secondary)

            if selectedItems > 0 {
                Text("•")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                Text("\(selectedItems) выбрано")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: { isTerminalVisible.toggle() }) {
                Label(
                    isTerminalVisible ? "Скрыть терминал" : "Терминал",
                    systemImage: isTerminalVisible ? "chevron.down" : "chevron.up"
                )
                .font(.system(size: 11))
            }
            .buttonStyle(.link)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(NSColor.controlBackgroundColor))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(NSColor.separatorColor)),
            alignment: .top
        )
    }
}

