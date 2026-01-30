import SwiftUI

struct ShelfView: View {
    var viewModel: ShelfViewModel

    var body: some View {
        Group {
            if viewModel.items.isEmpty {
                emptyStateView
            } else {
                itemsListView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "tray.and.arrow.down")
                .font(.system(size: 48))
                .foregroundStyle(.primary.opacity(0.6))

            Text("拖入文件到这里")
                .font(.headline)
                .foregroundStyle(.primary.opacity(0.6))

            Spacer()
        }
    }

    private var itemsListView: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.items) { item in
                    HStack {
                        Image(systemName: "doc.fill")
                            .foregroundStyle(.secondary)
                        Text(item.name)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .draggable(item.url)
                }
            }
            .padding(12)
        }
    }
}

#Preview {
    ShelfView(viewModel: ShelfViewModel())
        .frame(width: 180, height: 220)
        .background(.regularMaterial)
}
