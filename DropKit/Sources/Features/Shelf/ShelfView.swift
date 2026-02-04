import SwiftUI
import AppKit

struct ShelfView: View {
    var viewModel: ShelfViewModel
    var onClose: (() -> Void)?

    var body: some View {
        Group {
            switch viewModel.viewState {
            case .collapsed:
                CollapsedShelfView(viewModel: viewModel, onClose: onClose)
            case .expanded:
                ExpandedShelfView(viewModel: viewModel, onClose: onClose)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.viewState == .expanded)
    }
}

// MARK: - Collapsed View (收起状态)

struct CollapsedShelfView: View {
    var viewModel: ShelfViewModel
    var onClose: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            // 顶部栏
            HStack {
                // 关闭按钮
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

                Spacer()

                // 拖动条（有文件时显示）
                if !viewModel.items.isEmpty {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.secondary.opacity(0.4))
                        .frame(width: 36, height: 4)
                }

                Spacer()

                // 省略号菜单按钮（有文件时显示）
                if !viewModel.items.isEmpty {
                    Menu {
                        Button("展开查看全部") {
                            viewModel.expand()
                        }
                        Divider()
                        Button("在 Finder 中显示") {
                            if let firstItem = viewModel.items.first {
                                NSWorkspace.shared.activateFileViewerSelecting([firstItem.url])
                            }
                        }
                        Divider()
                        Button("清空所有", role: .destructive) {
                            viewModel.clearAll()
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .menuStyle(.borderlessButton)
                    .menuIndicator(.hidden)
                    .frame(width: 28, height: 28)
                    .background(Color.primary.opacity(0.1))
                    .clipShape(Circle())
                } else {
                    Color.clear.frame(width: 28, height: 28)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)

            // 内容区域
            if viewModel.items.isEmpty {
                emptyStateView
            } else {
                stackedThumbnailsView
                filePreviewBar
            }
        }
        .frame(width: 200, height: viewModel.items.isEmpty ? 200 : 240)
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Spacer()
            Text("放置你的内容项")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var stackedThumbnailsView: some View {
        DraggableStackView(
            urls: viewModel.items.map { $0.url },
            thumbnails: viewModel.items.map { $0.thumbnail },
            onTap: { viewModel.expand() },
            onFilesMovedOut: { movedUrls in
                viewModel.removeItems(byUrls: movedUrls)
            }
        ) {
            AnyView(
                ZStack {
                    // 扑克牌散开效果：轻微倾斜偏移
                    ForEach(Array(viewModel.items.prefix(3).enumerated().reversed()), id: \.element.id) { index, item in
                        thumbnailCard(for: item)
                            .rotationEffect(.degrees(Double(index) * -3)) // 轻微倾斜
                            .offset(x: CGFloat(index) * 5, y: CGFloat(index) * 2) // 轻微偏移
                    }
                }
                .frame(height: 120)
                .padding(.top, 16)
            )
        }
        .frame(height: 136)
    }

    private func thumbnailCard(for item: ShelfItem) -> some View {
        Group {
            if let thumbnail = item.thumbnail {
                Image(nsImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.1))
                    .frame(width: 100, height: 100)
                    .overlay {
                        Image(systemName: item.fileType.icon)
                            .font(.system(size: 32))
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    private var filePreviewBar: some View {
        Button {
            viewModel.expand()
        } label: {
            HStack {
                if let firstItem = viewModel.items.first {
                    Text(firstItem.name)
                        .font(.caption)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                if viewModel.items.count > 1 {
                    Text("+\(viewModel.items.count - 1)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.primary.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }
}

// MARK: - Expanded View (展开状态)

struct ExpandedShelfView: View {
    var viewModel: ShelfViewModel
    var onClose: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            // 导航栏
            navigationBar

            Divider()

            // 内容区域
            if viewModel.displayMode == .grid {
                gridContentView
            } else {
                listContentView
            }

            Divider()

            // 底部状态栏
            statusBar
        }
        .frame(width: 400, height: 300)
        .onKeyPress(.delete) {
            if !viewModel.selectedItemIds.isEmpty {
                viewModel.deleteSelected()
                return .handled
            }
            return .ignored
        }
        .onKeyPress(keys: [.init("a")]) { press in
            if press.modifiers.contains(.command) {
                viewModel.selectAll()
                return .handled
            }
            return .ignored
        }
    }

    private var navigationBar: some View {
        HStack {
            // 返回按钮
            HoverableCircleButton(icon: "chevron.left", foregroundStyle: .primary) {
                viewModel.collapse()
            }

            Spacer()

            // 标题
            if viewModel.selectedItemIds.isEmpty {
                Text(viewModel.itemCountDescription)
                    .font(.headline)
            } else {
                Text("已选择 \(viewModel.selectedItemIds.count) 个")
                    .font(.headline)
                    .foregroundStyle(Color.accentColor)
            }

            Spacer()

            // 视图切换按钮（单按钮切换）
            HoverableCircleButton(
                icon: viewModel.displayMode == .grid ? "square.grid.2x2" : "list.bullet",
                foregroundStyle: .secondary
            ) {
                viewModel.displayMode = viewModel.displayMode == .grid ? .list : .grid
            }

            // 更多操作菜单
            moreActionsMenu

            // 关闭按钮
            HoverableCircleButton(icon: "xmark", foregroundStyle: .secondary) {
                onClose?()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    // MARK: - More Actions Menu

    @State private var isMenuHovered = false

    private var moreActionsMenu: some View {
        Menu {
            if !viewModel.selectedItemIds.isEmpty {
                Button("在 Finder 中显示选中项") {
                    NSWorkspace.shared.activateFileViewerSelecting(viewModel.selectedUrls)
                }
                Button("复制到剪切板") {
                    copySelectedToClipboard()
                }
                Divider()
                Button("全选") {
                    viewModel.selectAll()
                }
                Button("取消选择") {
                    viewModel.deselectAll()
                }
                Divider()
                Button("删除选中项", role: .destructive) {
                    viewModel.deleteSelected()
                }
            } else {
                Button("在 Finder 中显示全部") {
                    NSWorkspace.shared.activateFileViewerSelecting(viewModel.items.map { $0.url })
                }
                Divider()
                Button("全选") {
                    viewModel.selectAll()
                }
                Divider()
                Button("清空所有", role: .destructive) {
                    viewModel.clearAll()
                }
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .frame(width: 28, height: 28)
        .background(
            Circle()
                .fill(Color.primary.opacity(isMenuHovered ? 0.15 : 0.1))
        )
        .onHover { hovering in
            isMenuHovered = hovering
        }
    }

    private func copySelectedToClipboard() {
        let urls = viewModel.selectedUrls
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects(urls as [NSURL])
    }

    // MARK: - Status Bar

    private var statusBar: some View {
        HStack {
            Text(viewModel.formattedTotalSize)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            if !viewModel.selectedItemIds.isEmpty {
                Button("取消选择") {
                    viewModel.deselectAll()
                }
                .font(.caption)
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Grid Content

    private var gridContentView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 16)], spacing: 16) {
                ForEach(viewModel.items) { item in
                    GridItemView(item: item, viewModel: viewModel)
                }

                // 垃圾桶删除区域
                trashDropZone
            }
            .padding(16)
        }
    }

    private var trashDropZone: some View {
        TrashDropZone(viewModel: viewModel)
    }

    // MARK: - List Content

    private var listContentView: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.items) { item in
                    ListItemView(item: item, viewModel: viewModel)
                }
            }
            .padding(16)
        }
    }
}

// MARK: - Grid Item View

struct GridItemView: View {
    let item: ShelfItem
    var viewModel: ShelfViewModel
    @State private var isHovered = false

    private var isSelected: Bool {
        viewModel.isSelected(item)
    }

    var body: some View {
        DraggableItemView(
            url: item.url,
            thumbnail: item.thumbnail,
            getSelectedUrls: {
                viewModel.selectedItemIds.isEmpty ? [item.url] : viewModel.selectedUrls
            },
            getSelectedThumbnails: {
                viewModel.selectedItemIds.isEmpty ? [item.thumbnail] : viewModel.selectedThumbnails
            },
            isSelected: {
                viewModel.selectedItemIds.contains(item.id)
            },
            onDragEnd: { draggedUrls in
                viewModel.removeItems(byUrls: draggedUrls)
            }
        ) {
            gridItemContent
        }
        .contextMenu {
            Button("在 Finder 中显示") {
                viewModel.showInFinder(item)
            }
            Divider()
            if isSelected && viewModel.selectedItemIds.count > 1 {
                Button("删除选中的 \(viewModel.selectedItemIds.count) 个文件", role: .destructive) {
                    viewModel.deleteSelected()
                }
            } else {
                Button("删除", role: .destructive) {
                    viewModel.removeItem(item)
                }
            }
        }
    }

    private var gridItemContent: some View {
        VStack(spacing: 6) {
            // 缩略图
            ZStack(alignment: .topLeading) {
                if let thumbnail = item.thumbnail {
                    Image(nsImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.1))
                        .frame(width: 100, height: 80)
                        .overlay {
                            Image(systemName: item.fileType.icon)
                                .font(.system(size: 24))
                                .foregroundStyle(.secondary)
                        }
                }

                // 删除按钮（右上角）
                if isHovered && !isSelected {
                    HStack {
                        Spacer()
                        Button {
                            viewModel.removeItem(item)
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 16, height: 16)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .padding(4)
                    }
                }
            }

            // 文件名
            Text(item.name)
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(width: 100)

            // 大小和尺寸
            HStack(spacing: 4) {
                Text(item.formattedSize)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if let dims = item.formattedDimensions {
                    Text("·")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(dims)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? Color.accentColor.opacity(0.08) : (isHovered ? Color.primary.opacity(0.08) : Color.clear))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.accentColor.opacity(0.6) : (isHovered ? Color.accentColor.opacity(0.3) : Color.clear), lineWidth: isSelected ? 2 : 1)
        )
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            viewModel.toggleSelection(item.id, modifierFlags: NSEvent.modifierFlags)
        }
    }
}

// MARK: - List Item View

struct ListItemView: View {
    let item: ShelfItem
    var viewModel: ShelfViewModel
    @State private var isHovered = false

    private var isSelected: Bool {
        viewModel.isSelected(item)
    }

    var body: some View {
        DraggableItemView(
            url: item.url,
            thumbnail: item.thumbnail,
            getSelectedUrls: {
                viewModel.selectedItemIds.isEmpty ? [item.url] : viewModel.selectedUrls
            },
            getSelectedThumbnails: {
                viewModel.selectedItemIds.isEmpty ? [item.thumbnail] : viewModel.selectedThumbnails
            },
            isSelected: {
                viewModel.selectedItemIds.contains(item.id)
            },
            onDragEnd: { draggedUrls in
                viewModel.removeItems(byUrls: draggedUrls)
            }
        ) {
            listItemContent
        }
        .contextMenu {
            Button("在 Finder 中显示") {
                viewModel.showInFinder(item)
            }
            Divider()
            if isSelected && viewModel.selectedItemIds.count > 1 {
                Button("删除选中的 \(viewModel.selectedItemIds.count) 个文件", role: .destructive) {
                    viewModel.deleteSelected()
                }
            } else {
                Button("删除", role: .destructive) {
                    viewModel.removeItem(item)
                }
            }
        }
    }

    private var listItemContent: some View {
        HStack(spacing: 10) {
            // 缩略图
            if let thumbnail = item.thumbnail {
                Image(nsImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            } else {
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.secondary.opacity(0.1))
                    .frame(width: 32, height: 32)
                    .overlay {
                        Image(systemName: item.fileType.icon)
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
            }

            // 文件名
            Text(item.name)
                .font(.callout)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            // 大小和尺寸
            VStack(alignment: .trailing, spacing: 1) {
                Text(item.formattedSize)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if let dims = item.formattedDimensions {
                    Text(dims)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            // 删除按钮
            Button {
                viewModel.removeItem(item)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .opacity(isHovered ? 1 : 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : (isHovered ? Color.accentColor.opacity(0.08) : Color.primary.opacity(0.03)))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 1.5)
        )
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            viewModel.toggleSelection(item.id, modifierFlags: NSEvent.modifierFlags)
        }
    }
}

// MARK: - Trash Drop Zone

struct TrashDropZone: View {
    var viewModel: ShelfViewModel
    @State private var isTargeted = false

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: isTargeted ? "trash.fill" : "trash")
                .font(.system(size: 24))
                .foregroundStyle(isTargeted ? .red : .secondary)
            Text("拖此删除")
                .font(.caption)
                .foregroundStyle(isTargeted ? .red : .secondary)
        }
        .frame(width: 100, height: 120)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(
                    isTargeted ? Color.red : Color.secondary.opacity(0.3),
                    style: StrokeStyle(lineWidth: 2, dash: [6, 4])
                )
        )
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isTargeted ? Color.red.opacity(0.1) : Color.clear)
        )
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            // 删除拖入的文件
            for provider in providers {
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    if let url = url {
                        DispatchQueue.main.async {
                            viewModel.removeItems(byUrls: [url])
                        }
                    }
                }
            }
            return true
        }
    }
}

// MARK: - Hoverable Circle Button

struct HoverableCircleButton: View {
    let icon: String
    let foregroundStyle: HierarchicalShapeStyle
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(foregroundStyle)
                .frame(width: 28, height: 28)
                .background(Color.primary.opacity(isHovered ? 0.15 : 0.1))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

#Preview {
    ShelfView(viewModel: ShelfViewModel(), onClose: {})
        .frame(width: 200, height: 200)
        .background(.regularMaterial)
}
