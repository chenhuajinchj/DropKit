import Foundation

/// 文件夹监听服务，检测新文件并触发回调
class FolderMonitor {
    private var source: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1
    private var knownFiles: Set<String> = []
    private var watchedURL: URL?
    private var isAccessingSecurityScopedResource = false
    private let queue = DispatchQueue(label: "com.dropkit.foldermonitor", qos: .utility)

    /// 每次 start / stop 都会 +1。用于让 queue 上 asyncAfter 的延迟任务自行作废，
    /// 防止"0.3s 窗口内 stop → start 新目录"导致旧任务污染新状态。
    private var generation: UInt64 = 0

    /// 新文件回调
    var onNewFile: ((URL) -> Void)?

    /// 当前是否正在监听
    var isMonitoring: Bool {
        source != nil
    }

    deinit {
        stop()
    }

    /// 开始监听指定文件夹
    func start(url: URL) {
        // 如果已经在监听同一路径，不重复启动
        if watchedURL == url && source != nil {
            return
        }

        // 停止之前的监听
        stop()

        generation &+= 1
        watchedURL = url

        if url.startAccessingSecurityScopedResource() {
            isAccessingSecurityScopedResource = true
        }

        // 验证路径存在且是目录
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            #if DEBUG
            print("FolderMonitor: 路径不存在或不是目录: \(url.path)")
            #endif
            stop()
            return
        }

        // 初始化已知文件列表
        knownFiles = getCurrentFiles(at: url)

        // 打开文件描述符
        fileDescriptor = open(url.path, O_EVTONLY)
        guard fileDescriptor >= 0 else {
            #if DEBUG
            print("FolderMonitor: 无法打开目录: \(url.path)")
            #endif
            stop()
            return
        }

        // 创建 DispatchSource 监听文件系统事件
        source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: .write,
            queue: queue
        )

        source?.setEventHandler { [weak self] in
            self?.handleFileSystemEvent()
        }

        source?.setCancelHandler { [weak self] in
            if let fd = self?.fileDescriptor, fd >= 0 {
                close(fd)
            }
            self?.fileDescriptor = -1
        }

        source?.resume()

        #if DEBUG
        print("FolderMonitor: 开始监听 \(url.path)")
        #endif
    }

    /// 停止监听
    func stop() {
        let currentWatchedURL = watchedURL
        generation &+= 1
        source?.cancel()
        source = nil
        watchedURL = nil
        knownFiles.removeAll()
        if isAccessingSecurityScopedResource {
            isAccessingSecurityScopedResource = false
            currentWatchedURL?.stopAccessingSecurityScopedResource()
        }

        #if DEBUG
        print("FolderMonitor: 停止监听")
        #endif
    }

    /// 获取当前目录下的所有文件名
    private func getCurrentFiles(at url: URL) -> Set<String> {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }
        return Set(contents.map { $0.lastPathComponent })
    }

    /// 处理文件系统事件
    private func handleFileSystemEvent() {
        guard let folderURL = watchedURL else { return }
        let currentGen = generation

        // 延迟处理，确保文件写入完成
        queue.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self, self.generation == currentGen else { return }
            self.checkForNewFiles(at: folderURL, generation: currentGen)
        }
    }

    /// 检查新增文件
    private func checkForNewFiles(at folderURL: URL, generation expectedGen: UInt64) {
        // 再次校验 generation：queue 上执行期间可能已经 stop
        guard self.generation == expectedGen else { return }

        let currentFiles = getCurrentFiles(at: folderURL)
        let newFiles = currentFiles.subtracting(knownFiles)

        // 更新已知文件列表
        knownFiles = currentFiles

        // 处理新文件
        for fileName in newFiles {
            let fileURL = folderURL.appendingPathComponent(fileName)

            // 确保文件存在且可读
            guard FileManager.default.isReadableFile(atPath: fileURL.path) else {
                continue
            }

            #if DEBUG
            print("FolderMonitor: 检测到新文件 \(fileName)")
            #endif

            // 在主线程回调前再次校验 generation
            DispatchQueue.main.async { [weak self] in
                guard let self, self.generation == expectedGen else { return }
                self.onNewFile?(fileURL)
            }
        }
    }

    // MARK: - 辅助方法

    /// 获取 macOS 截图文件夹路径
    static func getScreenshotFolderURL() -> URL? {
        // 尝试读取系统截图设置
        if let screencaptureDefaults = UserDefaults.standard.persistentDomain(forName: "com.apple.screencapture"),
           let location = screencaptureDefaults["location"] as? String {
            // 展开 ~ 路径
            let expandedPath = NSString(string: location).expandingTildeInPath
            if FileManager.default.fileExists(atPath: expandedPath) {
                return URL(fileURLWithPath: expandedPath, isDirectory: true)
            }
        }

        // 常见截图文件夹路径
        let commonPaths = [
            NSHomeDirectory() + "/Pictures/截图和录屏",
            NSHomeDirectory() + "/Pictures/Screenshots",
            NSHomeDirectory() + "/Desktop"
        ]

        for path in commonPaths {
            if FileManager.default.fileExists(atPath: path) {
                return URL(fileURLWithPath: path, isDirectory: true)
            }
        }

        return nil
    }
}
