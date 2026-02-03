import AppKit
import ServiceManagement

@Observable
class AppSettings {
    static let shared = AppSettings()

    // 摇晃检测参数
    var shakeMinShakes: Int {
        didSet { defaults.set(shakeMinShakes, forKey: "shakeMinShakes") }
    }
    var shakeTimeWindow: Double {
        didSet { defaults.set(shakeTimeWindow, forKey: "shakeTimeWindow") }
    }
    var shakeMinMovement: Double {
        didSet { defaults.set(shakeMinMovement, forKey: "shakeMinMovement") }
    }

    // 剪切板历史保留天数（0 = 永久）
    var clipboardRetentionDays: Int {
        didSet { defaults.set(clipboardRetentionDays, forKey: "clipboardRetentionDays") }
    }

    // 剪切板历史最大条数（0 = 永久）
    var clipboardMaxItems: Int {
        didSet { defaults.set(clipboardMaxItems, forKey: "clipboardMaxItems") }
    }

    // 忽略密码管理器内容（默认开启）
    var ignoreConcealed: Bool {
        didSet { defaults.set(ignoreConcealed, forKey: "ignoreConcealed") }
    }

    // 应用黑名单
    var clipboardBlacklistEnabled: Bool {
        didSet { defaults.set(clipboardBlacklistEnabled, forKey: "clipboardBlacklistEnabled") }
    }
    var clipboardBlacklist: Set<String> {
        didSet { defaults.set(Array(clipboardBlacklist), forKey: "clipboardBlacklist") }
    }

    func isBlacklisted(_ bundleId: String) -> Bool {
        clipboardBlacklistEnabled && clipboardBlacklist.contains(bundleId)
    }

    // 开机自启动
    var launchAtLogin: Bool {
        didSet {
            defaults.set(launchAtLogin, forKey: "launchAtLogin")
            updateLaunchAtLogin()
        }
    }

    // 文件夹监听
    var folderMonitorEnabled: Bool {
        didSet { defaults.set(folderMonitorEnabled, forKey: "folderMonitorEnabled") }
    }
    var watchedFolderPath: String? {
        didSet { defaults.set(watchedFolderPath, forKey: "watchedFolderPath") }
    }
    var autoCopyToClipboard: Bool {
        didSet { defaults.set(autoCopyToClipboard, forKey: "autoCopyToClipboard") }
    }
    var autoShowShelfOnNewFile: Bool {
        didSet { defaults.set(autoShowShelfOnNewFile, forKey: "autoShowShelfOnNewFile") }
    }

    // 窗口位置记忆（仅用于截图/菜单栏/快捷键触发）
    private(set) var shelfLastPositionX: Double {
        didSet { defaults.set(shelfLastPositionX, forKey: "shelfLastPositionX") }
    }
    private(set) var shelfLastPositionY: Double {
        didSet { defaults.set(shelfLastPositionY, forKey: "shelfLastPositionY") }
    }

    var hasSavedShelfPosition: Bool {
        shelfLastPositionX >= 0 && shelfLastPositionY >= 0
    }

    func saveShelfPosition(_ origin: NSPoint) {
        shelfLastPositionX = origin.x
        shelfLastPositionY = origin.y
    }

    func getSavedShelfPosition() -> NSPoint? {
        guard hasSavedShelfPosition else { return nil }
        return NSPoint(x: shelfLastPositionX, y: shelfLastPositionY)
    }

    private let defaults = UserDefaults.standard

    private init() {
        let storedShakes = defaults.integer(forKey: "shakeMinShakes")
        shakeMinShakes = storedShakes != 0 ? storedShakes : 4

        let storedTimeWindow = defaults.double(forKey: "shakeTimeWindow")
        shakeTimeWindow = storedTimeWindow != 0 ? storedTimeWindow : 0.3

        let storedMovement = defaults.double(forKey: "shakeMinMovement")
        shakeMinMovement = storedMovement != 0 ? storedMovement : 30

        // clipboardRetentionDays 默认 0 = 永久保存
        clipboardRetentionDays = defaults.integer(forKey: "clipboardRetentionDays")

        // clipboardMaxItems 默认 0 = 永久保存
        clipboardMaxItems = defaults.integer(forKey: "clipboardMaxItems")

        // ignoreConcealed 默认 true（安全起见）
        ignoreConcealed = defaults.object(forKey: "ignoreConcealed") == nil ? true : defaults.bool(forKey: "ignoreConcealed")

        // 应用黑名单
        clipboardBlacklistEnabled = defaults.bool(forKey: "clipboardBlacklistEnabled")
        if let saved = defaults.array(forKey: "clipboardBlacklist") as? [String] {
            clipboardBlacklist = Set(saved)
        } else {
            clipboardBlacklist = []
        }

        // 读取系统实际状态
        if #available(macOS 13.0, *) {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        } else {
            launchAtLogin = defaults.bool(forKey: "launchAtLogin")
        }

        // 文件夹监听设置
        folderMonitorEnabled = defaults.bool(forKey: "folderMonitorEnabled")
        watchedFolderPath = defaults.string(forKey: "watchedFolderPath")
        // autoCopyToClipboard 默认 true
        autoCopyToClipboard = defaults.object(forKey: "autoCopyToClipboard") == nil ? true : defaults.bool(forKey: "autoCopyToClipboard")
        autoShowShelfOnNewFile = defaults.bool(forKey: "autoShowShelfOnNewFile")

        // 窗口位置记忆（-1 表示未保存）
        let storedX = defaults.object(forKey: "shelfLastPositionX")
        shelfLastPositionX = storedX != nil ? defaults.double(forKey: "shelfLastPositionX") : -1

        let storedY = defaults.object(forKey: "shelfLastPositionY")
        shelfLastPositionY = storedY != nil ? defaults.double(forKey: "shelfLastPositionY") : -1
    }

    private func updateLaunchAtLogin() {
        if #available(macOS 13.0, *) {
            do {
                if launchAtLogin {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                #if DEBUG
                print("Failed to update launch at login: \(error)")
                #endif
            }
        }
    }
}
