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
}
