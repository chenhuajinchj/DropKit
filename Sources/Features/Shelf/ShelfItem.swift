import Foundation

struct ShelfItem: Identifiable {
    let id = UUID()
    let url: URL
    let name: String

    init(url: URL) {
        self.url = url
        self.name = url.lastPathComponent
    }
}
