# Phase 7: 收尾发布

> 创建日期：2026-01-29
> 状态：待开发

---

## Phase 概述

**目标**：完善应用细节，准备发布

**预计时间**：第 16-18 天

**成功标准**：
- ✅ 应用图标完成
- ✅ 性能优化完成
- ✅ 错误处理完善
- ✅ 用户引导实现
- ✅ 打包配置完成
- ✅ 测试通过

---

## 技术栈总览

本 Phase 涉及的技术栈：

| 组件 | 技术选择 | 原因 |
|------|---------|------|
| 图标设计 | ✅ SF Symbols / 自定义 | 系统风格 |
| 性能监控 | ✅ Instruments | 官方工具 |
| 错误处理 | ✅ Result + Optional | Swift 标准 |
| 用户引导 | ✅ SwiftUI Overlay | 原生实现 |
| 打包 | ✅ Xcode Archive | 标准流程 |
| 签名 | ✅ Developer ID | 官方签名 |

**关键技术**：
- ✅ Asset Catalog（图标管理）
- ✅ Instruments（性能分析）
- ✅ Error Protocol（错误定义）
- ✅ UserDefaults（首次启动检测）
- ✅ Entitlements（权限配置）
- ✅ Info.plist（应用配置）

---

## 工具使用指南

### 每个步骤的标准流程

```
1. 阅读步骤说明
   ↓
2. 编写代码/配置
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
- ✅ 写复杂逻辑前使用
- 使用方式：`/using-axiom [问题]`

---

## 步骤详解

---

### 7.1 应用图标设计

**技术栈**：
- ✅ Asset Catalog
- ✅ 多尺寸图标
- ✅ 深色模式适配
- ❌ 不涉及代码

**工具使用**：
- 🎨 设计工具：Sketch / Figma / SF Symbols
- 📝 Xcode：Asset Catalog 配置

**文件**：`Assets.xcassets/AppIcon.appiconset/`

**图标规格**：

```
应用图标尺寸（macOS）：
- 16x16 @1x, @2x
- 32x32 @1x, @2x
- 128x128 @1x, @2x
- 256x256 @1x, @2x
- 512x512 @1x, @2x

菜单栏图标尺寸：
- 16x16 @1x, @2x（推荐 18x18）
- 支持深色模式
- 使用 Template Image
```

**设计指南**：

1. **应用图标设计**：
   ```
   主题：盒子 + 拖放
   颜色：蓝色系（#007AFF）
   风格：扁平化、现代
   元素：
   - 主体：立方体盒子
   - 装饰：向下箭头/拖放手势
   - 背景：渐变色
   ```

2. **菜单栏图标设计**：
   ```
   主题：简化的盒子图标
   颜色：单色（黑/白自适应）
   风格：线条图标
   要求：
   - 18x18 像素
   - 2px 线宽
   - Template Image
   - 深色模式适配
   ```

3. **使用 SF Symbols**（临时方案）：
   ```swift
   // 应用图标
   Image(systemName: "shippingbox.fill")

   // 菜单栏图标
   Image(systemName: "shippingbox")
   ```

**Asset Catalog 配置**：

```json
// AppIcon.appiconset/Contents.json
{
  "images" : [
    {
      "size" : "16x16",
      "idiom" : "mac",
      "filename" : "icon_16x16.png",
      "scale" : "1x"
    },
    {
      "size" : "16x16",
      "idiom" : "mac",
      "filename" : "icon_16x16@2x.png",
      "scale" : "2x"
    },
    // ... 其他尺寸
  ],
  "info" : {
    "version" : 1,
    "author" : "xcode"
  }
}
```

**详细说明**：

1. **应用图标**：
   - 多尺寸支持
   - 高分辨率 @2x
   - 圆角由系统自动添加

2. **菜单栏图标**：
   - Template Image 模式
   - 自动适配深色模式
   - 简洁清晰

3. **临时方案**：
   - 使用 SF Symbols
   - 快速原型
   - 后期替换

**测试要点**：
- 应用图标显示正常
- 菜单栏图标清晰
- 深色模式适配正确
- 各尺寸显示正常

**提交**：
```bash
git add Assets.xcassets/
git commit -m "feat: add app icons"
```

---

### 7.2 菜单栏图标优化

**技术栈**：
- ✅ NSImage
- ✅ Template Image
- ✅ 深色模式适配
- ✅ 状态指示

**工具使用**：
- 📝 编辑器：编写图标管理代码
- 🔨 编译：使用 XcodeBuildMCP

**文件**：`Sources/Features/MenuBar/MenuBarIconManager.swift`

**代码结构**：

```swift
import AppKit

/// 菜单栏图标管理器
class MenuBarIconManager {

    private let statusItem: NSStatusItem

    // MARK: - Initialization

    init(statusItem: NSStatusItem) {
        self.statusItem = statusItem
        setupIcon()
    }

    // MARK: - Setup

    private func setupIcon() {
        guard let button = statusItem.button else { return }

        // 设置图标
        if let icon = createIcon() {
            button.image = icon
        }

        // 设置为 Template Image（自动适配深色模式）
        button.image?.isTemplate = true
    }

    private func createIcon() -> NSImage? {
        // 方案 1：使用 SF Symbol
        let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        return NSImage(systemSymbolName: "shippingbox", accessibilityDescription: "DropKit")
            ?.withSymbolConfiguration(config)

        // 方案 2：使用自定义图标
        // return NSImage(named: "MenuBarIcon")
    }

    // MARK: - State Management

    /// 设置正常状态
    func setNormalState() {
        guard let button = statusItem.button else { return }
        button.image = createIcon()
        button.image?.isTemplate = true
    }

    /// 设置活动状态（悬浮窗显示时）
    func setActiveState() {
        guard let button = statusItem.button else { return }

        // 使用填充版本的图标
        let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        let activeIcon = NSImage(systemSymbolName: "shippingbox.fill", accessibilityDescription: "DropKit")
            ?.withSymbolConfiguration(config)

        button.image = activeIcon
        button.image?.isTemplate = true
    }

    /// 设置错误状态
    func setErrorState() {
        guard let button = statusItem.button else { return }

        // 使用警告图标
        let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        let errorIcon = NSImage(systemSymbolName: "exclamationmark.triangle", accessibilityDescription: "Error")
            ?.withSymbolConfiguration(config)

        button.image = errorIcon
        button.image?.isTemplate = true
    }

    /// 显示徽章（未读数量）
    func showBadge(count: Int) {
        guard let button = statusItem.button else { return }

        // 创建带徽章的图标
        if let baseIcon = createIcon() {
            let badgedIcon = addBadge(to: baseIcon, count: count)
            button.image = badgedIcon
            button.image?.isTemplate = true
        }
    }

    /// 隐藏徽章
    func hideBadge() {
        setNormalState()
    }

    // MARK: - Private Methods

    private func addBadge(to image: NSImage, count: Int) -> NSImage {
        let size = image.size
        let badgeSize: CGFloat = 10

        let newImage = NSImage(size: size)
        newImage.lockFocus()

        // 绘制原图标
        image.draw(in: NSRect(origin: .zero, size: size))

        // 绘制徽章
        let badgeRect = NSRect(
            x: size.width - badgeSize,
            y: size.height - badgeSize,
            width: badgeSize,
            height: badgeSize
        )

        NSColor.red.setFill()
        NSBezierPath(ovalIn: badgeRect).fill()

        // 绘制数字
        let text = "\(min(count, 9))"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 8),
            .foregroundColor: NSColor.white
        ]

        let textSize = text.size(withAttributes: attributes)
        let textRect = NSRect(
            x: badgeRect.midX - textSize.width / 2,
            y: badgeRect.midY - textSize.height / 2,
            width: textSize.width,
            height: textSize.height
        )

        text.draw(in: textRect, withAttributes: attributes)

        newImage.unlockFocus()
        return newImage
    }
}
```

**详细说明**：

1. **图标管理**：
   - 正常状态：空心图标
   - 活动状态：填充图标
   - 错误状态：警告图标

2. **Template Image**：
   - 自动适配深色模式
   - 系统颜色管理
   - 无需手动处理

3. **徽章功能**：
   - 显示未读数量
   - 红色圆形徽章
   - 最多显示 9

4. **状态切换**：
   - 悬浮窗显示时切换到活动状态
   - 错误时显示警告图标
   - 有新剪切板项目时显示徽章

**测试要点**：
- 图标显示清晰
- 深色模式适配正确
- 状态切换流畅
- 徽章显示正确

**编译**：
使用 mcp__xcodebuildmcp__build 工具编译项目

**提交**：
```bash
git add Sources/Features/MenuBar/MenuBarIconManager.swift
git commit -m "feat: add MenuBarIconManager"
```

---

### 7.3 性能优化

**技术栈**：
- ✅ Instruments（性能分析）
- ✅ async/await（异步优化）
- ✅ LazyVStack（列表优化）
- ✅ 缓存机制

**工具使用**：
- 📊 Instruments：Time Profiler, Allocations
- 📝 编辑器：优化代码
- 🔨 编译：使用 XcodeBuildMCP

**优化清单**：

#### 1. 缩略图生成优化

**问题**：缩略图生成阻塞主线程

**解决方案**：

```swift
// 优化前
func loadThumbnail() {
    let thumbnail = ThumbnailGenerator.generate(for: url)
    self.thumbnail = thumbnail
}

// 优化后
func loadThumbnail() async {
    let thumbnail = await ThumbnailGenerator.generate(for: url)
    await MainActor.run {
        self.thumbnail = thumbnail
    }
}
```

#### 2. 剪切板历史列表优化

**问题**：大量历史项目导致滚动卡顿

**解决方案**：

```swift
// 优化前
ScrollView {
    VStack {
        ForEach(items) { item in
            ClipboardItemView(item: item)
        }
    }
}

// 优化后
ScrollView {
    LazyVStack {
        ForEach(items) { item in
            ClipboardItemView(item: item)
        }
    }
}
```

#### 3. 图片缓存

**问题**：重复加载图片浪费资源

**解决方案**：

```swift
/// 图片缓存管理器
class ImageCache {
    static let shared = ImageCache()
    
    private let cache = NSCache<NSString, NSImage>()
    
    private init() {
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }
    
    func get(_ key: String) -> NSImage? {
        return cache.object(forKey: key as NSString)
    }
    
    func set(_ image: NSImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
    
    func clear() {
        cache.removeAllObjects()
    }
}

// 使用缓存
func loadThumbnail(for url: URL) async -> NSImage? {
    let key = url.path
    
    // 检查缓存
    if let cached = ImageCache.shared.get(key) {
        return cached
    }
    
    // 生成缩略图
    if let thumbnail = await ThumbnailGenerator.generate(for: url) {
        ImageCache.shared.set(thumbnail, forKey: key)
        return thumbnail
    }
    
    return nil
}
```

#### 4. 剪切板监听优化

**问题**：定时器频繁检查浪费 CPU

**解决方案**：

```swift
// 优化前：固定 0.5 秒检查
timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { ... }

// 优化后：自适应间隔
private var checkInterval: TimeInterval = 0.5
private var lastChangeTime: Date = Date()

func checkPasteboard() {
    let currentChangeCount = NSPasteboard.general.changeCount
    
    if currentChangeCount != lastChangeCount {
        lastChangeCount = currentChangeCount
        lastChangeTime = Date()
        
        // 有变化时缩短间隔
        checkInterval = 0.3
        
        // 处理变化
        if let item = readPasteboardContent() {
            latestItem = item
        }
    } else {
        // 无变化时延长间隔
        let timeSinceLastChange = Date().timeIntervalSince(lastChangeTime)
        if timeSinceLastChange > 10 {
            checkInterval = 1.0
        }
    }
    
    // 重新调度 Timer
    rescheduleTimer()
}
```

#### 5. 内存管理

**问题**：大量历史项目占用内存

**解决方案**：

```swift
// 限制内存中的项目数量
let maxItemsInMemory = 100

// 超出限制时只保留最近的
if items.count > maxItemsInMemory {
    items = Array(items.prefix(maxItemsInMemory))
}

// 图片内容使用文件路径而非 base64
struct ClipboardItem {
    let type: ItemType
    let content: String // 文本/URL/文件路径
    let imagePath: String? // 图片文件路径（而非 base64）
}
```

**性能测试**：

```bash
# 使用 Instruments 分析
# 1. Time Profiler：检查 CPU 占用
# 2. Allocations：检查内存使用
# 3. Leaks：检查内存泄漏

# 性能指标：
# - 应用启动时间 < 1 秒
# - 悬浮窗显示延迟 < 100ms
# - 剪切板历史滚动 60fps
# - 内存占用 < 100MB
```

**提交**：
```bash
git add Sources/
git commit -m "perf: optimize performance"
```

---

### 7.4 错误处理完善

**技术栈**：
- ✅ Error Protocol
- ✅ Result 类型
- ✅ 错误日志
- ✅ 用户提示

**工具使用**：
- 📝 编辑器：编写错误处理代码
- 🔨 编译：使用 XcodeBuildMCP

**文件**：`Sources/Utilities/ErrorHandling.swift`

**代码结构**：

```swift
import Foundation
import AppKit

// MARK: - Error Definitions

/// 应用错误
enum AppError: LocalizedError {
    case permissionDenied(String)
    case fileNotFound(String)
    case invalidData(String)
    case networkError(String)
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied(let message):
            return "权限被拒绝: \(message)"
        case .fileNotFound(let path):
            return "文件不存在: \(path)"
        case .invalidData(let message):
            return "数据无效: \(message)"
        case .networkError(let message):
            return "网络错误: \(message)"
        case .unknown(let message):
            return "未知错误: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .permissionDenied:
            return "请在系统设置中授予必要的权限"
        case .fileNotFound:
            return "请检查文件是否存在"
        case .invalidData:
            return "请检查数据格式是否正确"
        case .networkError:
            return "请检查网络连接"
        case .unknown:
            return "请重启应用或联系开发者"
        }
    }
}

// MARK: - Error Handler

/// 错误处理器
class ErrorHandler {
    
    static let shared = ErrorHandler()
    
    private init() {}
    
    /// 处理错误
    func handle(_ error: Error, context: String = "") {
        // 记录日志
        logError(error, context: context)
        
        // 显示用户提示
        if shouldShowAlert(for: error) {
            showAlert(for: error)
        }
    }
    
    /// 记录错误日志
    private func logError(_ error: Error, context: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let message = """
        [\(timestamp)] ERROR
        Context: \(context)
        Error: \(error.localizedDescription)
        """
        
        print(message)
        
        // 写入日志文件
        writeToLogFile(message)
    }
    
    /// 写入日志文件
    private func writeToLogFile(_ message: String) {
        guard let logURL = getLogFileURL() else { return }
        
        do {
            let fileHandle = try FileHandle(forWritingTo: logURL)
            fileHandle.seekToEndOfFile()
            if let data = (message + "\n").data(using: .utf8) {
                fileHandle.write(data)
            }
            fileHandle.closeFile()
        } catch {
            // 文件不存在，创建新文件
            try? message.write(to: logURL, atomically: true, encoding: .utf8)
        }
    }
    
    /// 获取日志文件路径
    private func getLogFileURL() -> URL? {
        let fileManager = FileManager.default
        guard let appSupport = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else { return nil }
        
        let appFolder = appSupport.appendingPathComponent("DropKit")
        try? fileManager.createDirectory(at: appFolder, withIntermediateDirectories: true)
        
        return appFolder.appendingPathComponent("error.log")
    }
    
    /// 判断是否显示警告框
    private func shouldShowAlert(for error: Error) -> Bool {
        // 权限错误和未知错误显示警告
        if let appError = error as? AppError {
            switch appError {
            case .permissionDenied, .unknown:
                return true
            default:
                return false
            }
        }
        return false
    }
    
    /// 显示错误警告框
    private func showAlert(for error: Error) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "发生错误"
            alert.informativeText = error.localizedDescription
            
            if let recoverySuggestion = (error as? LocalizedError)?.recoverySuggestion {
                alert.informativeText += "\n\n\(recoverySuggestion)"
            }
            
            alert.alertStyle = .warning
            alert.addButton(withTitle: "确定")
            alert.runModal()
        }
    }
}

// MARK: - Result Extensions

extension Result {
    /// 处理错误
    func handleError(context: String = "") {
        if case .failure(let error) = self {
            ErrorHandler.shared.handle(error, context: context)
        }
    }
}
```

**使用示例**：

```swift
// 1. 使用 Result 类型
func loadSettings() -> Result<Settings, AppError> {
    guard let data = UserDefaults.standard.data(forKey: "settings") else {
        return .failure(.fileNotFound("settings"))
    }
    
    do {
        let settings = try JSONDecoder().decode(Settings.self, from: data)
        return .success(settings)
    } catch {
        return .failure(.invalidData("无法解析设置"))
    }
}

// 调用
let result = loadSettings()
result.handleError(context: "加载设置")

switch result {
case .success(let settings):
    print("设置加载成功: \(settings)")
case .failure(let error):
    print("设置加载失败: \(error)")
}

// 2. 使用 do-catch
func saveSettings(_ settings: Settings) {
    do {
        let data = try JSONEncoder().encode(settings)
        UserDefaults.standard.set(data, forKey: "settings")
    } catch {
        ErrorHandler.shared.handle(error, context: "保存设置")
    }
}

// 3. 权限检查
func checkAccessibilityPermission() throws {
    let hasPermission = AXIsProcessTrusted()
    if !hasPermission {
        throw AppError.permissionDenied("需要辅助功能权限")
    }
}

// 调用
do {
    try checkAccessibilityPermission()
} catch {
    ErrorHandler.shared.handle(error, context: "权限检查")
}
```

**详细说明**：

1. **错误定义**：
   - 使用 enum 定义错误类型
   - 实现 LocalizedError 协议
   - 提供错误描述和恢复建议

2. **错误处理**：
   - 统一的错误处理入口
   - 记录错误日志
   - 显示用户提示

3. **日志管理**：
   - 写入日志文件
   - 包含时间戳和上下文
   - 便于调试和问题追踪

4. **用户体验**：
   - 友好的错误提示
   - 提供解决建议
   - 避免应用崩溃

**测试要点**：
- 错误正确捕获
- 日志正确记录
- 警告框显示正确
- 应用不崩溃

**编译**：
使用 mcp__xcodebuildmcp__build 工具编译项目

**提交**：
```bash
git add Sources/Utilities/ErrorHandling.swift
git commit -m "feat: add comprehensive error handling"
```

---

### 7.5 用户引导（首次启动）

**技术栈**：
- ✅ SwiftUI Overlay
- ✅ UserDefaults（首次检测）
- ✅ 分步引导
- ✅ 权限请求

**工具使用**：
- 📝 编辑器：编写引导视图
- 🔨 编译：使用 XcodeBuildMCP

**文件**：`Sources/Features/Onboarding/OnboardingView.swift`

**代码结构**：

```swift
import SwiftUI

/// 首次启动引导视图
struct OnboardingView: View {
    
    @Binding var isPresented: Bool
    @State private var currentStep = 0
    
    private let steps: [OnboardingStep] = [
        OnboardingStep(
            icon: "hand.wave.fill",
            title: "欢迎使用 DropKit",
            description: "一个强大的 macOS 菜单栏工具\n提供悬浮窗和剪切板历史功能",
            action: nil
        ),
        OnboardingStep(
            icon: "hand.point.up.left.fill",
            title: "悬浮窗功能",
            description: "拖拽文件时摇晃鼠标\n即可显示悬浮窗暂存文件",
            action: nil
        ),
        OnboardingStep(
            icon: "doc.on.clipboard.fill",
            title: "剪切板历史",
            description: "自动记录复制的内容\n使用 ⌘⇧V 打开历史记录",
            action: nil
        ),
        OnboardingStep(
            icon: "lock.shield.fill",
            title: "辅助功能权限",
            description: "需要辅助功能权限来检测鼠标摇晃\n请在下一步授予权限",
            action: .requestPermission
        )
    ]
    
    var body: some View {
        ZStack {
            // 背景
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            // 内容卡片
            VStack(spacing: 0) {
                // 步骤内容
                TabView(selection: $currentStep) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        stepView(steps[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 400)
                
                // 底部按钮
                bottomBar
            }
            .frame(width: 500, height: 500)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(radius: 20)
        }
    }
    
    // MARK: - Step View
    
    private func stepView(_ step: OnboardingStep) -> some View {
        VStack(spacing: 32) {
            Spacer()
            
            // 图标
            Image(systemName: step.icon)
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
            
            // 标题
            Text(step.title)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // 描述
            Text(step.description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    // MARK: - Bottom Bar
    
    private var bottomBar: some View {
        HStack {
            // 跳过按钮
            if currentStep < steps.count - 1 {
                Button("跳过") {
                    completeOnboarding()
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 步骤指示器
            HStack(spacing: 8) {
                ForEach(0..<steps.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentStep ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            
            Spacer()
            
            // 下一步/完成按钮
            Button(currentStep < steps.count - 1 ? "下一步" : "开始使用") {
                handleNextButton()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
    }
    
    // MARK: - Actions
    
    private func handleNextButton() {
        // 执行当前步骤的操作
        if let action = steps[currentStep].action {
            performAction(action)
        }
        
        // 进入下一步或完成
        if currentStep < steps.count - 1 {
            withAnimation {
                currentStep += 1
            }
        } else {
            completeOnboarding()
        }
    }
    
    private func performAction(_ action: OnboardingAction) {
        switch action {
        case .requestPermission:
            requestAccessibilityPermission()
        }
    }
    
    private func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        isPresented = false
    }
}

// MARK: - Models

struct OnboardingStep {
    let icon: String
    let title: String
    let description: String
    let action: OnboardingAction?
}

enum OnboardingAction {
    case requestPermission
}

// MARK: - Preview

#Preview {
    OnboardingView(isPresented: .constant(true))
}
```

**集成到 AppState**：

```swift
// AppState.swift

@MainActor
class AppState: ObservableObject {
    
    @Published var showOnboarding = false
    
    init() {
        // ... 现有初始化代码 ...
        
        // 检查是否首次启动
        checkFirstLaunch()
    }
    
    private func checkFirstLaunch() {
        let hasCompleted = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        if !hasCompleted {
            showOnboarding = true
        }
    }
}
```

**在主视图中显示**：

```swift
// App.swift

@main
struct DropKitApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        MenuBarExtra {
            MenuBarView(appState: appState)
        } label: {
            Image(systemName: "shippingbox")
        }
        .overlay {
            if appState.showOnboarding {
                OnboardingView(isPresented: $appState.showOnboarding)
            }
        }
    }
}
```

**详细说明**：

1. **分步引导**：
   - 欢迎页面
   - 功能介绍
   - 权限请求
   - 开始使用

2. **交互设计**：
   - TabView 切换步骤
   - 步骤指示器
   - 跳过按钮
   - 下一步/完成按钮

3. **权限请求**：
   - 在引导中请求权限
   - 说明权限用途
   - 引导用户授权

4. **首次检测**：
   - 使用 UserDefaults 记录
   - 只在首次启动显示
   - 完成后不再显示

**测试要点**：
- 首次启动显示引导
- 步骤切换流畅
- 权限请求正常
- 完成后不再显示

**编译**：
使用 mcp__xcodebuildmcp__build 工具编译项目

**提交**：
```bash
git add Sources/Features/Onboarding/
git commit -m "feat: add onboarding flow"
```

---

### 7.6 打包配置（Entitlements 和 Info.plist）

**技术栈**：
- ✅ Entitlements（权限配置）
- ✅ Info.plist（应用配置）
- ✅ Build Settings
- ❌ 不涉及代码

**工具使用**：
- 📝 Xcode：配置文件编辑
- 🔨 编译：使用 XcodeBuildMCP

**文件 1**：`DropKit.entitlements`

**配置内容**：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- 沙盒模式（可选，根据需求决定） -->
    <key>com.apple.security.app-sandbox</key>
    <false/>
    
    <!-- 如果启用沙盒，需要以下权限 -->
    <!-- 
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    <key>com.apple.security.files.downloads.read-write</key>
    <true/>
    -->
    
    <!-- 辅助功能权限说明 -->
    <key>com.apple.security.automation.apple-events</key>
    <true/>
    
    <!-- 网络访问（如果需要） -->
    <!-- 
    <key>com.apple.security.network.client</key>
    <true/>
    -->
</dict>
</plist>
```

**文件 2**：`Info.plist`

**配置内容**：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- 应用基本信息 -->
    <key>CFBundleName</key>
    <string>DropKit</string>
    
    <key>CFBundleDisplayName</key>
    <string>DropKit</string>
    
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    
    <key>CFBundleVersion</key>
    <string>1</string>
    
    <key>CFBundleShortVersionString</key>
    <string>2.0.0</string>
    
    <!-- 隐藏 Dock 图标 -->
    <key>LSUIElement</key>
    <true/>
    
    <!-- 最低系统版本 -->
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    
    <!-- 权限说明 -->
    <key>NSAppleEventsUsageDescription</key>
    <string>DropKit 需要辅助功能权限来检测鼠标摇晃手势，以便在拖拽文件时显示悬浮窗。</string>
    
    <!-- 支持的文档类型（如果需要） -->
    <!-- 
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeName</key>
            <string>All Files</string>
            <key>CFBundleTypeRole</key>
            <string>Viewer</string>
            <key>LSItemContentTypes</key>
            <array>
                <string>public.item</string>
            </array>
        </dict>
    </array>
    -->
    
    <!-- 应用分类 -->
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.productivity</string>
    
    <!-- 版权信息 -->
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026 DropKit. All rights reserved.</string>
</dict>
</plist>
```

**Build Settings 配置**：

```
1. Signing & Capabilities:
   - Team: 选择你的开发团队
   - Bundle Identifier: com.yourname.dropkit
   - Signing Certificate: Developer ID Application
   - Provisioning Profile: Automatic

2. Build Settings:
   - Deployment Target: macOS 14.0
   - Swift Language Version: Swift 5
   - Optimization Level (Release): -O
   - Strip Debug Symbols (Release): Yes
   - Enable Bitcode: No (macOS 不需要)

3. Info:
   - Version: 2.0.0
   - Build: 1
```

**详细说明**：

1. **Entitlements**：
   - 沙盒模式：根据需求决定是否启用
   - 辅助功能：必需（用于全局事件监听）
   - 文件访问：如果启用沙盒需要配置

2. **Info.plist**：
   - LSUIElement: 隐藏 Dock 图标（菜单栏应用）
   - NSAppleEventsUsageDescription: 权限说明
   - LSMinimumSystemVersion: 最低系统版本

3. **签名配置**：
   - Developer ID: 用于分发到 Mac App Store 外
   - App Store: 用于 Mac App Store 分发
   - 开发测试: 使用开发证书

**测试要点**：
- 应用正确签名
- 权限说明显示正确
- Dock 图标隐藏
- 最低系统版本限制生效

**提交**：
```bash
git add DropKit.entitlements Info.plist
git commit -m "chore: configure entitlements and info.plist"
```

---

### 7.7 测试清单

**技术栈**：
- ✅ 手动测试
- ✅ 功能测试
- ✅ 兼容性测试
- ✅ 性能测试

**测试清单**：

#### 1. 基础功能测试

**悬浮窗功能**：
- [ ] 拖拽文件时摇晃鼠标，悬浮窗显示
- [ ] 文件可以拖入悬浮窗
- [ ] 文件可以从悬浮窗拖出
- [ ] 悬浮窗显示在正确位置
- [ ] 悬浮窗自动隐藏
- [ ] 多文件批量操作正常
- [ ] 缩略图显示正确
- [ ] 动画流畅

**剪切板历史**：
- [ ] 复制文本后自动记录
- [ ] 复制图片后自动记录
- [ ] 复制文件后自动记录
- [ ] 复制 URL 后自动记录
- [ ] ⌘⇧V 打开历史窗口
- [ ] 搜索功能正常
- [ ] 类型过滤正常
- [ ] 双击复制到剪切板
- [ ] 收藏功能正常
- [ ] 删除功能正常
- [ ] 清空历史正常

**菜单栏**：
- [ ] 菜单栏图标显示正常
- [ ] 深色模式适配正确
- [ ] 菜单项点击正常
- [ ] 快捷键显示正确
- [ ] 退出功能正常

**设置页面**：
- [ ] ⌘, 打开设置窗口
- [ ] 开机自启动开关正常
- [ ] 灵敏度调整生效
- [ ] 摇晃次数调整生效
- [ ] 悬浮窗位置选择生效
- [ ] 剪切板开关生效
- [ ] 历史数量限制生效
- [ ] 重置功能正常
- [ ] 设置持久化正常

#### 2. 权限测试

- [ ] 首次启动显示引导
- [ ] 辅助功能权限请求正常
- [ ] 无权限时功能禁用
- [ ] 授权后功能启用
- [ ] 权限说明清晰

#### 3. 错误处理测试

- [ ] 文件不存在时不崩溃
- [ ] 权限被拒时提示正确
- [ ] 数据损坏时不崩溃
- [ ] 内存不足时优雅降级
- [ ] 错误日志正确记录

#### 4. 性能测试

- [ ] 应用启动时间 < 1 秒
- [ ] 悬浮窗显示延迟 < 100ms
- [ ] 剪切板历史滚动流畅（60fps）
- [ ] 内存占用 < 100MB
- [ ] CPU 占用正常（空闲时 < 1%）
- [ ] 大量历史项目不卡顿

#### 5. 兼容性测试

**系统版本**：
- [ ] macOS 14.0 Sonoma
- [ ] macOS 15.0 Sequoia
- [ ] Intel 芯片
- [ ] Apple Silicon (M1/M2/M3)

**多显示器**：
- [ ] 双显示器环境正常
- [ ] 不同分辨率正常
- [ ] 不同缩放比例正常

**深色模式**：
- [ ] 浅色模式显示正常
- [ ] 深色模式显示正常
- [ ] 自动切换正常

#### 6. 边界情况测试

- [ ] 空剪切板历史
- [ ] 最大历史数量
- [ ] 超大文件（> 1GB）
- [ ] 特殊字符文件名
- [ ] 网络文件
- [ ] 只读文件
- [ ] 损坏的图片文件

#### 7. 用户体验测试

- [ ] 首次使用体验流畅
- [ ] 操作直观易懂
- [ ] 错误提示友好
- [ ] 快捷键不冲突
- [ ] 动画流畅自然
- [ ] 响应及时

**测试报告模板**：

```markdown
# DropKit v2.0.0 测试报告

## 测试环境
- 系统版本：macOS 14.2
- 芯片：Apple M1
- 内存：16GB
- 测试日期：2026-01-29

## 测试结果
- 通过：45/50
- 失败：5/50
- 通过率：90%

## 失败项目
1. [悬浮窗] 多显示器环境下位置不正确
2. [剪切板] 超大图片（> 10MB）加载慢
3. [性能] 1000+ 历史项目时滚动卡顿
4. [兼容性] macOS 13.0 启动项设置失败
5. [边界] 特殊字符文件名显示乱码

## 建议
1. 优化多显示器支持
2. 添加图片大小限制
3. 实现虚拟滚动
4. 添加 macOS 13 兼容代码
5. 修复文件名编码问题
```

---

### 7.8 发布准备

**技术栈**：
- ✅ Xcode Archive
- ✅ Notarization（公证）
- ✅ DMG 打包
- ✅ GitHub Release

**发布流程**：

#### 1. 版本号更新

```swift
// Info.plist
CFBundleShortVersionString: 2.0.0
CFBundleVersion: 1

// 版本号规则：
// 主版本.次版本.修订版本
// 2.0.0 - 重大更新
// 2.1.0 - 新功能
// 2.0.1 - Bug 修复
```

#### 2. 编译 Release 版本

```bash
# 使用 Xcode 编译
xcodebuild -scheme DropKit \
  -configuration Release \
  -archivePath ./build/DropKit.xcarchive \
  archive

# 导出应用
xcodebuild -exportArchive \
  -archivePath ./build/DropKit.xcarchive \
  -exportPath ./build/Release \
  -exportOptionsPlist ExportOptions.plist
```

**ExportOptions.plist**：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>signingStyle</key>
    <string>automatic</string>
</dict>
</plist>
```

#### 3. 公证（Notarization）

```bash
# 1. 压缩应用
ditto -c -k --keepParent ./build/Release/DropKit.app ./build/DropKit.zip

# 2. 提交公证
xcrun notarytool submit ./build/DropKit.zip \
  --apple-id "your@email.com" \
  --team-id "YOUR_TEAM_ID" \
  --password "app-specific-password" \
  --wait

# 3. 检查公证状态
xcrun notarytool info SUBMISSION_ID \
  --apple-id "your@email.com" \
  --team-id "YOUR_TEAM_ID" \
  --password "app-specific-password"

# 4. 装订公证票据
xcrun stapler staple ./build/Release/DropKit.app

# 5. 验证
xcrun stapler validate ./build/Release/DropKit.app
spctl -a -vv -t install ./build/Release/DropKit.app
```

#### 4. 创建 DMG 安装包

```bash
# 使用 create-dmg 工具
# 安装：brew install create-dmg

create-dmg \
  --volname "DropKit" \
  --volicon "Assets.xcassets/AppIcon.appiconset/icon_512x512@2x.png" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "DropKit.app" 175 120 \
  --hide-extension "DropKit.app" \
  --app-drop-link 425 120 \
  --no-internet-enable \
  "./build/DropKit-2.0.0.dmg" \
  "./build/Release/DropKit.app"
```

#### 5. 发布到 GitHub

```bash
# 1. 创建 Git 标签
git tag -a v2.0.0 -m "Release version 2.0.0"
git push origin v2.0.0

# 2. 创建 Release Notes
cat > RELEASE_NOTES.md << 'EOL'
# DropKit v2.0.0

## 新功能
- ✨ 悬浮窗功能：拖拽文件时摇晃鼠标显示悬浮窗
- ✨ 剪切板历史：自动记录复制内容
- ✨ 设置页面：自定义灵敏度、位置等
- ✨ 用户引导：首次启动引导流程

## 改进
- 🚀 性能优化：启动速度提升 50%
- 🎨 UI 美化：全新设计的界面
- 🌙 深色模式：完美适配深色模式

## 修复
- 🐛 修复多显示器环境下的问题
- 🐛 修复内存泄漏问题
- 🐛 修复权限检测问题

## 系统要求
- macOS 14.0 或更高版本
- 支持 Intel 和 Apple Silicon

## 安装方法
1. 下载 DropKit-2.0.0.dmg
2. 打开 DMG 文件
3. 将 DropKit 拖到应用程序文件夹
4. 首次启动时授予辅助功能权限

## 已知问题
- 暂无

---

**完整更新日志**: https://github.com/yourusername/dropkit/compare/v1.0.0...v2.0.0
EOL

# 3. 使用 gh CLI 创建 Release
gh release create v2.0.0 \
  ./build/DropKit-2.0.0.dmg \
  --title "DropKit v2.0.0" \
  --notes-file RELEASE_NOTES.md
```

#### 6. 发布检查清单

- [ ] 版本号已更新
- [ ] Release 版本编译成功
- [ ] 应用已签名
- [ ] 应用已公证
- [ ] DMG 已创建
- [ ] Git 标签已创建
- [ ] Release Notes 已准备
- [ ] GitHub Release 已发布
- [ ] 下载链接可用
- [ ] 安装测试通过

**详细说明**：

1. **版本管理**：
   - 遵循语义化版本规范
   - 主版本：重大更新
   - 次版本：新功能
   - 修订版本：Bug 修复

2. **签名和公证**：
   - Developer ID 签名
   - Apple 公证服务
   - 装订公证票据
   - 验证签名和公证

3. **DMG 打包**：
   - 美观的安装界面
   - 拖拽安装
   - 自定义背景和图标

4. **发布渠道**：
   - GitHub Releases
   - 官方网站
   - Mac App Store（可选）

**提交**：
```bash
git add .
git commit -m "chore: prepare for v2.0.0 release"
git push origin main
```

---

## 下一步

完成 Phase 7 后，DropKit v2 已经准备好发布：

✅ **已完成**：
- 应用图标设计
- 菜单栏图标优化
- 性能优化
- 错误处理完善
- 用户引导实现
- 打包配置完成
- 测试清单完成
- 发布准备完成

🎉 **恭喜！DropKit v2 开发完成！**

---

## 附录：常见问题

### Q1: 公证失败

**可能原因**：
- 签名不正确
- Entitlements 配置错误
- 包含不允许的内容

**解决方案**：
```bash
# 检查签名
codesign -dv --verbose=4 DropKit.app

# 检查 Entitlements
codesign -d --entitlements - DropKit.app

# 查看公证日志
xcrun notarytool log SUBMISSION_ID \
  --apple-id "your@email.com" \
  --team-id "YOUR_TEAM_ID" \
  --password "app-specific-password"
```

### Q2: DMG 创建失败

**可能原因**：
- 磁盘空间不足
- 权限问题
- 应用路径错误

**解决方案**：
```bash
# 检查磁盘空间
df -h

# 检查应用是否存在
ls -la ./build/Release/DropKit.app

# 手动创建 DMG
hdiutil create -volname "DropKit" \
  -srcfolder ./build/Release/DropKit.app \
  -ov -format UDZO \
  ./build/DropKit-2.0.0.dmg
```

### Q3: 应用无法打开（已损坏）

**可能原因**：
- 未公证
- 签名问题
- Gatekeeper 阻止

**解决方案**：
```bash
# 检查 Gatekeeper 状态
spctl --status

# 移除隔离属性
xattr -cr DropKit.app

# 允许应用运行
spctl --add DropKit.app
```

### Q4: 启动项设置失败

**可能原因**：
- macOS 版本不兼容
- Helper 应用未配置
- 权限不足

**解决方案**：
```swift
// 检查 macOS 版本
if #available(macOS 13.0, *) {
    // 使用新 API
    try SMAppService.mainApp.register()
} else {
    // 使用旧 API
    // 需要配置 Helper 应用
}

// 检查状态
let status = SMAppService.mainApp.status
print("Status: \(status)")
```

### Q5: 性能问题

**可能原因**：
- 内存泄漏
- 主线程阻塞
- 缓存未生效

**解决方案**：
```bash
# 使用 Instruments 分析
# 1. Time Profiler - CPU 占用
# 2. Allocations - 内存使用
# 3. Leaks - 内存泄漏

# 检查主线程
# 确保 UI 更新在主线程
# 确保耗时操作在后台线程
```

---

**Phase 7 完成！** 🎉

**DropKit v2 开发完成！** 🚀

