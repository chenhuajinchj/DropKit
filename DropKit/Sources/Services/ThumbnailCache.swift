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
                    // 传入 cost（估算像素数据大小）用于 totalCostLimit 生效
                    let cost = Int(image.size.width * image.size.height * 4)
                    self?.cache.setObject(image, forKey: key, cost: cost)
                }
                completion(image)
            }
        }
    }

    private func loadThumbnail(for path: String) -> NSImage? {
        // 优先加载已有的缩略图文件
        let thumbPath = Self.thumbnailPath(for: path)

        if FileManager.default.fileExists(atPath: thumbPath) {
            return NSImage(contentsOfFile: thumbPath)
        }

        // 降级：用 CGImageSource 生成缩略图，不加载原图到内存
        return generateAndSaveThumbnail(for: path)
    }

    /// 根据原图路径生成对应的缩略图路径（支持任意扩展名）
    static func thumbnailPath(for path: String) -> String {
        let url = URL(fileURLWithPath: path)
        let dir = url.deletingLastPathComponent().path
        let name = url.deletingPathExtension().lastPathComponent
        return (dir as NSString).appendingPathComponent("\(name)_thumb.png")
    }

    /// 用 CGImageSource 生成缩略图并保存到磁盘，返回缩略图 NSImage
    private func generateAndSaveThumbnail(for path: String) -> NSImage? {
        let url = URL(fileURLWithPath: path)
        let thumbSize = CGSize(width: 80, height: 80)
        let maxPixelSize = Int(max(thumbSize.width, thumbSize.height) * 2.0)

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

        // 保存缩略图到磁盘
        let thumbPath = Self.thumbnailPath(for: path)
        let thumbURL = URL(fileURLWithPath: thumbPath)
        if let destination = CGImageDestinationCreateWithURL(
            thumbURL as CFURL,
            "public.png" as CFString,
            1,
            nil
        ) {
            CGImageDestinationAddImage(destination, cgImage, nil)
            CGImageDestinationFinalize(destination)
        }

        let size = NSSize(width: CGFloat(cgImage.width), height: CGFloat(cgImage.height))
        return NSImage(cgImage: cgImage, size: size)
    }

    func clearCache() {
        cache.removeAllObjects()
    }
}
