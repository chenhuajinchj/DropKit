import SwiftUI

struct ClipboardHistoryView: View {
    var monitor: ClipboardMonitor
    var onClose: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("剪切板历史")
                    .font(.headline)
                Spacer()
                if !monitor.items.isEmpty {
                    Button {
                        monitor.clearAll()
                    } label: {
                        Text("清空")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                Button {
                    onClose?()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // 内容区域
            if monitor.items.isEmpty {
                emptyStateView
            } else {
                itemsListView
            }
        }
        .frame(width: 300, height: 400)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "clipboard")
                .font(.system(size: 48))
                .foregroundStyle(.primary.opacity(0.6))
            Text("暂无剪切板历史")
                .font(.headline)
                .foregroundStyle(.primary.opacity(0.6))
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var itemsListView: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(monitor.items) { item in
                    ClipboardItemRow(item: item) {
                        monitor.copyToClipboard(item)
                    } onDelete: {
                        monitor.removeItem(item)
                    }
                }
            }
            .padding(12)
        }
    }
}

struct ClipboardItemRow: View {
    let item: ClipboardItem
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Image(systemName: item.icon)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            Text(item.displayText)
                .lineLimit(2)
                .truncationMode(.tail)
                .font(.callout)
            Spacer()
            Button {
                onDelete()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}
