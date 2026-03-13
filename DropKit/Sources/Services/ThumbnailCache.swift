import AppKit

final class ThumbnailCache {
    static let shared = ThumbnailCache()

    private let cache = NSCache<NSString, NSImage>()
    private let loadingQueue = DispatchQueue(label: "com.dropkit.thumbnail", qos: .userInitiated)

    private init() {
        cache.countLimit = 100  // 最多缓存 100 张
        cache.totalCostLimit = 50 * 1024 * 1024  // 最多 50MB
    }

    func thumbnail(for path: String, completion: @escaping (NSImage?) -> Void) {
        let key = path as NSString

        if let cached = cache.object(forKey: key) {
            completion(cached)
            return
        }

        loadingQueue.async { [weak self] in
            let image = self?.generateThumbnail(for: path)

            DispatchQueue.main.async {
                if let image = image {
                    let cost = Int(image.size.width * image.size.height * 4)
                    self?.cache.setObject(image, forKey: key, cost: cost)
                }
                completion(image)
            }
        }
    }

    func store(_ image: NSImage, forPath path: String) {
        let key = path as NSString
        let cost = Int(image.size.width * image.size.height * 4)
        cache.setObject(image, forKey: key, cost: cost)
    }

    private func generateThumbnail(for path: String) -> NSImage? {
        let url = URL(fileURLWithPath: path)
        let maxPixelSize = 160  // 80pt * 2x

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            kCGImageSourceShouldCacheImmediately: false
        ]

        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
              let cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
            return nil
        }

        let size = NSSize(width: CGFloat(cgImage.width), height: CGFloat(cgImage.height))
        return NSImage(cgImage: cgImage, size: size)
    }

    func clearCache() {
        cache.removeAllObjects()
    }
}
