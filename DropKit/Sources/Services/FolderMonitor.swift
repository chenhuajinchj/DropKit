import Foundation

/// 文件夹监听服务，检测新文件并触发回调
class FolderMonitor {
    private var source: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1
    private var knownFiles: Set<String> = []
    private var watchedPath: String?
    private let queue = DispatchQueue(label: "com.dropkit.foldermonitor", qos: .utility)

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
    func start(path: String) {
        // 如果已经在监听同一路径，不重复启动
        if watchedPath == path && source != nil {
            return
        }

        // 停止之前的监听
        stop()

        watchedPath = path

        // 验证路径存在且是目录
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            #if DEBUG
            print("FolderMonitor: 路径不存在或不是目录: \(path)")
            #endif
            return
        }

        // 初始化已知文件列表
        knownFiles = getCurrentFiles(at: path)

        // 打开文件描述符
        fileDescriptor = open(path, O_EVTONLY)
        guard fileDescriptor >= 0 else {
            #if DEBUG
            print("FolderMonitor: 无法打开目录: \(path)")
            #endif
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
        print("FolderMonitor: 开始监听 \(path)")
        #endif
    }

    /// 停止监听
    func stop() {
        source?.cancel()
        source = nil
        watchedPath = nil
        knownFiles.removeAll()

        #if DEBUG
        print("FolderMonitor: 停止监听")
        #endif
    }

    /// 获取当前目录下的所有文件名
    private func getCurrentFiles(at path: String) -> Set<String> {
        let url = URL(fileURLWithPath: path)
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
        guard let path = watchedPath else { return }

        // 延迟处理，确保文件写入完成
        queue.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.checkForNewFiles(at: path)
        }
    }

    /// 检查新增文件
    private func checkForNewFiles(at path: String) {
        let currentFiles = getCurrentFiles(at: path)
        let newFiles = currentFiles.subtracting(knownFiles)

        // 更新已知文件列表
        knownFiles = currentFiles

        // 处理新文件
        for fileName in newFiles {
            let fileURL = URL(fileURLWithPath: path).appendingPathComponent(fileName)

            // 确保文件存在且可读
            guard FileManager.default.isReadableFile(atPath: fileURL.path) else {
                continue
            }

            #if DEBUG
            print("FolderMonitor: 检测到新文件 \(fileName)")
            #endif

            // 在主线程回调
            DispatchQueue.main.async { [weak self] in
                self?.onNewFile?(fileURL)
            }
        }
    }

    // MARK: - 辅助方法

    /// 获取 macOS 截图文件夹路径
    static func getScreenshotFolderPath() -> String? {
        // 尝试读取系统截图设置
        if let screencaptureDefaults = UserDefaults.standard.persistentDomain(forName: "com.apple.screencapture"),
           let location = screencaptureDefaults["location"] as? String {
            // 展开 ~ 路径
            let expandedPath = NSString(string: location).expandingTildeInPath
            if FileManager.default.fileExists(atPath: expandedPath) {
                return expandedPath
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
                return path
            }
        }

        return nil
    }
}
