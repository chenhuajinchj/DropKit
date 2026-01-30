import Foundation

@Observable
class ShelfViewModel {
    var items: [ShelfItem] = []

    func addItem(url: URL) {
        let item = ShelfItem(url: url)
        items.append(item)
        print("Added item: \(item.name)")
    }

    func addItems(urls: [URL]) {
        for url in urls {
            addItem(url: url)
        }
    }

    func removeItem(_ item: ShelfItem) {
        items.removeAll { $0.id == item.id }
    }

    func removeItem(at index: Int) {
        guard items.indices.contains(index) else { return }
        items.remove(at: index)
    }

    func clearAll() {
        items.removeAll()
    }
}
