import SwiftUI

struct ShelfView: View {
    var body: some View {
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ShelfView()
        .frame(width: 300, height: 400)
        .background(.regularMaterial)
}
