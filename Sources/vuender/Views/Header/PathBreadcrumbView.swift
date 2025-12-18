import SwiftUI
import AppKit

/// Helper для работы с сегментами пути
struct PathSegmentHelper {
    static func pathSegments(from path: String) -> [(name: String, fullPath: String)] {
        var segments: [(name: String, fullPath: String)] = []
        let components = path.split(separator: "/").map(String.init)

        // Корневой сегмент
        segments.append((name: "/", fullPath: "/"))

        // Остальные сегменты
        for (index, component) in components.enumerated() {
            if !component.isEmpty {
                let fullPath = "/" + components[0...index].joined(separator: "/")
                segments.append((name: component, fullPath: fullPath))
            }
        }

        return segments
    }

    static func getSiblingDirectories(for path: String) -> [String] {
        let fileManager = FileManager.default
        let url = URL(fileURLWithPath: path)
        let parentURL = url.deletingLastPathComponent()

        do {
            let contents = try fileManager.contentsOfDirectory(
                at: parentURL,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )

            return contents
                .filter { url in
                    (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
                }
                .map { $0.path }
                .sorted()
        } catch {
            return []
        }
    }
}

/// Breadcrumb навигация как в Windows Explorer
struct PathBreadcrumbView: View {
    let path: String
    let onNavigate: (String) -> Void
    let onEditRequest: () -> Void
    @Binding var activeDropdownIndex: Int?

    @State private var eventMonitor: Any?

    var body: some View {
        HStack(spacing: 0) {
            // Разбиваем путь на сегменты
            let segments = PathSegmentHelper.pathSegments(from: path)

            ForEach(Array(segments.enumerated()), id: \.offset) { index, segment in
                // Кнопка сегмента пути
                PathSegmentButton(
                    title: segment.name,
                    isLast: index == segments.count - 1,
                    onTap: {
                        if index < segments.count - 1 {
                            onNavigate(segment.fullPath)
                        } else {
                            // Клик на последний сегмент (текущую папку) - включить редактирование
                            onEditRequest()
                        }
                    }
                )

                // Разделитель с dropdown (кроме последнего элемента)
                if index < segments.count - 1 {
                    PathSeparatorButton(
                        isActive: activeDropdownIndex == index,
                        onTap: {
                            if activeDropdownIndex == index {
                                activeDropdownIndex = nil
                            } else {
                                activeDropdownIndex = index
                            }
                        }
                    )
                }
            }

            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(4)
        .onChange(of: activeDropdownIndex) { _, newValue in
            if newValue != nil && eventMonitor == nil {
                // Dropdown открыт - добавляем монитор событий
                eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                    if event.keyCode == 53 { // 53 = Escape
                        activeDropdownIndex = nil
                        return nil // Поглощаем событие
                    }
                    return event
                }
            } else if newValue == nil && eventMonitor != nil {
                // Dropdown закрыт - удаляем монитор
                NSEvent.removeMonitor(eventMonitor!)
                eventMonitor = nil
            }
        }
        .onDisappear {
            // Очистка при уничтожении view
            if let monitor = eventMonitor {
                NSEvent.removeMonitor(monitor)
                eventMonitor = nil
            }
        }
    }
}

/// Кнопка сегмента пути
struct PathSegmentButton: View {
    let title: String
    let isLast: Bool
    let onTap: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(isLast ? .primary : (isHovered ? .blue : .secondary))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(isHovered ? Color.blue.opacity(0.1) : Color.clear)
                .cornerRadius(3)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

/// Кнопка разделителя
struct PathSeparatorButton: View {
    let isActive: Bool
    let onTap: () -> Void

    @State private var isHovered = false

    var body: some View {
        ZStack {
            // Увеличенная кликабельная область
            Rectangle()
                .fill(Color.clear)
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())

            // Видимая иконка
            Image(systemName: isActive ? "chevron.up" : "chevron.right")
                .font(.system(size: 8))
                .foregroundColor(isHovered ? .blue : .secondary)
                .frame(width: 16, height: 16)
        }
        .onTapGesture {
            onTap()
        }
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

/// Dropdown меню с альтернативными папками
struct PathDropdownMenu: View {
    let alternatives: [String]
    let onSelect: (String) -> Void
    let onDismiss: () -> Void

    @State private var hoveredPath: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Убрали ScrollView для отладки
            VStack(alignment: .leading, spacing: 0) {
                if alternatives.isEmpty {
                    Text("Нет доступных папок")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .padding(10)
                } else {
                    ForEach(alternatives.prefix(10), id: \.self) { altPath in
                        Button(action: {
                            onSelect(altPath)
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "folder.fill")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 12))

                                Text(URL(fileURLWithPath: altPath).lastPathComponent)
                                    .font(.system(size: 12))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Spacer()
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(hoveredPath == altPath ? Color.blue.opacity(0.2) : Color.clear)
                        }
                        .buttonStyle(.plain)
                        .onHover { hovering in
                            hoveredPath = hovering ? altPath : nil
                        }

                        if altPath != alternatives.last {
                            Divider()
                        }
                    }
                }
            }
            .padding(.bottom, 8)
        }
        .frame(width: 300)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

