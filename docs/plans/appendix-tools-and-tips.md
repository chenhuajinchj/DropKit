# 附录：工具和技巧

> 创建日期：2026-01-29

---

## 概述

本文档提供 DropKit v2 开发过程中使用的工具详解、常见问题汇总、调试技巧、性能优化建议和安全注意事项。

---

## 目录

1. [工具详解](#工具详解)
2. [常见问题汇总](#常见问题汇总)
3. [调试技巧](#调试技巧)
4. [性能优化建议](#性能优化建议)
5. [安全注意事项](#安全注意事项)

---

## 工具详解

### XcodeBuildMCP

**简介**：XcodeBuildMCP 是一个用于编译 Xcode 项目的 MCP 服务器。

**使用方式**：

```
mcp__xcodebuildmcp__build
```

**功能**：
- ✅ 编译项目
- ✅ 运行测试
- ✅ 清理构建产物
- ✅ 查看编译日志

**常见用法**：

```bash
# 编译项目
mcp__xcodebuildmcp__build

# 编译并运行测试
mcp__xcodebuildmcp__test

# 清理构建
mcp__xcodebuildmcp__clean
```

**优点**：
- 快速编译
- 详细的错误信息
- 集成到开发流程

**注意事项**：
- 确保 Xcode 已安装
- 确保项目配置正确
- 编译失败时查看完整日志

---

### Axiom Skill

**简介**：Axiom 是 Swift/SwiftUI/Xcode 专家技能，用于解决编译错误和复杂问题。

**使用方式**：

```
/using-axiom [问题描述]
```

**适用场景**：
- ✅ 编译错误
- ✅ SwiftUI 布局问题
- ✅ Combine 响应式编程
- ✅ async/await 异步代码
- ✅ AppKit 集成问题

**使用示例**：

```
# 编译错误
/using-axiom "Cannot find 'NSPanel' in scope"

# SwiftUI 问题
/using-axiom "如何在 SwiftUI 中实现拖拽功能"

# Combine 问题
/using-axiom "如何使用 Combine 监听 NSPasteboard 变化"

# 异步问题
/using-axiom "如何在后台线程生成缩略图"
```

**最佳实践**：
- 提供完整的错误信息
- 说明你想实现的功能
- 提供相关代码片段
- 说明已尝试的方案

---

### Instruments

**简介**：Xcode 自带的性能分析工具。

**使用方式**：

```bash
# 启动 Instruments
open -a Instruments

# 或在 Xcode 中
Product > Profile (⌘I)
```

**常用工具**：

1. **Time Profiler**：
   - 分析 CPU 占用
   - 找出性能瓶颈
   - 优化热点代码

2. **Allocations**：
   - 分析内存使用
   - 找出内存泄漏
   - 优化内存占用

3. **Leaks**：
   - 检测内存泄漏
   - 找出循环引用
   - 修复内存问题

4. **System Trace**：
   - 分析系统调用
   - 找出 I/O 瓶颈
   - 优化系统交互

**使用技巧**：
- 使用 Release 配置分析
- 关注热点函数
- 对比优化前后
- 记录分析结果

---

## 常见问题汇总

### 编译问题

#### Q1: Cannot find 'NSPanel' in scope

**原因**：未导入 AppKit

**解决方案**：
```swift
import AppKit
```

#### Q2: Type 'SomeView' does not conform to protocol 'View'

**原因**：body 属性类型错误

**解决方案**：
```swift
struct SomeView: View {
    var body: some View {  // 确保返回 some View
        Text("Hello")
    }
}
```

#### Q3: Cannot convert value of type 'X' to expected argument type 'Y'

**原因**：类型不匹配

**解决方案**：
```swift
// 显式类型转换
let value = someValue as? ExpectedType

// 或使用正确的类型
let value: ExpectedType = ...
```

---

### 运行时问题

#### Q1: 悬浮窗不显示

**可能原因**：
- panel.orderFront(nil) 未调用
- panel.level 设置不正确
- panel.frame 在屏幕外

**解决方案**：
```swift
// 确保正确配置
panel.level = .floating
panel.orderFront(nil)
panel.makeKeyAndOrderFront(nil)

// 检查位置
print("Panel frame: \(panel.frame)")
print("Screen frame: \(NSScreen.main?.frame ?? .zero)")
```

#### Q2: 全局事件监听不工作

**可能原因**：
- 辅助功能权限未授予
- 监听器未正确注册

**解决方案**：
```swift
// 检查权限
let hasPermission = AXIsProcessTrusted()
print("Has permission: \(hasPermission)")

// 重新注册监听器
NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDragged) { event in
    print("Event received: \(event)")
}
```

#### Q3: 剪切板监听不工作

**可能原因**：
- Timer 未启动
- changeCount 检测失败

**解决方案**：
```swift
// 检查 Timer
print("Timer running: \(timer != nil)")

// 检查 changeCount
let count = NSPasteboard.general.changeCount
print("Change count: \(count)")
```

---

### 权限问题

#### Q1: 辅助功能权限请求不弹出

**原因**：已经请求过，需要手动授权

**解决方案**：
```
1. 打开系统设置
2. 隐私与安全 > 辅助功能
3. 找到 DropKit 并勾选
4. 重启应用
```

#### Q2: 权限授予后仍不工作

**原因**：需要重启应用

**解决方案**：
```swift
// 提示用户重启
let alert = NSAlert()
alert.messageText = "需要重启应用"
alert.informativeText = "权限已授予，请重启应用以使其生效"
alert.runModal()

// 退出应用
NSApp.terminate(nil)
```

---

## 调试技巧

### 1. 打印调试

**基础打印**：
```swift
print("Debug: \(value)")
```

**格式化打印**：
```swift
print("📍 Location: \(location)")
print("✅ Success: \(result)")
print("❌ Error: \(error)")
print("⚠️ Warning: \(message)")
```

**条件打印**：
```swift
#if DEBUG
print("Debug mode: \(value)")
#endif
```

**自定义调试函数**：
```swift
func debugLog(_ message: String, file: String = #file, line: Int = #line) {
    #if DEBUG
    let fileName = (file as NSString).lastPathComponent
    print("[\(fileName):\(line)] \(message)")
    #endif
}

// 使用
debugLog("Panel frame: \(panel.frame)")
```

---

### 2. 断点调试

**设置断点**：
- 点击行号左侧设置断点
- ⌘\ 快速设置/取消断点

**条件断点**：
```
右键断点 > Edit Breakpoint
Condition: count > 10
```

**符号断点**：
```
Debug > Breakpoints > Create Symbolic Breakpoint
Symbol: NSPanel.orderFront
```

**异常断点**：
```
Debug > Breakpoints > Create Exception Breakpoint
Exception: All
```

---

### 3. LLDB 命令

**常用命令**：
```lldb
# 打印变量
po variable

# 打印表达式
p expression

# 查看对象
po self

# 查看视图层级
po view.recursiveDescription()

# 修改变量
expr variable = newValue

# 继续执行
c

# 单步执行
n

# 进入函数
s
```

**调试 UI**：
```lldb
# 查看视图层级
po NSApp.windows

# 查看 panel 属性
po panel.frame
po panel.level
po panel.isVisible

# 强制刷新 UI
expr CATransaction.flush()
```

---

### 4. 日志系统

**使用 OSLog**：
```swift
import os.log

let logger = Logger(subsystem: "com.dropkit.app", category: "general")

logger.debug("Debug message")
logger.info("Info message")
logger.warning("Warning message")
logger.error("Error message")
logger.fault("Fault message")
```

**查看日志**：
```bash
# 使用 Console.app
open -a Console

# 或使用命令行
log stream --predicate 'subsystem == "com.dropkit.app"'
```

---

### 5. 性能调试

**测量执行时间**：
```swift
let start = CFAbsoluteTimeGetCurrent()
// 执行代码
let duration = CFAbsoluteTimeGetCurrent() - start
print("Duration: \(duration)s")
```

**使用 Signpost**：
```swift
import os.signpost

let log = OSLog(subsystem: "com.dropkit.app", category: .pointsOfInterest)

os_signpost(.begin, log: log, name: "Load Thumbnail")
// 执行代码
os_signpost(.end, log: log, name: "Load Thumbnail")
```

---

## 性能优化建议

### 1. 启动优化

**延迟初始化**：
```swift
// 不要在启动时初始化所有组件
// 按需初始化

lazy var clipboardMonitor: ClipboardMonitor = {
    return ClipboardMonitor()
}()
```

**异步加载**：
```swift
// 启动时异步加载数据
Task {
    let items = await storage.load()
    await MainActor.run {
        self.items = items
    }
}
```

**减少启动任务**：
```swift
// 只在启动时做必要的事情
// 其他任务延迟到首次使用时
```

---

### 2. 内存优化

**使用弱引用**：
```swift
// 避免循环引用
weak var delegate: SomeDelegate?

// 闭包中使用 weak self
someMethod { [weak self] in
    self?.doSomething()
}
```

**及时释放资源**：
```swift
// 不再使用时释放
deinit {
    timer?.invalidate()
    monitor.stopMonitoring()
}
```

**使用缓存**：
```swift
// 使用 NSCache 自动管理内存
let cache = NSCache<NSString, NSImage>()
cache.countLimit = 100
cache.totalCostLimit = 50 * 1024 * 1024
```

---

### 3. UI 优化

**使用 LazyVStack**：
```swift
// 大列表使用 LazyVStack
ScrollView {
    LazyVStack {
        ForEach(items) { item in
            ItemView(item: item)
        }
    }
}
```

**避免过度绘制**：
```swift
// 使用 .drawingGroup() 优化复杂视图
ComplexView()
    .drawingGroup()
```

**减少状态更新**：
```swift
// 使用 @Published 时注意更新频率
// 使用 debounce 减少更新
$searchText
    .debounce(for: 0.3, scheduler: DispatchQueue.main)
    .sink { text in
        self.performSearch(text)
    }
```

---

### 4. 异步优化

**使用 async/await**：
```swift
// 避免阻塞主线程
func loadThumbnail() async -> NSImage? {
    return await withCheckedContinuation { continuation in
        DispatchQueue.global().async {
            let thumbnail = generateThumbnail()
            continuation.resume(returning: thumbnail)
        }
    }
}
```

**并发执行**：
```swift
// 使用 TaskGroup 并发执行多个任务
await withTaskGroup(of: NSImage?.self) { group in
    for url in urls {
        group.addTask {
            await loadThumbnail(for: url)
        }
    }
    
    for await thumbnail in group {
        thumbnails.append(thumbnail)
    }
}
```

---

### 5. 数据优化

**分页加载**：
```swift
// 不要一次加载所有数据
func loadMore() {
    let start = items.count
    let end = start + 50
    let newItems = storage.load(range: start..<end)
    items.append(contentsOf: newItems)
}
```

**压缩存储**：
```swift
// 图片使用 JPEG 压缩
if let jpegData = image.jpegData(compressionQuality: 0.7) {
    try jpegData.write(to: url)
}
```

**索引优化**：
```swift
// 使用字典加速查找
var itemsById: [UUID: ClipboardItem] = [:]

for item in items {
    itemsById[item.id] = item
}

// O(1) 查找
let item = itemsById[id]
```

---

## 安全注意事项

### 1. 权限管理

**最小权限原则**：
```swift
// 只请求必要的权限
// 不要请求不需要的权限
```

**权限说明**：
```xml
<!-- Info.plist 中提供清晰的权限说明 -->
<key>NSAppleEventsUsageDescription</key>
<string>DropKit 需要辅助功能权限来检测鼠标摇晃手势</string>
```

**权限检查**：
```swift
// 使用前检查权限
func checkPermission() -> Bool {
    return AXIsProcessTrusted()
}

// 无权限时禁用功能
if !checkPermission() {
    disableFeature()
    showPermissionAlert()
}
```

---

### 2. 数据安全

**敏感数据处理**：
```swift
// 不记录敏感内容
func isSensitive(_ text: String) -> Bool {
    // 检测密码、信用卡等
    let patterns = [
        "password", "pwd", "passwd",
        "\\d{4}[- ]?\\d{4}[- ]?\\d{4}[- ]?\\d{4}" // 信用卡
    ]
    
    for pattern in patterns {
        if text.range(of: pattern, options: .regularExpression) != nil {
            return true
        }
    }
    
    return false
}

// 使用
if !isSensitive(text) {
    saveToHistory(text)
}
```

**数据加密**：
```swift
// 敏感数据加密存储
import CryptoKit

func encrypt(_ data: Data, key: SymmetricKey) throws -> Data {
    let sealedBox = try AES.GCM.seal(data, using: key)
    return sealedBox.combined!
}

func decrypt(_ data: Data, key: SymmetricKey) throws -> Data {
    let sealedBox = try AES.GCM.SealedBox(combined: data)
    return try AES.GCM.open(sealedBox, using: key)
}
```

---

### 3. 输入验证

**文件路径验证**：
```swift
func isValidPath(_ path: String) -> Bool {
    // 检查路径是否合法
    let fileManager = FileManager.default
    
    // 检查是否存在
    guard fileManager.fileExists(atPath: path) else {
        return false
    }
    
    // 检查是否可读
    guard fileManager.isReadableFile(atPath: path) else {
        return false
    }
    
    return true
}
```

**URL 验证**：
```swift
func isValidURL(_ string: String) -> Bool {
    guard let url = URL(string: string) else {
        return false
    }
    
    // 检查 scheme
    guard let scheme = url.scheme,
          ["http", "https"].contains(scheme) else {
        return false
    }
    
    return true
}
```

---

### 4. 错误处理

**不暴露敏感信息**：
```swift
// 错误信息不要包含敏感路径
// ❌ 错误
throw AppError.fileNotFound("/Users/username/secret.txt")

// ✅ 正确
throw AppError.fileNotFound("配置文件")
```

**安全的错误日志**：
```swift
func logError(_ error: Error) {
    // 过滤敏感信息
    let message = sanitize(error.localizedDescription)
    print("Error: \(message)")
}

func sanitize(_ text: String) -> String {
    // 移除路径中的用户名
    return text.replacingOccurrences(
        of: "/Users/[^/]+/",
        with: "/Users/****/",
        options: .regularExpression
    )
}
```

---

### 5. 沙盒安全

**文件访问限制**：
```swift
// 只访问用户选择的文件
func openFile() {
    let panel = NSOpenPanel()
    panel.canChooseFiles = true
    panel.canChooseDirectories = false
    
    if panel.runModal() == .OK {
        if let url = panel.url {
            // 安全访问
            processFile(at: url)
        }
    }
}
```

**网络请求安全**：
```swift
// 使用 HTTPS
guard let url = URL(string: "https://api.example.com") else {
    return
}

// 验证证书
let session = URLSession(configuration: .default)
// 配置证书验证
```

---

## 最佳实践总结

### 开发流程

1. **规划先行**：
   - 明确需求
   - 设计架构
   - 评估风险

2. **小步迭代**：
   - 每次只改一个功能
   - 改完立即测试
   - 通过后再继续

3. **代码审查**：
   - 自我审查
   - 同行审查
   - 工具检查

4. **测试充分**：
   - 单元测试
   - 集成测试
   - 手动测试

5. **文档完善**：
   - 代码注释
   - API 文档
   - 用户文档

---

### 代码质量

1. **命名规范**：
   - 清晰明确
   - 符合约定
   - 避免缩写

2. **函数设计**：
   - 单一职责
   - 参数合理
   - 返回明确

3. **错误处理**：
   - 预期错误
   - 优雅降级
   - 友好提示

4. **性能考虑**：
   - 避免过早优化
   - 关注热点
   - 测量验证

5. **安全意识**：
   - 最小权限
   - 输入验证
   - 数据保护

---

### 团队协作

1. **版本控制**：
   - 频繁提交
   - 清晰消息
   - 分支管理

2. **代码规范**：
   - 统一风格
   - 自动格式化
   - Lint 检查

3. **沟通协作**：
   - 及时沟通
   - 文档共享
   - 知识传递

4. **持续改进**：
   - 复盘总结
   - 优化流程
   - 学习成长

---

## 参考资源

### 官方文档

- [Swift 官方文档](https://swift.org/documentation/)
- [SwiftUI 教程](https://developer.apple.com/tutorials/swiftui)
- [AppKit 文档](https://developer.apple.com/documentation/appkit)
- [Xcode 帮助](https://developer.apple.com/documentation/xcode)

### 社区资源

- [Swift Forums](https://forums.swift.org/)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/swift)
- [GitHub](https://github.com/topics/swift)
- [Reddit r/swift](https://www.reddit.com/r/swift/)

### 推荐书籍

- 《Swift 编程语言》
- 《iOS 编程》
- 《Effective Swift》
- 《SwiftUI 实战》

### 推荐工具

- [SwiftLint](https://github.com/realm/SwiftLint) - 代码规范检查
- [SwiftFormat](https://github.com/nicklockwood/SwiftFormat) - 代码格式化
- [Periphery](https://github.com/peripheryapp/periphery) - 死代码检测
- [Sourcery](https://github.com/krzysztofzablocki/Sourcery) - 代码生成

---

**附录完成！** 📚

