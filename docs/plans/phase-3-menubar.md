# Phase 3: 菜单栏

> 创建日期：2026-01-29
> 状态：待开发

---

## Phase 概述

**目标**：实现菜单栏图标和菜单项

**预计时间**：第 6 天

**成功标准**：
- ✅ 菜单栏图标显示
- ✅ 菜单项功能正常
- ✅ 快捷键绑定
- ✅ 隐藏 Dock 图标

---

## 技术栈总览

本 Phase 涉及的技术栈：

| 组件 | 技术选择 | 原因 |
|------|---------|------|
| 菜单栏 | ✅ NSStatusItem (AppKit) | 完整控制菜单栏 |
| 菜单 | ✅ NSMenu + NSMenuItem | 标准菜单 API |
| 快捷键 | ✅ Carbon API | 全局快捷键支持 |
| 配置 | ✅ Info.plist | 隐藏 Dock 图标 |

**禁止使用**：
- ❌ MenuBarExtra（用 NSStatusItem）
- ❌ SwiftUI Menu（用 NSMenu）

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
- ✅ 写 AppKit 菜单代码前使用
- 使用方式：`/using-axiom [问题]`

---

## 步骤详解

---

### 3.1 创建 StatusBarController

**技术栈**：
- ✅ NSStatusItem (AppKit)
- ✅ NSMenu + NSMenuItem
- ✅ @objc 方法（菜单动作）
- ❌ 不使用 MenuBarExtra

**工具使用**：
- 📝 编辑器：编写 AppKit 代码
- 🔨 编译：使用 XcodeBuildMCP
- ❓ AppKit 前：使用 Axiom skill 查询 NSStatusItem 用法

**文件**：`Sources/Features/MenuBar/StatusBarController.swift`

**代码结构**：

```swift
import AppKit

/// 菜单栏控制器
class StatusBarController {
    private var statusItem: NSStatusItem?
    private var menu: NSMenu?

    // 回调
    var onShowShelf: (() -> Void)?
    var onShowClipboard: (() -> Void)?
    var onShowSettings: (() -> Void)?
    var onShowAbout: (() -> Void)?
    var onQuit: (() -> Void)?

    init() {
        setupStatusItem()
        setupMenu()
    }

    private func setupStatusItem() {
        // 创建状态栏项目
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        // 设置图标
        if let button = statusItem?.button {
            // Phase 3: 使用系统图标，Phase 4 替换为自定义图标
            button.image = NSImage(systemSymbolName: "tray.fill", accessibilityDescription: "DropKit")
            button.image?.isTemplate = true
        }

        print("StatusBar item created")
    }

    private func setupMenu() {
        let menu = NSMenu()

        // 显示悬浮窗
        let shelfItem = NSMenuItem(
            title: "显示悬浮窗",
            action: #selector(showShelfAction),
            keyEquivalent: "s"
        )
        shelfItem.keyEquivalentModifierMask = [.command, .shift]
        shelfItem.target = self
        menu.addItem(shelfItem)

        // 剪切板历史
        let clipboardItem = NSMenuItem(
            title: "剪切板历史",
            action: #selector(showClipboardAction),
            keyEquivalent: "v"
        )
        clipboardItem.keyEquivalentModifierMask = [.command, .shift]
        clipboardItem.target = self
        menu.addItem(clipboardItem)

        menu.addItem(NSMenuItem.separator())

        // 设置
        let settingsItem = NSMenuItem(
            title: "设置...",
            action: #selector(showSettingsAction),
            keyEquivalent: ","
        )
        settingsItem.keyEquivalentModifierMask = [.command]
        settingsItem.target = self
        menu.addItem(settingsItem)

        // 关于
        let aboutItem = NSMenuItem(
            title: "关于 DropKit",
            action: #selector(showAboutAction),
            keyEquivalent: ""
        )
        aboutItem.target = self
        menu.addItem(aboutItem)

        menu.addItem(NSMenuItem.separator())

        // 退出
        let quitItem = NSMenuItem(
            title: "退出 DropKit",
            action: #selector(quitAction),
            keyEquivalent: "q"
        )
        quitItem.keyEquivalentModifierMask = [.command]
        quitItem.target = self
        menu.addItem(quitItem)

        self.menu = menu
        statusItem?.menu = menu

        print("StatusBar menu created")
    }

    // MARK: - Actions

    @objc private func showShelfAction() {
        onShowShelf?()
    }

    @objc private func showClipboardAction() {
        onShowClipboard?()
    }

    @objc private func showSettingsAction() {
        onShowSettings?()
    }

    @objc private func showAboutAction() {
        onShowAbout?()
    }

    @objc private func quitAction() {
        onQuit?()
    }
}
```

**详细说明**：

1. **NSStatusItem**：
   - 使用 `NSStatusBar.system.statusItem` 创建
   - 长度：`squareLength`（正方形）
   - 图标：系统 SF Symbol（Phase 3）

2. **菜单项**：
   - 显示悬浮窗：⌘⇧S
   - 剪切板历史：⌘⇧V
   - 设置：⌘,
   - 关于：无快捷键
   - 退出：⌘Q

3. **回调机制**：
   - 使用闭包回调
   - AppDelegate 设置回调处理逻辑

**测试要点**：
- 菜单栏图标显示
- 点击图标显示菜单
- 菜单项点击触发回调
- 快捷键正常工作

**编译**：
使用 mcp__xcodebuildmcp__build 工具编译项目

**提交**：
```bash
git add Sources/Features/MenuBar/StatusBarController.swift
git commit -m "feat: add StatusBarController"
```

---

### 3.2 集成到 AppDelegate

**技术栈**：
- ✅ AppKit AppDelegate
- ✅ 回调闭包
- ❌ 不涉及 UI

**工具使用**：
- 📝 编辑器：修改 AppDelegate.swift
- 🔨 编译：使用 XcodeBuildMCP

**修改文件**：`Sources/App/AppDelegate.swift`

**添加属性**：

```swift
private var statusBarController: StatusBarController?
```

**在 `applicationDidFinishLaunching` 中添加**：

```swift
setupStatusBar()
```

**添加方法**：

```swift
private func setupStatusBar() {
    let controller = StatusBarController()
    self.statusBarController = controller

    // 显示悬浮窗
    controller.onShowShelf = { [weak self] in
        self?.shelfPanel?.show()
    }

    // 剪切板历史（Phase 5 实现）
    controller.onShowClipboard = {
        print("Show clipboard - not implemented yet")
    }

    // 设置（Phase 6 实现）
    controller.onShowSettings = {
        print("Show settings - not implemented yet")
    }

    // 关于（Phase 7 实现）
    controller.onShowAbout = {
        print("Show about - not implemented yet")
    }

    // 退出
    controller.onQuit = {
        NSApplication.shared.terminate(nil)
    }

    print("StatusBar initialized")
}
```

**详细说明**：

1. **回调设置**：
   - 显示悬浮窗：调用 shelfPanel?.show()
   - 其他功能：暂时打印占位信息
   - 退出：调用 NSApplication.shared.terminate

2. **占位功能**：
   - 剪切板历史：Phase 5 实现
   - 设置：Phase 6 实现
   - 关于：Phase 7 实现

**编译**：
使用 mcp__xcodebuildmcp__build 工具编译项目

**提交**：
```bash
git add Sources/App/AppDelegate.swift
git commit -m "feat: integrate StatusBarController into AppDelegate"
```

---

### 3.3 隐藏 Dock 图标

**技术栈**：
- ✅ Info.plist 配置
- ❌ 不涉及代码

**工具使用**：
- 📝 编辑器：修改 Info.plist
- 🔨 编译：使用 XcodeBuildMCP

**修改文件**：`Info.plist`

**添加键值**：

```xml
<key>LSUIElement</key>
<true/>
```

**说明**：
- `LSUIElement = true`：应用不显示在 Dock
- 只显示菜单栏图标
- 典型的菜单栏应用配置

**编译**：
使用 mcp__xcodebuildmcp__build 工具编译项目

**提交**：
```bash
git add DropKit/Info.plist
git commit -m "chore: hide Dock icon (LSUIElement)"
```

---

### 3.4 注册全局快捷键

**技术栈**：
- ✅ Carbon API（全局快捷键）
- ✅ EventHotKey 系列 API
- ❌ 不使用 NSEvent（只能监听应用内）

**工具使用**：
- 📝 编辑器：编写 Carbon 代码
- 🔨 编译：使用 XcodeBuildMCP
- ❓ Carbon API 前：使用 Axiom skill

**文件**：`Sources/Services/HotKeyManager.swift`

**代码结构**：

```swift
import AppKit
import Carbon

/// 全局快捷键管理器
class HotKeyManager {
    private var hotKeys: [EventHotKeyID: EventHotKeyRef] = [:]
    private var handlers: [EventHotKeyID: () -> Void] = [:]

    static let shared = HotKeyManager()

    private init() {
        setupEventHandler()
    }

    /// 注册快捷键
    func register(
        keyCode: UInt32,
        modifiers: UInt32,
        handler: @escaping () -> Void
    ) -> EventHotKeyID? {
        let hotKeyID = EventHotKeyID(
            signature: OSType(0x4B455920), // 'KEY '
            id: UInt32(hotKeys.count + 1)
        )

        var hotKeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )

        guard status == noErr, let ref = hotKeyRef else {
            print("Failed to register hotkey")
            return nil
        }

        hotKeys[hotKeyID] = ref
        handlers[hotKeyID] = handler

        print("Registered hotkey: \(keyCode)")
        return hotKeyID
    }

    /// 注销快捷键
    func unregister(id: EventHotKeyID) {
        if let ref = hotKeys[id] {
            UnregisterEventHotKey(ref)
            hotKeys.removeValue(forKey: id)
            handlers.removeValue(forKey: id)
        }
    }

    private func setupEventHandler() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetEventDispatcherTarget(),
            { (_, event, userData) -> OSStatus in
                var hotKeyID = EventHotKeyID()
                GetEventParameter(
                    event,
                    UInt32(kEventParamDirectObject),
                    UInt32(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )

                if let manager = userData?.assumingMemoryBound(to: HotKeyManager.self).pointee {
                    manager.handlers[hotKeyID]?()
                }

                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            nil
        )
    }
}
```

**详细说明**：

1. **Carbon API**：
   - RegisterEventHotKey：注册全局快捷键
   - InstallEventHandler：安装事件处理器
   - 支持应用在后台时也能响应

2. **单例模式**：
   - shared 实例
   - 全局唯一

3. **回调机制**：
   - 字典存储 handler
   - 按键触发时调用对应 handler

**测试要点**：
- 快捷键能注册成功
- 按下快捷键触发回调
- 应用在后台时也能响应

**编译**：
使用 mcp__xcodebuildmcp__build 工具编译项目

**提交**：
```bash
git add Sources/Services/HotKeyManager.swift
git commit -m "feat: add HotKeyManager for global shortcuts"
```

---

### 3.5 在 AppDelegate 中注册快捷键

**技术栈**：
- ✅ HotKeyManager
- ✅ Carbon 键码
- ❌ 不涉及 UI

**工具使用**：
- 📝 编辑器：修改 AppDelegate.swift
- 🔨 编译：使用 XcodeBuildMCP

**修改文件**：`Sources/App/AppDelegate.swift`

**在 `applicationDidFinishLaunching` 中添加**：

```swift
setupHotKeys()
```

**添加方法**：

```swift
private func setupHotKeys() {
    // ⌘⇧S - 显示悬浮窗
    HotKeyManager.shared.register(
        keyCode: 1, // S
        modifiers: UInt32(cmdKey | shiftKey)
    ) { [weak self] in
        self?.shelfPanel?.show()
    }

    // ⌘⇧V - 剪切板历史（Phase 5 实现）
    HotKeyManager.shared.register(
        keyCode: 9, // V
        modifiers: UInt32(cmdKey | shiftKey)
    ) { [weak self] in
        print("Show clipboard - not implemented yet")
    }

    print("HotKeys registered")
}
```

**详细说明**：

1. **键码**：
   - S = 1
   - V = 9
   - 使用 Carbon 键码

2. **修饰键**：
   - cmdKey：Command 键
   - shiftKey：Shift 键
   - 使用位或运算组合

**编译**：
使用 mcp__xcodebuildmcp__build 工具编译项目

**提交**：
```bash
git add Sources/App/AppDelegate.swift
git commit -m "feat: register global hotkeys"
```

---

### 3.6 Phase 3 测试清单

**技术栈**：
- ✅ XcodeBuild（编译测试）
- ✅ 手动功能测试
- ❌ 暂不涉及自动化测试

**工具使用**：
- 🔨 编译：使用 XcodeBuildMCP
- 📋 测试：手动逐项验证

**编译测试**：
```bash
cd "/Users/chenhuajin/Desktop/Dropkit v2 /DropKit"
xcodebuild -scheme DropKit -configuration Debug build
```

**功能测试清单**：

| # | 测试项 | 操作步骤 | 预期结果 | 状态 |
|---|--------|----------|----------|------|
| 1 | 菜单栏图标 | 启动应用 | 菜单栏显示图标 | ⬜ |
| 2 | Dock 隐藏 | 查看 Dock | 应用不在 Dock 中 | ⬜ |
| 3 | 点击图标 | 点击菜单栏图标 | 显示菜单 | ⬜ |
| 4 | 显示悬浮窗 | 点击菜单项 | 悬浮窗显示 | ⬜ |
| 5 | 快捷键 ⌘⇧S | 按下快捷键 | 悬浮窗显示 | ⬜ |
| 6 | 快捷键 ⌘⇧V | 按下快捷键 | 控制台输出提示 | ⬜ |
| 7 | 快捷键 ⌘, | 按下快捷键 | 控制台输出提示 | ⬜ |
| 8 | 退出菜单 | 点击退出 | 应用退出 | ⬜ |
| 9 | 快捷键 ⌘Q | 按下快捷键 | 应用退出 | ⬜ |
| 10 | 菜单分隔符 | 查看菜单 | 分隔符正确显示 | ⬜ |

**测试说明**：
- 所有测试项必须通过才能进入 Phase 4
- 发现问题立即修复，不要累积
- 每修复一个问题，重新编译测试

---

### 3.7 Phase 3 完成提交

**技术栈**：
- ✅ Git 版本控制
- ❌ 不涉及代码编写

**工具使用**：
- 📝 Git 命令行
- ✅ 使用 build-macos-apps skill 完整验证

**提交命令**：

```bash
git add -A
git commit -m "feat: Phase 3 complete - menu bar

Phase 3 完成：
- StatusBarController 菜单栏控制器
- HotKeyManager 全局快捷键管理
- 菜单项和快捷键绑定
- 隐藏 Dock 图标

功能：
- 菜单栏图标和菜单
- 显示悬浮窗（⌘⇧S）
- 剪切板历史占位（⌘⇧V）
- 设置占位（⌘,）
- 退出（⌘Q）

测试状态：全部通过

下一步：Phase 4 - 悬浮窗完善

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

**Phase 完成验证**：

使用 build-macos-apps skill 进行完整构建验证：
```
/using-build-macos-apps
```

---

## Phase 3 总结

### 已完成功能

✅ **菜单栏**：
- StatusBarController 菜单栏控制器
- NSStatusItem 菜单栏图标
- NSMenu 菜单项
- 回调机制

✅ **快捷键**：
- HotKeyManager 全局快捷键管理
- Carbon API 注册
- ⌘⇧S 显示悬浮窗
- ⌘⇧V 剪切板历史（占位）

✅ **配置**：
- LSUIElement 隐藏 Dock 图标
- 菜单栏应用配置

### 技术亮点

1. **NSStatusItem**：
   - 标准菜单栏 API
   - 完整控制菜单

2. **Carbon 全局快捷键**：
   - 应用在后台也能响应
   - 支持多个快捷键

3. **回调机制**：
   - 解耦菜单和业务逻辑
   - 易于扩展

### 已知限制

❌ **暂未实现**（后续 Phase 完成）：
- 自定义菜单栏图标（Phase 4）
- 剪切板历史（Phase 5）
- 设置页（Phase 6）
- 关于页（Phase 7）

### 下一步：Phase 4

**目标**：完善悬浮窗功能

**核心任务**：
1. ThumbnailGenerator（缩略图生成）
2. 更新 ShelfItemView（显示缩略图）
3. 添加动画效果
4. 窗口优化

**文档**：`phase-4-shelf-polish.md`

---

## 附录：常见问题

### Q1: 菜单栏图标不显示？

检查：
1. NSStatusItem 是否创建成功
2. button.image 是否设置
3. isTemplate 是否设置为 true

### Q2: 快捷键不工作？

检查：
1. HotKeyManager 是否初始化
2. 键码是否正确
3. 修饰键是否正确
4. 是否有其他应用占用快捷键

### Q3: Dock 图标还在显示？

检查：
1. Info.plist 中 LSUIElement 是否设置为 true
2. 是否重新编译
3. 是否重新启动应用

### Q4: 菜单项点击没反应？

检查：
1. target 是否设置为 self
2. action 是否正确
3. 回调是否设置

---

**Phase 3 完成！🎉**

准备好进入 Phase 4 了吗？打开 `phase-4-shelf-polish.md` 继续开发。

