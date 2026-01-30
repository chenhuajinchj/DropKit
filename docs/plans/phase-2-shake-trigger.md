# Phase 2: 摇晃触发

> 创建日期：2026-01-29
> 状态：待开发

---

## Phase 概述

**目标**：拖拽文件时摇晃鼠标触发悬浮窗

**预计时间**：第 4-5 天

**成功标准**：
- ✅ 检测到拖拽状态
- ✅ 拖拽时摇晃触发悬浮窗
- ✅ 不拖拽时摇晃不触发
- ✅ 辅助功能权限处理

---

## 技术栈总览

本 Phase 涉及的技术栈：

| 组件 | 技术选择 | 原因 |
|------|---------|------|
| 拖拽检测 | ✅ NSEvent.addGlobalMonitorForEvents | 全局事件监听 |
| 摇晃检测 | ✅ NSEvent 鼠标移动监听 | 检测方向变化 |
| 权限检查 | ✅ ApplicationServices | 系统权限 API |
| 权限引导 | ✅ SwiftUI + NSWindow | 友好的 UI |
| 数据模型 | ✅ 纯 Swift | 简单高效 |

**关键警告**：
- ❌ **不要在 DragMonitor 里读取 NSPasteboard**
- ❌ 拖拽过程中 NSPasteboard.general 读不到正在拖拽的内容
- ✅ 拖拽内容只能在 drop 回调中通过 NSDraggingInfo.draggingPasteboard 获取
- ✅ DragMonitor 只负责布尔状态，不负责内容获取

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
- ✅ 写 AppKit 全局监听代码前使用
- 使用方式：`/using-axiom [问题]`

---

## 步骤详解

---

### 2.1 创建 DragMonitor

**技术栈**：
- ✅ NSEvent.addGlobalMonitorForEvents（全局事件监听）
- ✅ .leftMouseDragged（拖拽事件）
- ✅ .leftMouseUp（鼠标松开事件）
- ❌ **不读取 NSPasteboard**（重要！）

**工具使用**：
- 📝 编辑器：编写 AppKit 代码
- 🔨 编译：使用 XcodeBuildMCP
- ❓ AppKit 前：使用 Axiom skill 查询全局监听用法

**文件**：`Sources/Services/DragMonitor.swift`

**代码结构**：

```swift
import AppKit

class DragMonitor {
    private(set) var isDragging = false
    var onDragStart: (() -> Void)?
    var onDragEnd: (() -> Void)?

    private var dragMonitor: Any?
    private var mouseUpMonitor: Any?

    init() {
        setupMonitors()
    }

    deinit {
        stopMonitoring()
    }

    private func setupMonitors() {
        dragMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDragged) { [weak self] event in
            guard let self = self else { return }
            if !self.isDragging {
                self.isDragging = true
                self.onDragStart?()
                print("Drag started")
            }
        }

        mouseUpMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseUp) { [weak self] event in
            guard let self = self else { return }
            if self.isDragging {
                self.isDragging = false
                self.onDragEnd?()
                print("Drag ended")
            }
        }

        print("DragMonitor initialized")
    }

    private func stopMonitoring() {
        if let monitor = dragMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = mouseUpMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
```

**详细说明**：

1. **职责**：
   - 只判断用户是否正在拖拽（布尔状态）
   - 不读取拖拽内容
   - 不处理拖拽数据

2. **监听事件**：
   - `.leftMouseDragged`：检测拖拽开始
   - `.leftMouseUp`：检测拖拽结束

3. **回调机制**：
   - `onDragStart`：拖拽开始时调用
   - `onDragEnd`：拖拽结束时调用

4. **⚠️ 重要警告**：
   - **不要在这里读取 NSPasteboard.general**
   - 拖拽过程中读取会拿到上一次复制的内容
   - 造成误判和错误行为

**测试要点**：
- 拖拽文件时 isDragging 变为 true
- 松开鼠标时 isDragging 变为 false
- 回调正确触发

**编译**：
使用 mcp__xcodebuildmcp__build 工具编译项目

**提交**：
```bash
git add Sources/Services/DragMonitor.swift
git commit -m "feat: add DragMonitor for global drag detection"
```

---

### 2.2 创建 ShakeDetector

**技术栈**：
- ✅ NSEvent.addGlobalMonitorForEvents（全局事件监听）
- ✅ .mouseMoved（鼠标移动事件）
- ✅ 方向变化检测算法
- ❌ 不涉及 UI

**工具使用**：
- 📝 编辑器：编写算法代码
- 🔨 编译：使用 XcodeBuildMCP
- ❓ 遇到问题：使用 Axiom skill

**文件**：`Sources/Services/ShakeDetector.swift`

**代码结构**：

```swift
import AppKit

class ShakeDetector {
    var sensitivity: Double = 0.5
    var minShakes: Int = 3
    var timeWindow: TimeInterval = 0.5
    var onShakeDetected: (() -> Void)?
    
    private var isEnabled = false
    private var mouseMoveMonitor: Any?
    private var lastX: CGFloat = 0
    private var lastDirection: Direction = .none
    private var directionChanges: [(time: Date, direction: Direction)] = []
    
    private enum Direction {
        case left, right, none
    }
    
    init() {
        print("ShakeDetector initialized")
    }
    
    deinit {
        stopDetecting()
    }
    
    func startDetecting() {
        guard !isEnabled else { return }
        isEnabled = true
        setupMonitor()
        print("ShakeDetector started")
    }
    
    func stopDetecting() {
        guard isEnabled else { return }
        isEnabled = false
        if let monitor = mouseMoveMonitor {
            NSEvent.removeMonitor(monitor)
            mouseMoveMonitor = nil
        }
        lastX = 0
        lastDirection = .none
        directionChanges.removeAll()
        print("ShakeDetector stopped")
    }
    
    private func setupMonitor() {
        mouseMoveMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            guard let self = self, self.isEnabled else { return }
            
            let currentX = NSEvent.mouseLocation.x
            if self.lastX == 0 {
                self.lastX = currentX
                return
            }
            
            let delta = currentX - self.lastX
            let threshold = 10.0 * (1.0 - self.sensitivity)
            
            if abs(delta) < threshold {
                return
            }
            
            let currentDirection: Direction = delta > 0 ? .right : .left
            
            if currentDirection != self.lastDirection && self.lastDirection != .none {
                self.directionChanges.append((time: Date(), direction: currentDirection))
                self.checkForShake()
            }
            
            self.lastDirection = currentDirection
            self.lastX = currentX
        }
    }
    
    private func checkForShake() {
        let now = Date()
        directionChanges.removeAll { now.timeIntervalSince($0.time) > timeWindow }
        
        if directionChanges.count >= minShakes {
            print("Shake detected! Changes: \(directionChanges.count)")
            onShakeDetected?()
            directionChanges.removeAll()
            lastDirection = .none
        }
    }
}
```

**详细说明**：

1. **检测算法**：
   - 记录鼠标 X 坐标变化
   - 检测方向反转（左→右 或 右→左）
   - 时间窗口内反转次数 >= minShakes 触发

2. **可配置参数**：
   - `sensitivity`：灵敏度（0-1），越高越敏感
   - `minShakes`：最少反转次数（默认 3）
   - `timeWindow`：时间窗口（默认 0.5 秒）

3. **启停控制**：
   - `startDetecting()`：开始检测
   - `stopDetecting()`：停止检测并清理状态

4. **前置条件**：
   - 需要辅助功能权限
   - 无权限时监听器不会触发

**测试要点**：
- 快速左右摇晃能触发
- 慢速摇晃不触发
- 停止检测后不触发

**编译**：
使用 mcp__xcodebuildmcp__build 工具编译项目

**提交**：
```bash
git add Sources/Services/ShakeDetector.swift
git commit -m "feat: add ShakeDetector for shake gesture detection"
```

---

### 2.3 创建权限检查工具

**技术栈**：
- ✅ ApplicationServices（系统权限 API）
- ✅ AXIsProcessTrustedWithOptions（权限检查）
- ✅ NSWorkspace（打开系统设置）
- ❌ 不涉及 UI

**工具使用**：
- 📝 编辑器：编写工具类
- 🔨 编译：使用 XcodeBuildMCP
- ❓ 遇到问题：使用 Axiom skill

**文件**：`Sources/Utilities/PermissionChecker.swift`

**代码结构**：

```swift
import ApplicationServices
import AppKit

/// 权限检查工具
class PermissionChecker {
    
    /// 检查辅助功能权限（不弹窗）
    static func checkAccessibilityPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    /// 请求辅助功能权限（弹出系统设置）
    static func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    /// 打开系统设置的辅助功能页面
    static func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}
```

**详细说明**：

1. **检查权限**：
   - 使用 `AXIsProcessTrustedWithOptions` 检查
   - `kAXTrustedCheckOptionPrompt: false` 不弹窗
   - 返回 Bool 表示是否有权限

2. **请求权限**：
   - `kAXTrustedCheckOptionPrompt: true` 弹出系统设置
   - 用户需要手动勾选应用

3. **打开设置**：
   - 使用 URL Scheme 直接打开辅助功能页面
   - 更友好的引导方式

**测试要点**：
- 无权限时返回 false
- 有权限时返回 true
- 请求权限能打开系统设置

**编译**：
使用 mcp__xcodebuildmcp__build 工具编译项目

**提交**：
```bash
git add Sources/Utilities/PermissionChecker.swift
git commit -m "feat: add PermissionChecker utility"
```

---

### 2.4 创建权限引导视图

**技术栈**：
- ✅ SwiftUI（UI 层）
- ✅ VStack + HStack（布局）
- ✅ Button（交互）
- ✅ @Environment(\.dismiss)（关闭视图）
- ❌ 不使用 NSView

**工具使用**：
- 📝 编辑器：编写 SwiftUI 代码
- 🔨 编译：使用 XcodeBuildMCP
- ❓ 复杂 UI 前：使用 Axiom skill

**文件**：`Sources/Features/Permission/PermissionGuideView.swift`

**代码结构**：

```swift
import SwiftUI

/// 权限引导视图
struct PermissionGuideView: View {
    @Environment(\.dismiss) var dismiss
    @State private var hasPermission = false
    
    var body: some View {
        VStack(spacing: 24) {
            // 图标
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)
            
            // 标题
            Text("需要辅助功能权限")
                .font(.title)
                .fontWeight(.bold)
            
            // 说明
            VStack(alignment: .leading, spacing: 12) {
                Text("DropKit 需要辅助功能权限来检测鼠标摇晃手势。")
                    .font(.body)
                
                Text("具体步骤：")
                    .font(.headline)
                    .padding(.top, 8)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top) {
                        Text("1.")
                        Text("点击下方按钮打开系统设置")
                    }
                    HStack(alignment: .top) {
                        Text("2.")
                        Text("在「隐私与安全」→「辅助功能」中找到 DropKit")
                    }
                    HStack(alignment: .top) {
                        Text("3.")
                        Text("勾选 DropKit 旁边的复选框")
                    }
                    HStack(alignment: .top) {
                        Text("4.")
                        Text("返回应用，点击「重新检查」按钮")
                    }
                }
                .font(.callout)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // 按钮
            VStack(spacing: 12) {
                Button(action: {
                    PermissionChecker.openAccessibilitySettings()
                }) {
                    Text("打开系统设置")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    checkPermission()
                }) {
                    Text("重新检查权限")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.secondary.opacity(0.2))
                        .foregroundColor(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                
                if hasPermission {
                    Text("✓ 权限已授予")
                        .foregroundColor(.green)
                        .font(.headline)
                }
            }
        }
        .padding(32)
        .frame(width: 500)
        .onAppear {
            checkPermission()
        }
    }
    
    private func checkPermission() {
        hasPermission = PermissionChecker.checkAccessibilityPermission()
        if hasPermission {
            // 延迟关闭，让用户看到成功提示
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                dismiss()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    PermissionGuideView()
}
```

**详细说明**：

1. **布局结构**：
   - 图标：手势图标
   - 标题：说明需要权限
   - 说明：详细步骤
   - 按钮：打开设置、重新检查

2. **交互逻辑**：
   - 打开设置：调用系统 URL Scheme
   - 重新检查：检查权限状态
   - 自动关闭：检测到权限后自动关闭

3. **用户体验**：
   - 清晰的步骤说明
   - 明确的操作按钮
   - 即时的状态反馈

**测试要点**：
- 按钮能打开系统设置
- 重新检查能更新状态
- 有权限后自动关闭

**编译**：
使用 mcp__xcodebuildmcp__build 工具编译项目

**提交**：
```bash
git add Sources/Features/Permission/PermissionGuideView.swift
git commit -m "feat: add PermissionGuideView"
```

---

### 2.5 创建权限引导窗口

**技术栈**：
- ✅ NSWindow (AppKit)
- ✅ NSHostingView（SwiftUI 集成）
- ❌ 不使用 SwiftUI Window

**工具使用**：
- 📝 编辑器：编写 AppKit 代码
- 🔨 编译：使用 XcodeBuildMCP

**文件**：`Sources/Features/Permission/PermissionGuideWindow.swift`

**代码结构**：

```swift
import AppKit
import SwiftUI

/// 权限引导窗口
class PermissionGuideWindow: NSWindow {
    
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 600),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        self.title = "DropKit 需要权限"
        self.center()
        self.isReleasedWhenClosed = false
        
        // 设置内容视图
        let contentView = NSHostingView(rootView: PermissionGuideView())
        self.contentView = contentView
    }
    
    func showModal() {
        self.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
```

**详细说明**：

1. **窗口配置**：
   - 尺寸：500x600
   - 样式：标题栏 + 关闭按钮
   - 居中显示

2. **SwiftUI 集成**：
   - 使用 NSHostingView 包装 PermissionGuideView
   - 设置为 contentView

3. **显示方式**：
   - `showModal()`：显示窗口并激活应用

**编译**：
使用 mcp__xcodebuildmcp__build 工具编译项目

**提交**：
```bash
git add Sources/Features/Permission/PermissionGuideWindow.swift
git commit -m "feat: add PermissionGuideWindow"
```

---

### 2.6 集成摇晃触发到 AppDelegate

**技术栈**：
- ✅ AppKit AppDelegate
- ✅ 回调闭包（连接各组件）
- ✅ 权限检查流程
- ❌ 不涉及 UI

**工具使用**：
- 📝 编辑器：修改 AppDelegate.swift
- 🔨 编译：使用 XcodeBuildMCP

**修改文件**：`Sources/App/AppDelegate.swift`

**完整代码**：

```swift
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var shelfPanel: ShelfPanel?
    private var shelfViewModel: ShelfViewModel?
    private var dragMonitor: DragMonitor?
    private var shakeDetector: ShakeDetector?
    private var permissionGuideWindow: PermissionGuideWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("DropKit launched")
        
        // 检查权限
        if !PermissionChecker.checkAccessibilityPermission() {
            showPermissionGuide()
            return
        }
        
        setupShelf()
        setupShakeDetection()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        shelfPanel?.show()
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        print("DropKit terminating")
    }

    private func setupShelf() {
        let viewModel = ShelfViewModel()
        self.shelfViewModel = viewModel
        
        let panel = ShelfPanel(viewModel: viewModel)
        self.shelfPanel = panel
        
        print("Shelf initialized")
    }
    
    private func setupShakeDetection() {
        // 创建 DragMonitor
        let dragMonitor = DragMonitor()
        self.dragMonitor = dragMonitor
        
        // 创建 ShakeDetector
        let shakeDetector = ShakeDetector()
        self.shakeDetector = shakeDetector
        
        // 拖拽开始时启动摇晃检测
        dragMonitor.onDragStart = { [weak self, weak shakeDetector] in
            shakeDetector?.startDetecting()
            print("Shake detection enabled")
        }
        
        // 拖拽结束时停止摇晃检测
        dragMonitor.onDragEnd = { [weak self, weak shakeDetector] in
            shakeDetector?.stopDetecting()
            print("Shake detection disabled")
        }
        
        // 检测到摇晃时显示悬浮窗
        shakeDetector.onShakeDetected = { [weak self] in
            guard let self = self else { return }
            if self.dragMonitor?.isDragging == true {
                self.shelfPanel?.show()
                print("Shelf shown by shake")
            }
        }
        
        print("Shake detection initialized")
    }
    
    private func showPermissionGuide() {
        let window = PermissionGuideWindow()
        self.permissionGuideWindow = window
        window.showModal()
        
        // 权限授予后初始化功能
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if PermissionChecker.checkAccessibilityPermission() {
                self.setupShelf()
                self.setupShakeDetection()
            }
        }
    }
}
```

**详细说明**：

1. **启动流程**：
   - 检查辅助功能权限
   - 无权限：显示引导窗口
   - 有权限：初始化功能

2. **摇晃触发逻辑**：
   - DragMonitor 检测拖拽状态
   - 拖拽开始 → 启动 ShakeDetector
   - 拖拽结束 → 停止 ShakeDetector
   - 检测到摇晃 → 显示 ShelfPanel

3. **权限处理**：
   - 显示引导窗口
   - 定期检查权限状态
   - 授权后初始化功能

4. **重要变化**：
   - 移除了 Phase 1 的自动显示代码
   - 改为摇晃触发

**编译**：
使用 mcp__xcodebuildmcp__build 工具编译项目

**提交**：
```bash
git add Sources/App/AppDelegate.swift
git commit -m "feat: integrate shake detection with permission handling"
```

---

### 2.7 更新 Entitlements

**技术栈**：
- ✅ Xcode Entitlements 配置
- ❌ 不涉及代码

**工具使用**：
- 📝 编辑器：修改 entitlements 文件
- 🔨 编译：使用 XcodeBuildMCP

**修改文件**：`DropKit/DropKit.entitlements`

**添加内容**：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <false/>
    <key>com.apple.security.automation.apple-events</key>
    <true/>
</dict>
</plist>
```

**说明**：
- 禁用沙盒：全局事件监听需要
- 允许自动化：打开系统设置需要

**编译**：
使用 mcp__xcodebuildmcp__build 工具编译项目

**提交**：
```bash
git add DropKit/DropKit.entitlements
git commit -m "chore: update entitlements for accessibility"
```

---

### 2.8 Phase 2 测试清单

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
| 1 | 权限检查 | 首次启动应用 | 显示权限引导窗口 | ⬜ |
| 2 | 打开设置 | 点击「打开系统设置」 | 系统设置打开到辅助功能页 | ⬜ |
| 3 | 授予权限 | 在系统设置中勾选 | 应用获得权限 | ⬜ |
| 4 | 重新检查 | 点击「重新检查权限」 | 检测到权限，窗口关闭 | ⬜ |
| 5 | 拖拽检测 | 拖拽任意文件 | 控制台输出"Drag started" | ⬜ |
| 6 | 摇晃检测启动 | 拖拽时摇晃鼠标 | 控制台输出"Shake detection enabled" | ⬜ |
| 7 | 摇晃触发 | 拖拽时快速左右摇晃 | 悬浮窗在鼠标位置显示 | ⬜ |
| 8 | 拖入文件 | 拖入文件到悬浮窗 | 文件添加成功 | ⬜ |
| 9 | 拖拽结束 | 松开鼠标 | 控制台输出"Drag ended" | ⬜ |
| 10 | 摇晃检测停止 | 拖拽结束后摇晃 | 悬浮窗不触发 | ⬜ |
| 11 | 灵敏度测试 | 轻微摇晃 | 不触发 | ⬜ |
| 12 | 灵敏度测试 | 大幅摇晃 | 触发 | ⬜ |
| 13 | 时间窗口 | 慢速摇晃（>0.5秒） | 不触发 | ⬜ |
| 14 | 时间窗口 | 快速摇晃（<0.5秒） | 触发 | ⬜ |
| 15 | 多次触发 | 连续摇晃多次 | 每次都触发 | ⬜ |

**边界测试**：

| # | 测试项 | 操作步骤 | 预期结果 | 状态 |
|---|--------|----------|----------|------|
| 1 | 无权限拖拽 | 未授权时拖拽文件 | 不触发摇晃检测 | ⬜ |
| 2 | 权限撤销 | 运行中撤销权限 | 摇晃检测失效 | ⬜ |
| 3 | 多屏幕 | 在不同屏幕拖拽 | 正常检测 | ⬜ |
| 4 | 快速拖拽 | 极快速度拖拽 | 正常检测 | ⬜ |
| 5 | 垂直拖拽 | 只上下拖拽 | 不触发（只检测水平） | ⬜ |

**测试说明**：
- 所有测试项必须通过才能进入 Phase 3
- 发现问题立即修复，不要累积
- 每修复一个问题，重新编译测试

---

### 2.9 Phase 2 完成提交

**技术栈**：
- ✅ Git 版本控制
- ❌ 不涉及代码编写

**工具使用**：
- 📝 Git 命令行
- ✅ 使用 build-macos-apps skill 完整验证

**提交命令**：

```bash
git add -A
git commit -m "feat: Phase 2 complete - shake detection

Phase 2 完成：
- DragMonitor 全局拖拽检测
- ShakeDetector 摇晃手势检测
- PermissionChecker 权限检查工具
- PermissionGuideView 权限引导界面
- PermissionGuideWindow 权限引导窗口
- 集成到 AppDelegate
- Entitlements 配置

核心功能：
- 拖拽文件时摇晃鼠标触发悬浮窗
- 完整的权限请求流程
- 友好的用户引导

测试状态：全部通过

下一步：Phase 3 - 菜单栏

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

**Phase 完成验证**：

使用 build-macos-apps skill 进行完整构建验证：
```
/using-build-macos-apps
```

---

## Phase 2 总结

### 已完成功能

✅ **拖拽检测**：
- DragMonitor 全局拖拽状态检测
- 只判断布尔状态，不读取内容
- 回调机制通知拖拽开始/结束

✅ **摇晃检测**：
- ShakeDetector 鼠标摇晃手势检测
- 方向变化算法
- 可配置灵敏度、次数、时间窗口

✅ **权限处理**：
- PermissionChecker 权限检查工具
- PermissionGuideView 友好的引导界面
- PermissionGuideWindow 引导窗口
- 完整的权限请求流程

✅ **集成**：
- 拖拽开始 → 启动摇晃检测
- 拖拽结束 → 停止摇晃检测
- 检测到摇晃 → 显示悬浮窗
- Entitlements 配置

### 技术亮点

1. **智能触发机制**：
   - 只在拖拽时检测摇晃
   - 避免误触发
   - 节省系统资源

2. **权限友好处理**：
   - 清晰的引导步骤
   - 即时的状态反馈
   - 自动检测权限变化

3. **⚠️ 关键警告**：
   - DragMonitor 不读取 NSPasteboard
   - 拖拽内容只在 drop 回调中获取
   - 避免误判和错误行为

### 已知限制

❌ **暂未实现**（后续 Phase 完成）：
- 菜单栏（Phase 3）
- 快捷键（Phase 3）
- 缩略图（Phase 4）
- 动画效果（Phase 4）
- 剪切板历史（Phase 5）
- 设置页（Phase 6）

### 下一步：Phase 3

**目标**：实现菜单栏和快捷键

**核心任务**：
1. StatusBarController（菜单栏控制器）
2. HotKeyManager（全局快捷键）
3. 菜单项和快捷键绑定
4. 隐藏 Dock 图标

**文档**：`phase-3-menubar.md`

---

## 附录：常见问题

### Q1: 摇晃不触发怎么办？

检查：
1. **辅助功能权限**（最常见原因）
   - 系统设置 → 隐私与安全 → 辅助功能
   - 确认应用已勾选
   - 权限变更后需要重启应用

2. **拖拽状态**
   - 确认 DragMonitor.isDragging 为 true
   - 查看控制台输出

3. **灵敏度参数**
   - 检查 sensitivity、minShakes、timeWindow
   - 尝试调整参数

### Q2: 权限引导窗口不显示？

检查：
1. `PermissionChecker.checkAccessibilityPermission()` 返回值
2. `showPermissionGuide()` 是否调用
3. 窗口是否被其他窗口遮挡

### Q3: 拖拽检测不工作？

检查：
1. 辅助功能权限是否授予
2. NSEvent.addGlobalMonitorForEvents 是否成功
3. 查看控制台是否有错误信息

### Q4: 如何调试摇晃检测？

添加调试输出：
```swift
print("Current X: \(currentX), Delta: \(delta), Direction: \(currentDirection)")
print("Direction changes: \(directionChanges.count)")
```

---

**Phase 2 完成！🎉**

准备好进入 Phase 3 了吗？打开 `phase-3-menubar.md` 继续开发。

