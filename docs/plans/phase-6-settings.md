# Phase 6: 设置页

> 创建日期：2026-01-29
> 状态：待开发

---

## Phase 概述

**目标**：实现应用设置页面，提供各项配置选项

**预计时间**：第 13-15 天

**成功标准**：
- ✅ 通用设置（启动项、快捷键）
- ✅ 悬浮窗设置（灵敏度、显示位置）
- ✅ 剪切板设置（历史数量、忽略类型）
- ✅ 关于页面
- ✅ 设置持久化

---

## 技术栈总览

本 Phase 涉及的技术栈：

| 组件 | 技术选择 | 原因 |
|------|---------|------|
| 数据模型 | ✅ Codable + UserDefaults | 简单配置存储 |
| UI 框架 | ✅ SwiftUI | 现代 UI |
| 窗口容器 | ✅ NSWindow | 标准窗口 |
| 表单控件 | ✅ Toggle, Slider, Picker | 原生控件 |
| 启动项 | ✅ SMLoginItemSetEnabled | 系统 API |
| 快捷键 | ✅ NSEvent 监听 | 全局快捷键 |

**关键技术**：
- ✅ UserDefaults（设置持久化）
- ✅ @AppStorage（SwiftUI 绑定）
- ✅ SMLoginItemSetEnabled（启动项）
- ✅ NSEvent.addLocalMonitorForEvents（快捷键）

---

## 工具使用指南

### 每个步骤的标准流程

```
1. 阅读步骤说明
   ↓
2. 编写代码
   ↓
3. 使用 XcodeBuildMCP 编译
   ↓
4. 测试功能
   ↓
5. Git commit
```

### 工具说明

**XcodeBuildMCP**（编译工具）：
- ✅ 每个步骤完成后都要编译
- 使用方式：`mcp__xcodebuildmcp__build`

**Axiom Skill**（Swift/SwiftUI 专家）：
- ✅ 遇到编译错误时使用
- ✅ 写复杂 UI 前使用
- ✅ 写系统 API 前使用
- 使用方式：`/using-axiom [问题]`

---

## 步骤详解

---

### 6.1 创建 Settings 数据模型

**技术栈**：
- ✅ 纯 Swift 数据模型
- ✅ Codable（JSON 序列化）
- ✅ UserDefaults 存储
- ❌ 不涉及 UI

**工具使用**：
- 📝 编辑器：编写数据模型
- 🔨 编译：使用 XcodeBuildMCP

**文件**：`Sources/Models/Settings.swift`

**代码结构**：

```swift
import Foundation

/// 应用设置
struct Settings: Codable {

    // MARK: - General Settings

    /// 开机自启动
    var launchAtLogin: Bool = false

    /// 显示菜单栏图标
    var showMenuBarIcon: Bool = true

    // MARK: - Shelf Settings

    /// 摇晃灵敏度 (0.0 - 1.0)
    var shakeSensitivity: Double = 0.5

    /// 最少摇晃次数
    var minShakeCount: Int = 3

    /// 悬浮窗显示位置
    var shelfPosition: ShelfPosition = .mouse

    /// 悬浮窗最大项目数
    var maxShelfItems: Int = 10

    /// 自动隐藏延迟（秒）
    var autoHideDelay: Double = 5.0

    // MARK: - Clipboard Settings

    /// 启用剪切板历史
    var enableClipboardHistory: Bool = true

    /// 最大历史数量
    var maxClipboardItems: Int = 100

    /// 忽略的类型
    var ignoredClipboardTypes: Set<String> = []

    /// 忽略敏感内容（密码等）
    var ignoreSensitiveContent: Bool = true

    // MARK: - Hotkeys

    /// 剪切板历史快捷键
    var clipboardHistoryHotkey: String = "⌘⇧V"

    /// 悬浮窗快捷键
    var shelfHotkey: String = "⌘⇧S"

    // MARK: - Nested Types

    enum ShelfPosition: String, Codable, CaseIterable {
        case mouse = "鼠标位置"
        case center = "屏幕中央"
        case topRight = "右上角"
        case bottomRight = "右下角"
    }

    // MARK: - Default Instance

    static let `default` = Settings()
}

/// 设置管理器
class SettingsManager {

    static let shared = SettingsManager()

    private let userDefaults = UserDefaults.standard
    private let settingsKey = "app_settings"

    private init() {}

    // MARK: - Public Methods

    /// 加载设置
    func load() -> Settings {
        guard let data = userDefaults.data(forKey: settingsKey) else {
            return .default
        }

        do {
            let decoder = JSONDecoder()
            let settings = try decoder.decode(Settings.self, from: data)
            return settings
        } catch {
            print("❌ 加载设置失败: \(error)")
            return .default
        }
    }

    /// 保存设置
    func save(_ settings: Settings) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(settings)
            userDefaults.set(data, forKey: settingsKey)
            print("✅ 保存设置成功")
        } catch {
            print("❌ 保存设置失败: \(error)")
        }
    }

    /// 重置为默认设置
    func reset() {
        userDefaults.removeObject(forKey: settingsKey)
        print("✅ 重置设置成功")
    }
}
```

**详细说明**：

1. **设置分类**：
   - 通用设置：启动项、菜单栏
   - 悬浮窗设置：灵敏度、位置、数量
   - 剪切板设置：历史数量、忽略类型
   - 快捷键设置

2. **数据类型**：
   - Bool：开关选项
   - Double：滑块值（灵敏度）
   - Int：数量限制
   - String：快捷键
   - Enum：位置选择

3. **持久化**：
   - 使用 UserDefaults 存储
   - JSON 序列化
   - 单例模式管理

4. **默认值**：
   - 提供合理的默认配置
   - 加载失败时使用默认值

**测试要点**：
- 保存设置成功
- 加载设置正确
- 重置功能正常
- 默认值合理

**编译**：
使用 mcp__xcodebuildmcp__build 工具编译项目

**提交**：
```bash
git add Sources/Models/Settings.swift
git commit -m "feat: add Settings data model"
```

---

### 6.2 创建 SettingsViewModel（状态管理）

**技术栈**：
- ✅ ObservableObject（SwiftUI 状态管理）
- ✅ @Published（自动通知 UI）
- ✅ Combine（响应式编程）
- ❌ 不涉及 UI

**工具使用**：
- 📝 编辑器：编写 ViewModel
- 🔨 编译：使用 XcodeBuildMCP

**文件**：`Sources/Features/Settings/SettingsViewModel.swift`

**代码结构**：

```swift
import Foundation
import Combine
import ServiceManagement

/// 设置视图模型
class SettingsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var settings: Settings
    
    // MARK: - Private Properties
    
    private let manager = SettingsManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        self.settings = manager.load()
        
        // 监听设置变化，自动保存
        $settings
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .sink { [weak self] settings in
                self?.manager.save(settings)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - General Settings
    
    /// 切换开机自启动
    func toggleLaunchAtLogin() {
        settings.launchAtLogin.toggle()
        applyLaunchAtLogin(settings.launchAtLogin)
    }
    
    private func applyLaunchAtLogin(_ enabled: Bool) {
        // 使用 SMLoginItemSetEnabled
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.dropkit.app"
        let helperBundleIdentifier = "\(bundleIdentifier).LaunchHelper"
        
        if #available(macOS 13.0, *) {
            // macOS 13+ 使用新 API
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
                print("✅ 启动项设置成功: \(enabled)")
            } catch {
                print("❌ 启动项设置失败: \(error)")
            }
        } else {
            // macOS 12 及以下使用旧 API
            let success = SMLoginItemSetEnabled(helperBundleIdentifier as CFString, enabled)
            if success {
                print("✅ 启动项设置成功: \(enabled)")
            } else {
                print("❌ 启动项设置失败")
            }
        }
    }
    
    // MARK: - Shelf Settings
    
    /// 更新摇晃灵敏度
    func updateShakeSensitivity(_ value: Double) {
        settings.shakeSensitivity = value
        // 通知 ShakeDetector 更新
        NotificationCenter.default.post(
            name: .shakeSensitivityChanged,
            object: value
        )
    }
    
    /// 更新最少摇晃次数
    func updateMinShakeCount(_ value: Int) {
        settings.minShakeCount = value
        NotificationCenter.default.post(
            name: .minShakeCountChanged,
            object: value
        )
    }
    
    /// 更新悬浮窗位置
    func updateShelfPosition(_ position: Settings.ShelfPosition) {
        settings.shelfPosition = position
    }
    
    // MARK: - Clipboard Settings
    
    /// 切换剪切板历史
    func toggleClipboardHistory() {
        settings.enableClipboardHistory.toggle()
        
        // 通知 ClipboardMonitor
        if settings.enableClipboardHistory {
            NotificationCenter.default.post(name: .startClipboardMonitoring, object: nil)
        } else {
            NotificationCenter.default.post(name: .stopClipboardMonitoring, object: nil)
        }
    }
    
    /// 更新最大历史数量
    func updateMaxClipboardItems(_ value: Int) {
        settings.maxClipboardItems = value
    }
    
    /// 切换忽略敏感内容
    func toggleIgnoreSensitiveContent() {
        settings.ignoreSensitiveContent.toggle()
    }
    
    // MARK: - Reset
    
    /// 重置所有设置
    func resetToDefaults() {
        manager.reset()
        settings = .default
        
        // 应用默认设置
        applyLaunchAtLogin(false)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let shakeSensitivityChanged = Notification.Name("shakeSensitivityChanged")
    static let minShakeCountChanged = Notification.Name("minShakeCountChanged")
    static let startClipboardMonitoring = Notification.Name("startClipboardMonitoring")
    static let stopClipboardMonitoring = Notification.Name("stopClipboardMonitoring")
}
```

**详细说明**：

1. **自动保存**：
   - 监听 settings 变化
   - 使用 debounce 防抖（0.5 秒）
   - 自动保存到 UserDefaults

2. **启动项管理**：
   - macOS 13+ 使用 SMAppService
   - macOS 12- 使用 SMLoginItemSetEnabled
   - 版本兼容处理

3. **设置应用**：
   - 灵敏度变化通知 ShakeDetector
   - 剪切板开关通知 ClipboardMonitor
   - 使用 NotificationCenter 解耦

4. **重置功能**：
   - 清除 UserDefaults
   - 恢复默认值
   - 应用默认配置

**测试要点**：
- 设置变化自动保存
- 启动项切换正常
- 通知发送正确
- 重置功能正常

**编译**：
使用 mcp__xcodebuildmcp__build 工具编译项目

**提交**：
```bash
git add Sources/Features/Settings/SettingsViewModel.swift
git commit -m "feat: add SettingsViewModel"
```

---

### 6.3 创建 SettingsView（主界面）

**技术栈**：
- ✅ SwiftUI（UI 框架）
- ✅ TabView（标签页）
- ✅ Form（表单布局）
- ✅ SF Symbols（图标）

**工具使用**：
- 📝 编辑器：编写 SwiftUI 视图
- 🔨 编译：使用 XcodeBuildMCP
- ❓ 复杂 UI 前：使用 Axiom skill

**文件**：`Sources/Features/Settings/SettingsView.swift`

**代码结构**：

```swift
import SwiftUI

/// 设置视图
struct SettingsView: View {
    
    @ObservedObject var viewModel: SettingsViewModel
    
    var body: some View {
        TabView {
            // 通用设置
            GeneralSettingsView(viewModel: viewModel)
                .tabItem {
                    Label("通用", systemImage: "gearshape")
                }
                .tag(0)
            
            // 悬浮窗设置
            ShelfSettingsView(viewModel: viewModel)
                .tabItem {
                    Label("悬浮窗", systemImage: "rectangle.stack")
                }
                .tag(1)
            
            // 剪切板设置
            ClipboardSettingsView(viewModel: viewModel)
                .tabItem {
                    Label("剪切板", systemImage: "doc.on.clipboard")
                }
                .tag(2)
            
            // 关于
            AboutView()
                .tabItem {
                    Label("关于", systemImage: "info.circle")
                }
                .tag(3)
        }
        .frame(width: 600, height: 500)
    }
}

// MARK: - Preview

#Preview {
    SettingsView(viewModel: SettingsViewModel())
}
```

**详细说明**：

1. **标签页结构**：
   - 通用设置
   - 悬浮窗设置
   - 剪切板设置
   - 关于页面

2. **布局**：
   - 固定尺寸：600x500
   - TabView 自动切换
   - SF Symbols 图标

3. **子视图**：
   - 每个标签页独立视图
   - 共享 ViewModel
   - 下面步骤实现

**测试要点**：
- 标签页切换正常
- 图标显示正确
- 尺寸合适

**编译**：
使用 mcp__xcodebuildmcp__build 工具编译项目

**提交**：
```bash
git add Sources/Features/Settings/SettingsView.swift
git commit -m "feat: add SettingsView main layout"
```

---

### 6.4 通用设置（GeneralSettingsView）

**技术栈**：
- ✅ SwiftUI Form
- ✅ Toggle（开关）
- ✅ Picker（选择器）
- ✅ Section（分组）

**工具使用**：
- 📝 编辑器：编写 SwiftUI 视图
- 🔨 编译：使用 XcodeBuildMCP

**文件**：`Sources/Features/Settings/GeneralSettingsView.swift`

**代码结构**：

```swift
import SwiftUI

/// 通用设置视图
struct GeneralSettingsView: View {
    
    @ObservedObject var viewModel: SettingsViewModel
    
    var body: some View {
        Form {
            // 启动设置
            Section {
                Toggle(isOn: $viewModel.settings.launchAtLogin) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("开机自启动")
                            .font(.body)
                        Text("登录时自动启动 DropKit")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .onChange(of: viewModel.settings.launchAtLogin) { _ in
                    viewModel.toggleLaunchAtLogin()
                }
                
                Toggle(isOn: $viewModel.settings.showMenuBarIcon) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("显示菜单栏图标")
                            .font(.body)
                        Text("在菜单栏显示 DropKit 图标")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("启动")
            }
            
            // 快捷键设置
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("剪切板历史")
                            .font(.body)
                        Text("打开剪切板历史窗口")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(viewModel.settings.clipboardHistoryHotkey)
                        .font(.system(.body, design: .monospaced))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("悬浮窗")
                            .font(.body)
                        Text("显示/隐藏悬浮窗")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(viewModel.settings.shelfHotkey)
                        .font(.system(.body, design: .monospaced))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            } header: {
                Text("快捷键")
            } footer: {
                Text("快捷键暂不支持自定义")
                    .font(.caption)
            }
            
            // 外观设置
            Section {
                Picker("主题", selection: .constant("auto")) {
                    Text("跟随系统").tag("auto")
                    Text("浅色").tag("light")
                    Text("深色").tag("dark")
                }
                .disabled(true)
                
                Picker("语言", selection: .constant("zh-CN")) {
                    Text("简体中文").tag("zh-CN")
                    Text("English").tag("en")
                }
                .disabled(true)
            } header: {
                Text("外观")
            } footer: {
                Text("主题和语言设置即将推出")
                    .font(.caption)
            }
            
            // 高级设置
            Section {
                Button("重置所有设置") {
                    viewModel.resetToDefaults()
                }
                .foregroundColor(.red)
            } header: {
                Text("高级")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Preview

#Preview {
    GeneralSettingsView(viewModel: SettingsViewModel())
        .frame(width: 600, height: 500)
}
```

**详细说明**：

1. **启动设置**：
   - 开机自启动开关
   - 菜单栏图标开关
   - 说明文字

2. **快捷键设置**：
   - 显示当前快捷键
   - 等宽字体显示
   - 暂不支持自定义

3. **外观设置**：
   - 主题选择（禁用）
   - 语言选择（禁用）
   - 未来功能提示

4. **高级设置**：
   - 重置按钮
   - 红色警告色

**测试要点**：
- 开关切换正常
- 快捷键显示正确
- 重置功能正常
- 布局美观

**编译**：
使用 mcp__xcodebuildmcp__build 工具编译项目

**提交**：
```bash
git add Sources/Features/Settings/GeneralSettingsView.swift
git commit -m "feat: add GeneralSettingsView"
```

---

### 6.5 悬浮窗设置（ShelfSettingsView）

**技术栈**：
- ✅ SwiftUI Form
- ✅ Slider（滑块）
- ✅ Stepper（步进器）
- ✅ Picker（选择器）

**工具使用**：
- 📝 编辑器：编写 SwiftUI 视图
- 🔨 编译：使用 XcodeBuildMCP

**文件**：`Sources/Features/Settings/ShelfSettingsView.swift`

**代码结构**：

```swift
import SwiftUI

/// 悬浮窗设置视图
struct ShelfSettingsView: View {
    
    @ObservedObject var viewModel: SettingsViewModel
    
    var body: some View {
        Form {
            // 触发设置
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("摇晃灵敏度")
                            .font(.body)
                        
                        Spacer()
                        
                        Text(sensitivityLabel)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(
                        value: $viewModel.settings.shakeSensitivity,
                        in: 0.0...1.0,
                        step: 0.1
                    ) {
                        Text("灵敏度")
                    } minimumValueLabel: {
                        Text("低")
                            .font(.caption)
                    } maximumValueLabel: {
                        Text("高")
                            .font(.caption)
                    }
                    .onChange(of: viewModel.settings.shakeSensitivity) { value in
                        viewModel.updateShakeSensitivity(value)
                    }
                    
                    Text("灵敏度越高，越容易触发悬浮窗")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Stepper(
                    value: $viewModel.settings.minShakeCount,
                    in: 2...5
                ) {
                    HStack {
                        Text("最少摇晃次数")
                        Spacer()
                        Text("\(viewModel.settings.minShakeCount) 次")
                            .foregroundColor(.secondary)
                    }
                }
                .onChange(of: viewModel.settings.minShakeCount) { value in
                    viewModel.updateMinShakeCount(value)
                }
            } header: {
                Text("触发")
            }
            
            // 显示设置
            Section {
                Picker("显示位置", selection: $viewModel.settings.shelfPosition) {
                    ForEach(Settings.ShelfPosition.allCases, id: \.self) { position in
                        Text(position.rawValue).tag(position)
                    }
                }
                .onChange(of: viewModel.settings.shelfPosition) { position in
                    viewModel.updateShelfPosition(position)
                }
                
                Stepper(
                    value: $viewModel.settings.maxShelfItems,
                    in: 5...20
                ) {
                    HStack {
                        Text("最大项目数")
                        Spacer()
                        Text("\(viewModel.settings.maxShelfItems) 个")
                            .foregroundColor(.secondary)
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("自动隐藏延迟")
                            .font(.body)
                        
                        Spacer()
                        
                        Text("\(String(format: "%.1f", viewModel.settings.autoHideDelay)) 秒")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(
                        value: $viewModel.settings.autoHideDelay,
                        in: 1.0...10.0,
                        step: 0.5
                    )
                    
                    Text("悬浮窗无操作后自动隐藏的时间")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("显示")
            }
            
            // 预览
            Section {
                VStack(spacing: 16) {
                    Text("预览")
                        .font(.headline)
                    
                    // 简单的预览示意图
                    HStack(spacing: 8) {
                        ForEach(0..<min(3, viewModel.settings.maxShelfItems), id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.accentColor.opacity(0.2))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Image(systemName: "doc")
                                        .foregroundColor(.accentColor)
                                )
                        }
                    }
                    
                    Text("悬浮窗将显示在\(viewModel.settings.shelfPosition.rawValue)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
        }
        .formStyle(.grouped)
        .padding()
    }
    
    // MARK: - Computed Properties
    
    private var sensitivityLabel: String {
        let value = viewModel.settings.shakeSensitivity
        if value < 0.3 {
            return "低"
        } else if value < 0.7 {
            return "中"
        } else {
            return "高"
        }
    }
}

// MARK: - Preview

#Preview {
    ShelfSettingsView(viewModel: SettingsViewModel())
        .frame(width: 600, height: 500)
}
```

**详细说明**：

1. **触发设置**：
   - 摇晃灵敏度滑块（0.0-1.0）
   - 最少摇晃次数步进器（2-5）
   - 实时显示当前值

2. **显示设置**：
   - 位置选择器（鼠标/中央/角落）
   - 最大项目数步进器（5-20）
   - 自动隐藏延迟滑块（1-10 秒）

3. **预览区域**：
   - 简单的视觉预览
   - 显示当前配置效果
   - 位置说明文字

4. **交互反馈**：
   - onChange 实时应用设置
   - 显示当前值
   - 说明文字

**测试要点**：
- 滑块拖动流畅
- 步进器增减正常
- 选择器切换正常
- 预览更新正确

**编译**：
使用 mcp__xcodebuildmcp__build 工具编译项目

**提交**：
```bash
git add Sources/Features/Settings/ShelfSettingsView.swift
git commit -m "feat: add ShelfSettingsView"
```

---

### 6.6 剪切板设置（ClipboardSettingsView）

**技术栈**：
- ✅ SwiftUI Form
- ✅ Toggle（开关）
- ✅ Stepper（步进器）
- ✅ List（列表）

**工具使用**：
- 📝 编辑器：编写 SwiftUI 视图
- 🔨 编译：使用 XcodeBuildMCP

**文件**：`Sources/Features/Settings/ClipboardSettingsView.swift`

**代码结构**：

```swift
import SwiftUI

/// 剪切板设置视图
struct ClipboardSettingsView: View {
    
    @ObservedObject var viewModel: SettingsViewModel
    
    var body: some View {
        Form {
            // 基本设置
            Section {
                Toggle(isOn: $viewModel.settings.enableClipboardHistory) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("启用剪切板历史")
                            .font(.body)
                        Text("自动记录复制的内容")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .onChange(of: viewModel.settings.enableClipboardHistory) { _ in
                    viewModel.toggleClipboardHistory()
                }
                
                Stepper(
                    value: $viewModel.settings.maxClipboardItems,
                    in: 50...500,
                    step: 50
                ) {
                    HStack {
                        Text("最大历史数量")
                        Spacer()
                        Text("\(viewModel.settings.maxClipboardItems) 条")
                            .foregroundColor(.secondary)
                    }
                }
                .onChange(of: viewModel.settings.maxClipboardItems) { value in
                    viewModel.updateMaxClipboardItems(value)
                }
                .disabled(!viewModel.settings.enableClipboardHistory)
            } header: {
                Text("基本")
            }
            
            // 隐私设置
            Section {
                Toggle(isOn: $viewModel.settings.ignoreSensitiveContent) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("忽略敏感内容")
                            .font(.body)
                        Text("不记录密码、信用卡等敏感信息")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .onChange(of: viewModel.settings.ignoreSensitiveContent) { _ in
                    viewModel.toggleIgnoreSensitiveContent()
                }
                .disabled(!viewModel.settings.enableClipboardHistory)
            } header: {
                Text("隐私")
            } footer: {
                Text("敏感内容检测基于启发式规则，可能不完全准确")
                    .font(.caption)
            }
            
            // 忽略类型
            Section {
                Toggle(isOn: .constant(false)) {
                    Text("忽略图片")
                }
                .disabled(true)
                
                Toggle(isOn: .constant(false)) {
                    Text("忽略文件")
                }
                .disabled(true)
                
                Toggle(isOn: .constant(false)) {
                    Text("忽略 URL")
                }
                .disabled(true)
            } header: {
                Text("忽略类型")
            } footer: {
                Text("类型过滤功能即将推出")
                    .font(.caption)
            }
            
            // 存储信息
            Section {
                HStack {
                    Text("存储位置")
                    Spacer()
                    Text("~/Library/Application Support/DropKit")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("当前大小")
                    Spacer()
                    Text("计算中...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Button("清空历史记录") {
                    // 清空逻辑
                }
                .foregroundColor(.red)
            } header: {
                Text("存储")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Preview

#Preview {
    ClipboardSettingsView(viewModel: SettingsViewModel())
        .frame(width: 600, height: 500)
}
```

**详细说明**：

1. **基本设置**：
   - 启用/禁用剪切板历史
   - 最大历史数量（50-500）
   - 禁用时灰显其他选项

2. **隐私设置**：
   - 忽略敏感内容开关
   - 说明文字
   - 提示检测规则

3. **忽略类型**：
   - 图片、文件、URL 过滤
   - 暂时禁用（未来功能）
   - 提示即将推出

4. **存储信息**：
   - 显示存储位置
   - 显示当前大小
   - 清空历史按钮

**测试要点**：
- 开关切换正常
- 步进器增减正常
- 禁用状态正确
- 清空功能正常

**编译**：
使用 mcp__xcodebuildmcp__build 工具编译项目

**提交**：
```bash
git add Sources/Features/Settings/ClipboardSettingsView.swift
git commit -m "feat: add ClipboardSettingsView"
```

---

### 6.7 关于页面（AboutView）

**技术栈**：
- ✅ SwiftUI
- ✅ VStack 布局
- ✅ Link（超链接）
- ✅ SF Symbols

**工具使用**：
- 📝 编辑器：编写 SwiftUI 视图
- 🔨 编译：使用 XcodeBuildMCP

**文件**：`Sources/Features/Settings/AboutView.swift`

**代码结构**：

```swift
import SwiftUI

/// 关于视图
struct AboutView: View {
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // 应用图标
            Image(systemName: "shippingbox.fill")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
            
            // 应用名称和版本
            VStack(spacing: 8) {
                Text("DropKit")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("版本 2.0.0")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // 描述
            Text("macOS 菜单栏工具，提供悬浮窗和剪切板历史功能")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
            
            // 链接
            VStack(spacing: 12) {
                Link(destination: URL(string: "https://github.com/yourusername/dropkit")!) {
                    HStack {
                        Image(systemName: "link")
                        Text("GitHub 仓库")
                    }
                }
                
                Link(destination: URL(string: "https://github.com/yourusername/dropkit/issues")!) {
                    HStack {
                        Image(systemName: "exclamationmark.bubble")
                        Text("反馈问题")
                    }
                }
                
                Link(destination: URL(string: "https://github.com/yourusername/dropkit/blob/main/LICENSE")!) {
                    HStack {
                        Image(systemName: "doc.text")
                        Text("开源许可")
                    }
                }
            }
            
            Spacer()
            
            // 版权信息
            VStack(spacing: 4) {
                Text("© 2026 DropKit")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("使用 SwiftUI 和 AppKit 构建")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Preview

#Preview {
    AboutView()
        .frame(width: 600, height: 500)
}
```

**详细说明**：

1. **应用信息**：
   - 应用图标（SF Symbol）
   - 应用名称和版本
   - 简短描述

2. **链接区域**：
   - GitHub 仓库
   - 反馈问题
   - 开源许可
   - 使用 Link 组件

3. **版权信息**：
   - 版权声明
   - 技术栈说明
   - 底部显示

4. **布局**：
   - 垂直居中
   - 合理间距
   - 美观简洁

**测试要点**：
- 链接可点击
- 布局居中
- 文字清晰
- 美观大方

**编译**：
使用 mcp__xcodebuildmcp__build 工具编译项目

**提交**：
```bash
git add Sources/Features/Settings/AboutView.swift
git commit -m "feat: add AboutView"
```

---

### 6.8 集成到 AppState 和创建 SettingsWindow

**技术栈**：
- ✅ NSWindow（窗口容器）
- ✅ NSHostingView（SwiftUI 桥接）
- ✅ 依赖注入
- ❌ 不涉及新数据模型

**工具使用**：
- 📝 编辑器：修改现有文件
- 🔨 编译：使用 XcodeBuildMCP

**文件 1**：`Sources/Features/Settings/SettingsWindow.swift`（新建）

**代码结构**：

```swift
import AppKit
import SwiftUI

/// 设置窗口
class SettingsWindow: NSWindow {
    
    private let viewModel: SettingsViewModel
    
    // MARK: - Initialization
    
    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
        
        // 窗口配置
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        setupWindow()
        setupContent()
        centerWindow()
    }
    
    // MARK: - Setup
    
    private func setupWindow() {
        title = "设置"
        
        // 窗口行为
        isReleasedWhenClosed = false
        
        // 固定尺寸（不可调整）
        styleMask.remove(.resizable)
        
        // 标题栏样式
        titlebarAppearsTransparent = false
        
        // 工具栏样式
        toolbarStyle = .unified
    }
    
    private func setupContent() {
        let contentView = SettingsView(viewModel: viewModel)
        self.contentView = NSHostingView(rootView: contentView)
    }
    
    private func centerWindow() {
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let windowRect = frame
            
            let x = screenRect.midX - windowRect.width / 2
            let y = screenRect.midY - windowRect.height / 2
            
            setFrameOrigin(NSPoint(x: x, y: y))
        }
    }
    
    // MARK: - Public Methods
    
    /// 显示窗口
    func show() {
        makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    /// 隐藏窗口
    func hide() {
        orderOut(nil)
    }
}
```

**文件 2**：`Sources/AppState.swift`（修改）

**代码修改**：

```swift
import SwiftUI
import AppKit

@MainActor
class AppState: ObservableObject {
    
    // MARK: - Existing Properties
    
    // ... 现有属性 ...
    
    // MARK: - Settings Properties (新增)
    
    let settingsViewModel: SettingsViewModel
    private(set) var settingsWindow: SettingsWindow?
    
    // MARK: - Initialization
    
    init() {
        // ... 现有初始化代码 ...
        
        // 初始化设置组件
        self.settingsViewModel = SettingsViewModel()
        
        // 创建设置窗口
        self.settingsWindow = SettingsWindow(viewModel: settingsViewModel)
        
        // 应用设置到其他组件
        applySettings()
        
        // 监听设置变化
        setupSettingsObserver()
    }
    
    // MARK: - Settings Methods (新增)
    
    /// 显示设置窗口
    func showSettings() {
        settingsWindow?.show()
    }
    
    /// 隐藏设置窗口
    func hideSettings() {
        settingsWindow?.hide()
    }
    
    // MARK: - Private Methods (新增)
    
    private func applySettings() {
        let settings = settingsViewModel.settings
        
        // 应用到 ShakeDetector
        shakeDetector.sensitivity = settings.shakeSensitivity
        shakeDetector.minShakes = settings.minShakeCount
        
        // 应用到 ClipboardMonitor
        if settings.enableClipboardHistory {
            clipboardMonitor.startMonitoring()
        } else {
            clipboardMonitor.stopMonitoring()
        }
    }
    
    private func setupSettingsObserver() {
        // 监听灵敏度变化
        NotificationCenter.default.addObserver(
            forName: .shakeSensitivityChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let value = notification.object as? Double {
                self?.shakeDetector.sensitivity = value
            }
        }
        
        // 监听摇晃次数变化
        NotificationCenter.default.addObserver(
            forName: .minShakeCountChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let value = notification.object as? Int {
                self?.shakeDetector.minShakes = value
            }
        }
        
        // 监听剪切板开关
        NotificationCenter.default.addObserver(
            forName: .startClipboardMonitoring,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.clipboardMonitor.startMonitoring()
        }
        
        NotificationCenter.default.addObserver(
            forName: .stopClipboardMonitoring,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.clipboardMonitor.stopMonitoring()
        }
    }
}
```

**文件 3**：`Sources/Features/MenuBar/MenuBarView.swift`（修改）

**代码修改**：

```swift
// 在 MenuBarView.swift 中添加设置菜单项

struct MenuBarView: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        // ... 现有菜单项 ...
        
        Divider()
        
        // 设置菜单项（新增）
        Button("设置...") {
            appState.showSettings()
        }
        .keyboardShortcut(",", modifiers: .command)
        
        // ... 其他菜单项 ...
    }
}
```

**详细说明**：

1. **SettingsWindow**：
   - 标准窗口样式
   - 固定尺寸（不可调整）
   - 居中显示
   - 不释放（isReleasedWhenClosed = false）

2. **AppState 集成**：
   - 创建 SettingsViewModel
   - 创建 SettingsWindow
   - 应用设置到其他组件
   - 监听设置变化

3. **设置应用**：
   - 灵敏度 → ShakeDetector
   - 摇晃次数 → ShakeDetector
   - 剪切板开关 → ClipboardMonitor

4. **菜单集成**：
   - 添加设置菜单项
   - 快捷键 ⌘,
   - 点击显示设置窗口

**测试要点**：
- 设置窗口显示正常
- 设置变化实时应用
- 快捷键 ⌘, 正常
- 菜单项点击正常
- 窗口关闭后不释放

**编译**：
使用 mcp__xcodebuildmcp__build 工具编译项目

**提交**：
```bash
git add Sources/Features/Settings/SettingsWindow.swift Sources/AppState.swift Sources/Features/MenuBar/MenuBarView.swift
git commit -m "feat: integrate settings into AppState"
```

---

## 下一步

完成 Phase 6 后，你已经实现了完整的设置页面：

✅ **已完成**：
- 设置数据模型（Settings + SettingsManager）
- 状态管理（SettingsViewModel）
- 主界面（SettingsView）
- 通用设置（GeneralSettingsView）
- 悬浮窗设置（ShelfSettingsView）
- 剪切板设置（ClipboardSettingsView）
- 关于页面（AboutView）
- 窗口容器（SettingsWindow）
- 集成到应用（AppState）

🎯 **下一步：Phase 7 - 收尾发布**

进入 `phase-7-polish-release.md`，实现：
- 应用图标设计
- 菜单栏图标优化
- 性能优化
- 错误处理完善
- 用户引导（首次启动）
- 打包配置
- 测试清单
- 发布准备

---

## 附录：常见问题

### Q1: 启动项设置不生效

**可能原因**：
- macOS 版本不兼容
- Helper 应用未配置
- 权限问题

**解决方案**：
```swift
// 检查 macOS 版本
if #available(macOS 13.0, *) {
    // 使用新 API
} else {
    // 使用旧 API
    // 需要配置 Helper 应用
}

// 检查状态
let status = SMAppService.mainApp.status
print("Login item status: \(status)")
```

### Q2: 设置不保存

**可能原因**：
- UserDefaults 写入失败
- JSON 编码失败
- debounce 时间过长

**解决方案**：
```swift
// 手动保存
SettingsManager.shared.save(settings)

// 检查保存结果
if let data = UserDefaults.standard.data(forKey: "app_settings") {
    print("Settings saved: \(data.count) bytes")
} else {
    print("Settings not saved")
}

// 减少 debounce 时间
.debounce(for: 0.3, scheduler: DispatchQueue.main)
```

### Q3: 设置变化不生效

**可能原因**：
- 通知未发送
- 通知未监听
- 组件未更新

**解决方案**：
```swift
// 检查通知发送
NotificationCenter.default.post(
    name: .shakeSensitivityChanged,
    object: value
)
print("Notification posted: shakeSensitivityChanged")

// 检查通知接收
NotificationCenter.default.addObserver(
    forName: .shakeSensitivityChanged,
    object: nil,
    queue: .main
) { notification in
    print("Notification received: \(notification.object ?? "nil")")
}
```

### Q4: 窗口显示位置不对

**可能原因**：
- 多显示器环境
- 屏幕坐标计算错误
- 窗口尺寸变化

**解决方案**：
```swift
// 使用主屏幕
if let screen = NSScreen.main {
    let screenRect = screen.visibleFrame
    // 计算居中位置
}

// 或使用鼠标所在屏幕
if let screen = NSScreen.screens.first(where: { screen in
    NSMouseInRect(NSEvent.mouseLocation, screen.frame, false)
}) {
    // 在该屏幕居中
}
```

### Q5: 快捷键冲突

**可能原因**：
- 系统快捷键占用
- 其他应用占用
- 快捷键未注册

**解决方案**：
```swift
// 使用不同的快捷键
// ⌘, → ⌘⌥,
.keyboardShortcut(",", modifiers: [.command, .option])

// 或使用全局快捷键库
// 如 MASShortcut、HotKey
```

---

**Phase 6 完成！** 🎉

