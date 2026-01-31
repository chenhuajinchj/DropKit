import Foundation
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

    // 开机自启动
    var launchAtLogin: Bool {
        didSet {
            defaults.set(launchAtLogin, forKey: "launchAtLogin")
            updateLaunchAtLogin()
        }
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

        // 读取系统实际状态
        if #available(macOS 13.0, *) {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        } else {
            launchAtLogin = defaults.bool(forKey: "launchAtLogin")
        }
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
                print("Failed to update launch at login: \(error)")
            }
        }
    }
}
