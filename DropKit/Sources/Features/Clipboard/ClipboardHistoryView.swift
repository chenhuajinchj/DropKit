import SwiftUI
import AppKit

struct ClipboardHistoryView: View {
    var monitor: ClipboardMonitor
    var onClose: (() -> Void)?

    @State private var showToast = false
    @State private var selectedItemId: UUID?
    @State private var showPreview = false
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // 拖动把手区域 + 关闭按钮
                ZStack {
                    WindowDragArea()
                        .frame(height: 12)

                    HStack {
                        Spacer()
                        Button {
                            onClose?()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.secondary)
                                .frame(width: 28, height: 28)
                                .background(Color.primary.opacity(0.1))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 8)
                        .padding(.top, 4)
                    }
                }

                // 搜索框
                headerView

                Divider()
                    .opacity(0.5)

                // 筛选器（也可拖动）
                filterBar
                    .background(WindowDragArea())

                Divider()
                    .opacity(0.5)

                // 内容区域
                if monitor.filteredItems.isEmpty {
                    emptyStateView
                } else {
                    itemsListView
                }
            }

            // Toast
            if showToast {
                VStack {
                    Spacer()
                    toastView
                        .padding(.bottom, 50)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // 预览弹层
            if showPreview, let itemId = selectedItemId,
               let item = monitor.items.first(where: { $0.id == itemId }) {
                previewOverlay(for: item)
            }
        }
        .frame(width: 380, height: 520)
        .onKeyPress(.space) {
            if selectedItemId != nil {
                showPreview.toggle()
                return .handled
            }
            return .ignored
        }
        .onKeyPress(keys: [.escape]) { _ in
            if showPreview {
                showPreview = false
                return .handled
            }
            return .ignored
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 10) {
            // 搜索框
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 13))

                TextField("搜索剪切板...", text: Binding(
                    get: { monitor.searchText },
                    set: { monitor.searchText = $0 }
                ))
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .focused($isSearchFocused)

                if !monitor.searchText.isEmpty {
                    Button {
                        monitor.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                }

                // 快捷键提示
                Text("⌘F")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Color.secondary.opacity(0.5), lineWidth: 1)
                    )
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.primary.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        HStack(spacing: 8) {
            ForEach(ClipboardFilterType.allCases, id: \.self) { filter in
                filterButton(for: filter)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private func filterButton(for filter: ClipboardFilterType) -> some View {
        let isSelected = monitor.selectedFilter == filter
        return Button {
            monitor.selectedFilter = filter
        } label: {
            HStack(spacing: 4) {
                if filter == .favorites {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.orange)
                }
                Text(filter.rawValue)
                    .font(.system(size: 12))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(isSelected ? Color.primary.opacity(0.1) : Color.clear)
            .foregroundStyle(isSelected ? .primary : .secondary)
            .fontWeight(isSelected ? .medium : .regular)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: emptyStateIcon)
                .font(.system(size: 48))
                .foregroundStyle(.primary.opacity(0.3))
            Text(emptyStateText)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateIcon: String {
        if !monitor.searchText.isEmpty {
            return "magnifyingglass"
        }
        switch monitor.selectedFilter {
        case .favorites: return "star"
        default: return "clipboard"
        }
    }

    private var emptyStateText: String {
        if !monitor.searchText.isEmpty {
            return "未找到匹配项"
        }
        switch monitor.selectedFilter {
        case .favorites: return "暂无收藏"
        default: return "暂无剪切板历史"
        }
    }

    // MARK: - Items List

    private var itemsListView: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(monitor.filteredItems) { item in
                    ClipboardItemRow(
                        item: item,
                        isSelected: selectedItemId == item.id,
                        onSelect: {
                            selectedItemId = item.id
                        },
                        onCopy: {
                            copyItem(item)
                        },
                        onCopyAsPlainText: {
                            copyItemAsPlainText(item)
                        },
                        onDelete: {
                            monitor.removeItem(item)
                        },
                        onToggleFavorite: {
                            monitor.toggleFavorite(item)
                        }
                    )
                }
            }
            .padding(8)
        }
    }

    // MARK: - Footer

    private var footerView: some View {
        Text("按 Space 预览 · 按 Enter 复制")
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.primary.opacity(0.02))
    }

    // MARK: - Toast

    private var toastView: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text("已复制到剪切板")
                .font(.system(size: 12))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.regularMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
    }

    // MARK: - Preview Overlay

    private func previewOverlay(for item: ClipboardItem) -> some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    showPreview = false
                }

            VStack(spacing: 0) {
                // 标题栏
                HStack {
                    Text("内容预览")
                        .font(.system(size: 14, weight: .semibold))
                    Spacer()
                    // 空格键提示
                    Text("空格关闭")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.primary.opacity(0.05))

                // 内容区域 - 占满剩余空间
                ScrollView {
                    previewContent(for: item)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(12)
            }
            .frame(width: 340, height: 400)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
        }
    }

    @ViewBuilder
    private func previewContent(for item: ClipboardItem) -> some View {
        switch item.type {
        case .text:
            Text(item.content)
                .font(.system(size: 13))
                .textSelection(.enabled)
        case .html:
            Text(ClipboardItem.stripHTMLTags(from: item.content))
                .font(.system(size: 13))
                .textSelection(.enabled)
        case .file:
            if item.isImageFile,
               let nsImage = NSImage(contentsOfFile: item.content) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text(URL(fileURLWithPath: item.content).lastPathComponent)
                        .font(.system(size: 14, weight: .medium))
                    Text(item.content)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }
        case .image:
            if !item.content.isEmpty,
               let nsImage = NSImage(contentsOfFile: item.content) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack {
                    Image(systemName: "photo")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                    Text("图片不可用")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Actions

    private func copyItem(_ item: ClipboardItem) {
        monitor.copyToClipboard(item)
        withAnimation(.easeInOut(duration: 0.2)) {
            showToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showToast = false
            }
        }
    }

    private func copyItemAsPlainText(_ item: ClipboardItem) {
        monitor.copyAsPlainText(item)
        withAnimation(.easeInOut(duration: 0.2)) {
            showToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showToast = false
            }
        }
    }
}

// MARK: - ClipboardItemRow

struct ClipboardItemRow: View {
    let item: ClipboardItem
    let isSelected: Bool
    let onSelect: () -> Void
    let onCopy: () -> Void
    let onCopyAsPlainText: () -> Void
    let onDelete: () -> Void
    let onToggleFavorite: () -> Void

    @State private var isHovered = false
    @State private var showCopied = false
    @State private var cachedThumbnail: NSImage?

    var body: some View {
        HStack(spacing: 12) {
            // 左侧缩略图（图片类型或图片文件）
            if item.isImageFile {
                Group {
                    if let thumbnail = cachedThumbnail {
                        Image(nsImage: thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Color.gray.opacity(0.2)
                    }
                }
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            // 中间内容
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    if item.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.orange)
                    }
                    Text(item.displayText)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .font(.system(size: 13))
                        .foregroundStyle(.primary)
                }

                // 元信息：类型 · 时间
                HStack(spacing: 6) {
                    Text(item.type.rawValue)
                    Text("·")
                    Text(item.relativeTime)
                }
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            }

            Spacer()

            // 右侧悬停按钮组
            if isHovered {
                HStack(spacing: 8) {
                    // 复制按钮
                    Button {
                        showCopied = true
                        onCopy()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            showCopied = false
                        }
                    } label: {
                        Image(systemName: showCopied ? "checkmark.circle.fill" : "doc.on.doc")
                            .font(.system(size: 14))
                            .foregroundStyle(showCopied ? .green : .secondary)
                    }
                    .buttonStyle(.plain)

                    // 纯文本复制按钮（仅 HTML 类型显示）
                    if item.type == .html {
                        Button {
                            onCopyAsPlainText()
                        } label: {
                            Image(systemName: "textformat")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("复制为纯文本")
                    }

                    // 收藏按钮
                    Button {
                        onToggleFavorite()
                    } label: {
                        Image(systemName: item.isFavorite ? "star.fill" : "star")
                            .font(.system(size: 14))
                            .foregroundStyle(item.isFavorite ? .orange : .secondary)
                    }
                    .buttonStyle(.plain)

                    // 删除按钮
                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
            if hovering {
                onSelect()
            }
        }
        .onTapGesture {
            onSelect()
        }
        .onAppear {
            if item.isImageFile, cachedThumbnail == nil {
                ThumbnailCache.shared.thumbnail(for: item.content) { image in
                    cachedThumbnail = image
                }
            }
        }
    }
}

// MARK: - Window Drag Area

struct WindowDragArea: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = WindowDragView()
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

class WindowDragView: NSView {
    override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }

    override func mouseDragged(with event: NSEvent) {
        window?.performDrag(with: event)
    }
}
