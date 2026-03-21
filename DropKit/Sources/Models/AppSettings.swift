import AppKit

@Observable
class AppSettings {
    static let shared = AppSettings()

    private enum Keys {
        static let shakeMinShakes = "shakeMinShakes"
        static let shakeTimeWindow = "shakeTimeWindow"
        static let shakeMinMovement = "shakeMinMovement"
        static let clipboardRetentionDays = "clipboardRetentionDays"
        static let clipboardMaxItems = "clipboardMaxItems"
        static let ignoreConcealed = "ignoreConcealed"
        static let clipboardBlacklistEnabled = "clipboardBlacklistEnabled"
        static let clipboardBlacklist = "clipboardBlacklist"
        static let launchAtLogin = "launchAtLogin"
        static let folderMonitorEnabled = "folderMonitorEnabled"
        static let watchedFolderPath = "watchedFolderPath"
        static let autoCopyToClipboard = "autoCopyToClipboard"
        static let autoShowShelfOnNewFile = "autoShowShelfOnNewFile"
        static let shelfLastPositionX = "shelfLastPositionX"
        static let shelfLastPositionY = "shelfLastPositionY"
        static let shelfExpandedWidth = "shelfExpandedWidth"
        static let shelfExpandedHeight = "shelfExpandedHeight"
    }

    // 摇晃检测参数
    var shakeMinShakes: Int {
        didSet { defaults.set(shakeMinShakes, forKey: Keys.shakeMinShakes) }
    }
    var shakeTimeWindow: Double {
        didSet { defaults.set(shakeTimeWindow, forKey: Keys.shakeTimeWindow) }
    }
    var shakeMinMovement: Double {
        didSet { defaults.set(shakeMinMovement, forKey: Keys.shakeMinMovement) }
    }

    // 剪切板历史保留天数（0 = 永久）
    var clipboardRetentionDays: Int {
        didSet { defaults.set(clipboardRetentionDays, forKey: Keys.clipboardRetentionDays) }
    }

    // 剪切板历史最大条数（0 = 永久）
    var clipboardMaxItems: Int {
        didSet { defaults.set(clipboardMaxItems, forKey: Keys.clipboardMaxItems) }
    }

    // 忽略密码管理器内容（默认开启）
    var ignoreConcealed: Bool {
        didSet { defaults.set(ignoreConcealed, forKey: Keys.ignoreConcealed) }
    }

    // 应用黑名单
    var clipboardBlacklistEnabled: Bool {
        didSet { defaults.set(clipboardBlacklistEnabled, forKey: Keys.clipboardBlacklistEnabled) }
    }
    var clipboardBlacklist: Set<String> {
        didSet { defaults.set(Array(clipboardBlacklist), forKey: Keys.clipboardBlacklist) }
    }

    func isBlacklisted(_ bundleId: String) -> Bool {
        clipboardBlacklistEnabled && clipboardBlacklist.contains(bundleId)
    }

    // 开机自启动
    var launchAtLogin: Bool {
        didSet {
            defaults.set(launchAtLogin, forKey: Keys.launchAtLogin)
            updateLaunchAtLogin()
        }
    }

    // 文件夹监听
    var folderMonitorEnabled: Bool {
        didSet { defaults.set(folderMonitorEnabled, forKey: Keys.folderMonitorEnabled) }
    }
    private(set) var watchedFolderPath: String? {
        didSet { defaults.set(watchedFolderPath, forKey: Keys.watchedFolderPath) }
    }
    var autoCopyToClipboard: Bool {
        didSet { defaults.set(autoCopyToClipboard, forKey: Keys.autoCopyToClipboard) }
    }
    var autoShowShelfOnNewFile: Bool {
        didSet { defaults.set(autoShowShelfOnNewFile, forKey: Keys.autoShowShelfOnNewFile) }
    }

    // 窗口位置记忆（仅用于截图/菜单栏/快捷键触发）
    private(set) var shelfLastPositionX: Double {
        didSet { defaults.set(shelfLastPositionX, forKey: Keys.shelfLastPositionX) }
    }
    private(set) var shelfLastPositionY: Double {
        didSet { defaults.set(shelfLastPositionY, forKey: Keys.shelfLastPositionY) }
    }

    // 展开状态窗口尺寸记忆（用户调整后保存）
    private(set) var shelfExpandedWidth: Double {
        didSet { defaults.set(shelfExpandedWidth, forKey: Keys.shelfExpandedWidth) }
    }
    private(set) var shelfExpandedHeight: Double {
        didSet { defaults.set(shelfExpandedHeight, forKey: Keys.shelfExpandedHeight) }
    }

    var hasSavedShelfPosition: Bool {
        shelfLastPositionX >= 0 && shelfLastPositionY >= 0
    }

    var hasSavedExpandedSize: Bool {
        shelfExpandedWidth > 0 && shelfExpandedHeight > 0
    }

    func saveShelfPosition(_ origin: NSPoint) {
        shelfLastPositionX = origin.x
        shelfLastPositionY = origin.y
    }

    func getSavedShelfPosition() -> NSPoint? {
        guard hasSavedShelfPosition else { return nil }
        return NSPoint(x: shelfLastPositionX, y: shelfLastPositionY)
    }

    func saveShelfExpandedSize(_ size: NSSize) {
        shelfExpandedWidth = size.width
        shelfExpandedHeight = size.height
    }

    func getSavedExpandedSize() -> NSSize? {
        guard hasSavedExpandedSize else { return nil }
        return NSSize(width: shelfExpandedWidth, height: shelfExpandedHeight)
    }

    private let defaults: UserDefaults
    private let launchAtLoginManager: any LaunchAtLoginManaging
    private let bookmarkStore: FolderBookmarkStore

    init(
        defaults: UserDefaults = .standard,
        launchAtLoginManager: any LaunchAtLoginManaging = SystemLaunchAtLoginManager(),
        bookmarkStore: FolderBookmarkStore? = nil
    ) {
        self.defaults = defaults
        self.launchAtLoginManager = launchAtLoginManager
        self.bookmarkStore = bookmarkStore ?? FolderBookmarkStore(defaults: defaults)

        let storedShakes = defaults.integer(forKey: Keys.shakeMinShakes)
        shakeMinShakes = storedShakes != 0 ? storedShakes : 4

        let storedTimeWindow = defaults.double(forKey: Keys.shakeTimeWindow)
        shakeTimeWindow = storedTimeWindow != 0 ? storedTimeWindow : 0.3

        let storedMovement = defaults.double(forKey: Keys.shakeMinMovement)
        shakeMinMovement = storedMovement != 0 ? storedMovement : 30

        // clipboardRetentionDays 默认 0 = 永久保存
        clipboardRetentionDays = defaults.integer(forKey: Keys.clipboardRetentionDays)

        // clipboardMaxItems 默认 0 = 永久保存
        clipboardMaxItems = defaults.integer(forKey: Keys.clipboardMaxItems)

        // ignoreConcealed 默认 true（安全起见）
        ignoreConcealed = defaults.object(forKey: Keys.ignoreConcealed) == nil ? true : defaults.bool(forKey: Keys.ignoreConcealed)

        // 应用黑名单
        clipboardBlacklistEnabled = defaults.bool(forKey: Keys.clipboardBlacklistEnabled)
        if let saved = defaults.array(forKey: Keys.clipboardBlacklist) as? [String] {
            clipboardBlacklist = Set(saved)
        } else {
            clipboardBlacklist = []
        }

        // 读取系统实际状态
        launchAtLogin = launchAtLoginManager.currentStatus()

        // 文件夹监听设置
        folderMonitorEnabled = defaults.bool(forKey: Keys.folderMonitorEnabled)
        watchedFolderPath = defaults.string(forKey: Keys.watchedFolderPath)
        if let restoredURL = self.bookmarkStore.restoreURL() {
            watchedFolderPath = restoredURL.path
        } else {
            watchedFolderPath = nil
            defaults.removeObject(forKey: Keys.watchedFolderPath)
        }

        // autoCopyToClipboard 默认 true
        autoCopyToClipboard = defaults.object(forKey: Keys.autoCopyToClipboard) == nil ? true : defaults.bool(forKey: Keys.autoCopyToClipboard)
        autoShowShelfOnNewFile = defaults.bool(forKey: Keys.autoShowShelfOnNewFile)

        // 窗口位置记忆（-1 表示未保存）
        let storedX = defaults.object(forKey: Keys.shelfLastPositionX)
        shelfLastPositionX = storedX != nil ? defaults.double(forKey: Keys.shelfLastPositionX) : -1

        let storedY = defaults.object(forKey: Keys.shelfLastPositionY)
        shelfLastPositionY = storedY != nil ? defaults.double(forKey: Keys.shelfLastPositionY) : -1

        // 展开状态窗口尺寸记忆（0 表示未保存，使用默认值）
        shelfExpandedWidth = defaults.double(forKey: Keys.shelfExpandedWidth)
        shelfExpandedHeight = defaults.double(forKey: Keys.shelfExpandedHeight)
    }

    private func updateLaunchAtLogin() {
        do {
            try launchAtLoginManager.setEnabled(launchAtLogin)
        } catch {
            #if DEBUG
            print("Failed to update launch at login: \(error)")
            #endif
        }
    }

    @discardableResult
    func setWatchedFolder(_ url: URL) -> Bool {
        do {
            let restoredURL = try bookmarkStore.save(url)
            watchedFolderPath = restoredURL.path
            return true
        } catch {
            #if DEBUG
            print("Failed to save watched folder bookmark: \(error)")
            #endif
            return false
        }
    }

    func watchedFolderURL() -> URL? {
        let restoredURL = bookmarkStore.restoreURL()
        watchedFolderPath = restoredURL?.path
        return restoredURL
    }

    func clearWatchedFolder() {
        bookmarkStore.clear()
        watchedFolderPath = nil
    }
}
