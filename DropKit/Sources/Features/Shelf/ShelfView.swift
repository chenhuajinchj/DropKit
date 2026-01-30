import SwiftUI

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

                // 收起按钮（有文件时显示）
                if !viewModel.items.isEmpty {
                    Button {
                        viewModel.expand()
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(width: 28, height: 28)
                            .background(Color.primary.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
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
        }
        .frame(width: 400, height: 300)
    }

    private var navigationBar: some View {
        HStack {
            // 返回按钮
            Button {
                viewModel.collapse()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)
                    .frame(width: 32, height: 32)
                    .background(Color.primary.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            // 统计信息
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.itemCountDescription)
                    .font(.headline)
                Text(viewModel.formattedTotalSize)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // 视图切换按钮
            HStack(spacing: 4) {
                viewModeButton(mode: .grid, icon: "square.grid.2x2")
                viewModeButton(mode: .list, icon: "list.bullet")
            }

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
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private func viewModeButton(mode: DisplayMode, icon: String) -> some View {
        Button {
            viewModel.displayMode = mode
        } label: {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(viewModel.displayMode == mode ? .primary : .secondary)
                .frame(width: 32, height: 32)
                .background(viewModel.displayMode == mode ? Color.primary.opacity(0.1) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Grid Content

    private var gridContentView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 16)], spacing: 16) {
                ForEach(viewModel.items) { item in
                    GridItemView(item: item, viewModel: viewModel)
                }

                // "在 Finder 中显示" 快捷操作
                if let firstItem = viewModel.items.first {
                    finderShortcut(for: firstItem)
                }
            }
            .padding(16)
        }
    }

    private func finderShortcut(for item: ShelfItem) -> some View {
        Button {
            viewModel.showInFinder(item)
        } label: {
            VStack(spacing: 8) {
                Image(systemName: "arrow.up.forward.circle")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
                Text("在 Finder 中显示")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 100, height: 120)
        }
        .buttonStyle(.plain)
    }

    // MARK: - List Content

    private var listContentView: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.items) { item in
                    ListItemView(item: item, viewModel: viewModel)
                }
            }
            .padding(12)
        }
    }
}

// MARK: - Grid Item View

struct GridItemView: View {
    let item: ShelfItem
    var viewModel: ShelfViewModel
    @State private var isHovered = false

    var body: some View {
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

                // 删除按钮
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
                .opacity(isHovered ? 1 : 0)
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
                .fill(isHovered ? Color.primary.opacity(0.08) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isHovered ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 2)
        )
        .onHover { hovering in
            isHovered = hovering
        }
        .draggable(item.url)
        .contextMenu {
            Button("在 Finder 中显示") {
                viewModel.showInFinder(item)
            }
            Divider()
            Button("删除", role: .destructive) {
                viewModel.removeItem(item)
            }
        }
    }
}

// MARK: - List Item View

struct ListItemView: View {
    let item: ShelfItem
    var viewModel: ShelfViewModel
    @State private var isHovered = false

    var body: some View {
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
                .fill(isHovered ? Color.accentColor.opacity(0.15) : Color.primary.opacity(0.03))
        )
        .onHover { hovering in
            isHovered = hovering
        }
        .draggable(item.url)
        .contextMenu {
            Button("在 Finder 中显示") {
                viewModel.showInFinder(item)
            }
            Divider()
            Button("删除", role: .destructive) {
                viewModel.removeItem(item)
            }
        }
    }
}

#Preview {
    ShelfView(viewModel: ShelfViewModel(), onClose: {})
        .frame(width: 200, height: 200)
        .background(.regularMaterial)
}
