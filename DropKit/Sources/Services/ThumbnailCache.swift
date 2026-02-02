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

        // 1. 检查内存缓存
        if let cached = cache.object(forKey: key) {
            completion(cached)
            return
        }

        // 2. 异步加载
        loadingQueue.async { [weak self] in
            let image = self?.loadThumbnail(for: path)

            DispatchQueue.main.async {
                if let image = image {
                    self?.cache.setObject(image, forKey: key)
                }
                completion(image)
            }
        }
    }

    private func loadThumbnail(for path: String) -> NSImage? {
        // 优先加载缩略图文件
        let thumbPath = path.replacingOccurrences(of: ".png", with: "_thumb.png")

        if FileManager.default.fileExists(atPath: thumbPath) {
            return NSImage(contentsOfFile: thumbPath)
        }

        // 降级：加载原图（兼容旧数据）
        return NSImage(contentsOfFile: path)
    }

    func clearCache() {
        cache.removeAllObjects()
    }
}
