# CLAUDE.md - DropKit v2 AI 开发规范

> 本文件供 Claude Code 读取，定义开发规则和工作流程

---

## 项目信息

```
项目名称: DropKit v2
类型: macOS 菜单栏应用
技术栈: SwiftUI + AppKit 混合
目标系统: macOS 14.0+ (Sonoma)
Swift 版本: 5.9+
```

---

## 当前项目状态

### 已完成
- [x] 项目初始化 + Git
- [x] 基础 App 结构（DropKitApp.swift, AppDelegate.swift, AppState.swift）
- [x] 目录结构创建（Features/, Services/, Models/, Utilities/）

### 下一步
Phase 1.3: 创建 ShelfPanel（空的 NSPanel 窗口）

### 开发阶段参考
```
Phase 1: 最小可用悬浮窗（MVP）
  1.1 项目初始化 + Git ✅
  1.2 AppDelegate + 基础生命周期 ✅
  1.3 ShelfPanel (NSPanel 空窗口) ✅
  1.4 ShelfView (空状态 UI) ✅
  1.5 拖入功能 ✅
  1.6 拖出功能 ✅

Phase 2: 摇晃触发 ✅
Phase 3: 菜单栏 ✅
Phase 4: 悬浮窗完善 ← 当前（两层架构重构）
Phase 5: 剪切板历史 ✅
Phase 6: 设置页 ✅
Phase 7: 收尾 ✅
```

---

## Phase 4: 两层悬浮窗架构设计

### 架构说明

文件存储方式：只保存文件的路径引用，不复制文件本身。所有操作（预览、打开、在 Finder 中显示）都指向原文件位置。

### 状态枚举

```swift
enum ShelfViewState {
    case collapsed  // 收起状态
    case expanded   // 展开状态
}

enum DisplayMode {
    case grid   // 宫格模式
    case list   // 列表模式
}
```

### 视图结构

```
ShelfView
├── CollapsedView (收起状态)
│   ├── DragHandle (顶部拖动条，有文件时显示)
│   ├── CloseButton (左上角)
│   ├── CollapseButton (右上角，有文件时显示)
│   ├── EmptyState / StackedThumbnails (中间)
│   └── FilePreviewBar (底部，有文件时显示)
│
└── ExpandedView (展开状态)
    ├── NavigationBar
    │   ├── BackButton (左：返回收起状态)
    │   ├── StatsLabel (中：X张图片 XX KB)
    │   └── ViewModeButtons (右：预览/宫格/列表)
    ├── GridContentView (宫格模式)
    │   └── 缩略图 + 文件名 + 大小 + 尺寸
    └── ListContentView (列表模式)
        └── 小缩略图 + 文件名 + 大小 + 尺寸

右键菜单：在 Finder 中显示
```

### 窗口尺寸

- 收起状态（空）：约 200x200
- 收起状态（有文件）：约 200x240
- 展开状态：约 400x300

### ShelfItem 数据模型增强

```swift
struct ShelfItem: Identifiable {
    let id: UUID
    let url: URL
    let name: String
    var thumbnail: NSImage?      // 缩略图缓存
    var fileSize: Int64          // 文件大小（字节）
    var dimensions: CGSize?      // 图片尺寸（仅图片文件）
    var fileType: FileType       // 文件类型枚举
}

enum FileType {
    case image
    case video
    case document
    case other
}
```

### ShelfViewModel 状态增强

```swift
@Observable
class ShelfViewModel {
    var items: [ShelfItem] = []
    var viewState: ShelfViewState = .collapsed
    var displayMode: DisplayMode = .grid

    // 统计信息
    var totalSize: Int64 { ... }
    var itemCountDescription: String { ... }  // "1张图片" / "3个文件"
}
```

### 实现步骤

```
4.1 增强 ShelfItem 数据模型（添加 thumbnail, fileSize, dimensions, fileType）
4.2 增强 ShelfViewModel（添加 viewState, displayMode, 统计方法）
4.3 创建 CollapsedShelfView（收起状态视图）
4.4 创建 ExpandedShelfView（展开状态视图）
4.5 创建 GridContentView（宫格模式）
4.6 创建 ListContentView（列表模式）
4.7 实现缩略图异步生成
4.8 实现右键菜单（在 Finder 中显示）
4.9 更新 ShelfPanel 支持动态尺寸
4.10 测试 → commit
```

---

## 文件路径规则（重要）

### 项目根目录
```
/Users/chenhuajin/Desktop/Dropkit v2/DropKit/
```

### 源代码目录结构
```
DropKit/Sources/
├── App/                          # 应用入口（已有文件）
│   ├── DropKitApp.swift          # @main 入口
│   ├── AppDelegate.swift         # AppKit 生命周期
│   └── AppState.swift            # 全局状态 (@Observable)
│
├── Features/                     # 功能模块
│   ├── Shelf/                    # 悬浮窗
│   │   ├── ShelfPanel.swift      # NSPanel 窗口容器
│   │   ├── ShelfView.swift       # SwiftUI 视图
│   │   ├── ShelfViewModel.swift  # 视图模型
│   │   └── ShelfItem.swift       # 数据模型
│   ├── Clipboard/                # 剪切板
│   ├── MenuBar/                  # 菜单栏
│   └── Settings/                 # 设置
│
├── Services/                     # 核心服务
│   ├── ShakeDetector.swift       # 摇晃检测
│   ├── DragMonitor.swift         # 拖拽监听
│   └── ClipboardMonitor.swift    # 剪切板监听
│
├── Models/                       # 数据模型
│   ├── AppSettings.swift         # 设置模型
│   └── DataStore.swift           # 本地存储
│
└── Utilities/                    # 工具类
    ├── Extensions/               # 扩展
    └── Helpers/                  # 辅助函数
```

### 新建文件路径示例
```
创建 ShelfPanel.swift:
→ DropKit/Sources/Features/Shelf/ShelfPanel.swift

创建 DragMonitor.swift:
→ DropKit/Sources/Services/DragMonitor.swift

创建 ShelfItem.swift:
→ DropKit/Sources/Features/Shelf/ShelfItem.swift
```

---

## 编译与运行

### 编译命令
```bash
# 进入项目目录
cd "/Users/chenhuajin/Desktop/Dropkit v2/DropKit"

# ⚠️ 重要：编译前必须先清理旧进程
pkill -f DropKit

# 编译
xcodebuild -scheme DropKit -configuration Debug build

# 或使用 XcodeBuildMCP（如果可用）
```

### 运行应用
```bash
# 编译后的应用位置（DerivedData）
open /Users/chenhuajin/Library/Developer/Xcode/DerivedData/DropKit-bqmlcvlnjuylvzeagcwxbprezsdf/Build/Products/Debug/DropKit.app

# 或者本地 build 目录
open ./build/Debug/DropKit.app
```

### 一键编译运行
```bash
# 清理旧进程 + 编译 + 运行
pkill -f DropKit; cd "/Users/chenhuajin/Desktop/Dropkit v2/DropKit" && xcodebuild -scheme DropKit -configuration Debug build && open /Users/chenhuajin/Library/Developer/Xcode/DerivedData/DropKit-bqmlcvlnjuylvzeagcwxbprezsdf/Build/Products/Debug/DropKit.app
```

### 清理构建
```bash
xcodebuild clean -scheme DropKit
```

---

## 现有代码说明

### AppState.swift
```swift
// 使用 Swift 5.9+ 的 @Observable 宏
@Observable
class AppState {
    var isShelfVisible = false
    // 添加新状态属性在这里
}
```

### 如何在新代码中使用 AppState
```swift
// 在 SwiftUI 视图中
struct SomeView: View {
    @Environment(AppState.self) var appState
    // 或通过初始化传入
}

// 在 AppKit 类中
class SomePanel: NSPanel {
    var appState: AppState

    init(appState: AppState) {
        self.appState = appState
        // ...
    }
}
```

### AppDelegate.swift
```swift
// 在 applicationDidFinishLaunching 中初始化核心服务
// 例如：创建 ShelfPanel、启动 DragMonitor 等
```

---

## 核心规则（必须遵守）

### 规则 1：Git 优先

```
改代码前：
1. git status  # 确认工作区状态
2. 如果有未提交的改动，先 commit 或询问我

改代码后：
1. 编译测试通过
2. 等我确认功能正常
3. 我说"commit"后再执行 git commit

禁止操作（执行前必须询问我）：
- git reset --hard
- git clean -fd
- 任何删除文件的操作
```

### 规则 2：最小改动原则

```
- 每次只改一个功能点
- 不要顺手"优化"其他代码
- 不要重构我没提到的部分
- 改完一个，测试通过，再改下一个
```

### 规则 3：编译验证

```
每次改完代码必须编译：
1. 使用 XcodeBuildMCP 编译（如果可用）
2. 或者执行: xcodebuild -scheme DropKit -configuration Debug build

编译失败时：
1. 先看错误信息
2. 只修复编译错误
3. 不要趁机改其他东西
```

### 规则 4：不主动更新文档

```
除非我明确要求，否则：
- 不要更新 README.md
- 不要更新 CHANGELOG.md
- 不要添加注释说明改了什么

变更记录由 git commit message 承担
```

---

## 技术约束

### 必须使用

```swift
// 悬浮窗
NSPanel  // 不要用 NSWindow 或 SwiftUI Window

// 菜单栏
NSStatusItem  // 不要用 MenuBarExtra

// 全局事件监听
NSEvent.addGlobalMonitorForEvents

// 拖拽
NSDraggingDestination / NSDraggingSource

// 剪切板
NSPasteboard.general
```

### 禁止使用

```swift
// 不要用这些做悬浮窗
MenuBarExtra
SwiftUI Window
SwiftUI WindowGroup

// 不要用第三方库（除非我明确要求）
```

---

## 技术规范

### 架构分层

```
Features/     # 功能模块（按功能划分）
Services/     # 核心服务（全局监听、检测器）
Models/       # 数据模型
Utilities/    # 工具类、扩展
```

### 命名规范

```swift
// 文件名
ShelfPanel.swift        // AppKit 窗口类
ShelfView.swift         // SwiftUI 视图
ShelfViewModel.swift    // 视图模型
ShelfItem.swift         // 数据模型

// 类名
class ShelfPanel: NSPanel { }
struct ShelfView: View { }
class ShelfViewModel: ObservableObject { }
struct ShelfItem: Identifiable { }

// 变量名
let shelfPanel: ShelfPanel
@StateObject var viewModel: ShelfViewModel
@Published var items: [ShelfItem]

// 常量
let maxItems = 100
let SHAKE_THRESHOLD = 3
```

### SwiftUI 视图结构

```swift
struct SomeView: View {
    // 1. 属性（按顺序）
    @ObservedObject var viewModel: SomeViewModel
    @State private var isHovered = false
    
    // 2. body
    var body: some View {
        // 使用系统颜色（自动适配深色模式）
        // .foregroundColor(.primary)
        // .background(.regularMaterial)
        // 使用 SF Symbols
        // Image(systemName: "doc.on.clipboard")
        // 标准圆角
        // .clipShape(RoundedRectangle(cornerRadius: 12))
        // 标准动画
        // .animation(.easeInOut(duration: 0.2), value: someValue)
    }
    
    // 3. 子视图（提取复杂部分）
    private var headerView: some View {
        // ...
    }
    
    // 4. 方法
    private func handleTap() {
        // ...
    }
}
```

### AppKit 规范

```swift
// 悬浮窗必须设置
panel.level = .floating
panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
panel.styleMask = [.borderless, .nonactivatingPanel]
panel.isOpaque = false
panel.backgroundColor = .clear

// 全局事件监听
NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDragged) { event in
    // 处理
}
```

### 异步处理

```swift
// 缩略图生成、文件读取必须异步
Task {
    let thumbnail = await generateThumbnail(for: url)
    await MainActor.run {
        self.thumbnail = thumbnail
    }
}
```

---

## 开发流程

### 新功能开发

```
1. 我描述需求
2. 你确认理解（简短复述）
3. git status 确认工作区干净
4. 复杂功能先说方案，我确认后再写代码
5. 写代码
6. 编译
7. 我测试
8. 通过 → 我说 commit
9. 不通过 → 你修复，回到步骤 6
```

### Bug 修复

```
1. 我描述问题
2. 你分析可能原因（不要直接改）
3. 我确认方向
4. git status
5. 最小改动修复
6. 编译测试
7. commit
```

### 回退操作

```
当我说"回到上一个版本"：
1. 先提醒我：这会丢弃所有未提交的改动
2. 等我确认
3. 执行: git checkout .

当我说"回到某个 commit"：
1. 先 git log --oneline -10 给我看
2. 我选择具体 commit
3. 再执行回退
```

---

## 功能模块指南

### 悬浮窗 (Shelf)

```
核心文件:
- ShelfPanel.swift      # NSPanel，窗口容器
- ShelfView.swift       # SwiftUI，内部 UI
- ShelfViewModel.swift  # 状态管理
- ShelfItem.swift       # 数据模型

核心要求:
1. 拖拽文件时摇晃鼠标才触发（不是随时摇晃都触发）
2. 文件可拖入
3. 文件可拖出
4. 浮在所有窗口之上
5. 毛玻璃背景

关键点:
- 拖入: registerForDraggedTypes + performDragOperation
- 拖出: NSDraggingSource 协议
- 层级: panel.level = .floating
- 触发: 由 ShakeDetector + DragMonitor 控制

触发逻辑:
DragMonitor.isDragging == true && ShakeDetector.shakeDetected
→ 显示 ShelfPanel
```

### 摇晃检测 (ShakeDetector)

```
核心逻辑:
1. 监听全局鼠标移动 (NSEvent.addGlobalMonitorForEvents)
2. 记录 X 坐标变化方向
3. 短时间内方向反转 >= 3 次 → 触发
4. 只在 DragMonitor.isDragging == true 时检测

参数:
- sensitivity: 灵敏度 (0-1)
- minShakes: 最少反转次数 (默认 3)
- timeWindow: 时间窗口 (默认 0.5 秒)

前置条件:
- 需要辅助功能权限才能工作
- 初始化时应检查权限状态
```

### 拖拽检测 (DragMonitor)

```
职责: 判断用户是否正在拖拽（仅状态判断，不读取内容）

实现方式:
1. 监听 .leftMouseDragged 事件 → isDragging = true
2. 监听 .leftMouseUp 事件 → isDragging = false

输出:
- isDragging: Bool
- onDragStart / onDragEnd 回调

⚠️ 重要警告:
- 不要在 DragMonitor 里读取 NSPasteboard
- 拖拽过程中 NSPasteboard.general 读不到正在拖拽的内容
- 拖拽内容只能在 drop 回调中通过 NSDraggingInfo.draggingPasteboard 获取
- DragMonitor 只负责布尔状态，不负责内容获取
```

### 拖拽内容获取（重要）

```
正确时机: ShelfPanel 的 performDragOperation 回调

正确方式:
func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
    let pasteboard = sender.draggingPasteboard
    // 在这里读取文件 URL、图片等内容
    if let urls = pasteboard.readObjects(forClasses: [NSURL.self]) as? [URL] {
        // 处理文件
    }
    return true
}

错误方式:
// ❌ 不要在拖拽过程中读取 NSPasteboard.general
// ❌ 不要在 DragMonitor 里读取 pasteboard
// ❌ 这样会拿到上一次复制的内容，造成误判
```

### 剪切板 (Clipboard)

```
核心文件:
- ClipboardMonitor.swift    # 监听剪切板变化
- ClipboardItem.swift       # 数据模型
- ClipboardHistoryView.swift # UI
- ClipboardViewModel.swift  # 状态管理

关键点:
- 定时检查 NSPasteboard.general.changeCount
- 支持类型: text, html, image, file, url
- 持久化: UserDefaults 或 JSON 文件
```

### 菜单栏 (MenuBar)

```
菜单项：
- 打开剪切板历史 (⌘⇧V)
- 显示悬浮窗 (⌘⇧S)
- ---
- 设置... (⌘,)
- 关于 DropKit
- ---
- 退出 (⌘Q)
```

---

## 权限处理（关键路径）

### 辅助功能权限

```
为什么需要:
- NSEvent.addGlobalMonitorForEvents 需要此权限
- 没有权限时回调根本不会触发
- 不会报错，不会弹窗提示
- 代码看起来正确但就是不工作

这是开发中最容易踩的坑！
```

### 权限检测代码

```swift
import ApplicationServices

// 检测权限（不弹窗）
func checkAccessibilityPermission() -> Bool {
    let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
    return AXIsProcessTrustedWithOptions(options as CFDictionary)
}

// 请求权限（弹出系统设置）
func requestAccessibilityPermission() {
    let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
    AXIsProcessTrustedWithOptions(options as CFDictionary)
}
```

### 权限引导流程设计

```
1. 应用启动时检查权限
2. 无权限时显示引导界面（不是直接弹系统设置）
3. 引导界面说明：
   - 为什么需要这个权限（检测鼠标摇晃手势）
   - 具体操作步骤
   - 「打开系统设置」按钮
4. 用户授权后需要重启应用才能生效
5. 提供「重新检查权限」按钮

注意事项：
- 权限变更后监听器不会自动生效，需要重新注册
- 建议在 ShakeDetector / DragMonitor 初始化时检查权限状态
- 无权限时应禁用相关功能并提示用户
```

### Entitlements 配置

```xml
<key>com.apple.security.automation.apple-events</key>
<true/>
```

### Info.plist 配置

```xml
<!-- 隐藏 Dock 图标 -->
<key>LSUIElement</key>
<true/>

<!-- 应用名称 -->
<key>CFBundleName</key>
<string>DropKit</string>
```

---

## 调试指南

### 权限问题排查（优先检查）

```
如果全局监听不工作：
1. 首先检查辅助功能权限
2. 系统设置 → 隐私与安全 → 辅助功能
3. 确认应用在列表中且已勾选
4. 权限变更后需要重启应用
```

### 悬浮窗不显示

```
检查:
1. panel.orderFront(nil) 是否调用
2. panel.level 是否设置为 .floating
3. panel.frame 是否在屏幕内
4. panel.isVisible 状态
5. collectionBehavior 是否正确
```

### 拖入不工作

```
检查:
1. registerForDraggedTypes 是否调用
2. draggingEntered 是否返回正确的 NSDragOperation
3. performDragOperation 是否正确处理
4. 是否在正确的回调里读取 NSDraggingInfo
```

### 拖出不工作

```
检查:
1. 是否实现 NSDraggingSource
2. draggingSession 是否正确创建
3. pasteboard 是否正确写入
```

### 摇晃不触发

```
检查:
1. 辅助功能权限是否已授予（最常见原因）
2. DragMonitor.isDragging 是否为 true
3. ShakeDetector 是否启动
4. 灵敏度参数是否合理
```

### 查看调试信息

```swift
// 拖拽状态
print("isDragging: \(dragMonitor.isDragging)")

// 摇晃检测
print("shake count: \(shakeDetector.currentShakeCount)")

// 窗口层级
print("panel level: \(panel.level.rawValue)")
print("panel isVisible: \(panel.isVisible)")

// 权限状态
print("accessibility: \(checkAccessibilityPermission())")
```

---

## Commit Message 规范

```
格式：<type>: <description>

类型：
- feat: 新功能
- fix: 修复 bug
- refactor: 重构（不改变功能）
- style: 代码格式调整
- docs: 文档更新
- chore: 构建/配置相关

示例：
feat: basic shelf drag in/out
fix: shelf not showing on shake
refactor: extract thumbnail generation
```

---

## 可用工具

### MCP 服务器

```
XcodeBuildMCP: 编译项目
- mcp__xcodebuildmcp__build
- mcp__xcodebuildmcp__test
```

### Skills

```
Axiom: Swift/SwiftUI/Xcode 问题
superpowers: 设计和规划流程
```

---

## 常见问题

### Q: 编译报错 "Cannot find X in scope"

```
可能原因:
1. import 缺失
2. 文件没加入 Target
3. 拼写错误

处理: 先看完整错误信息，定位具体文件和行号
```

### Q: 悬浮窗出现在错误位置

```
检查:
1. NSEvent.mouseLocation 获取鼠标位置
2. NSScreen.main?.frame 获取屏幕范围
3. 坐标转换是否正确（macOS 坐标系 Y 轴向上）
```

### Q: 改了代码但没生效

```
检查:
1. 是否保存了文件
2. 是否重新编译
3. 是否重新运行应用
4. 是否改对了文件（可能有同名文件）
```

### Q: 代码改坏了

```
1. 不要继续改
2. git status 看改了什么
3. git diff 看具体改动
4. 如果改动不多：手动撤销错误部分
5. 如果改动很多：git checkout . 回到上次 commit
```

### Q: 编译大量报错

```
1. 不要乱修
2. 从第一个错误开始修
3. 通常第一个错误修好后，后面的会消失
4. 如果是结构性错误：考虑 git checkout . 回退
```

---

## 禁止事项

```
❌ 不要在没有 git status 的情况下改代码
❌ 不要一次改多个不相关的功能
❌ 不要删除我没提到的代码
❌ 不要重命名我没要求重命名的文件
❌ 不要添加我没要求的新依赖
❌ 不要"顺便优化"
❌ 不要在修复 bug 时添加新功能
❌ 不要假设我想要什么，不确定就问
❌ 不要在 DragMonitor 里读取 NSPasteboard
```

---

## 沟通规范

### 回复格式

```
改代码时:
1. 简短说明改了什么（1-2 句）
2. 贴出改动的代码
3. 说明如何测试

遇到问题时:
1. 说明问题是什么
2. 给出可能的原因
3. 问我想怎么处理（不要自作主张）
```

### 确认节点

```
以下情况必须等我确认后再继续:
- 要删除文件
- 要重命名文件
- 要改动架构
- 要添加新依赖
- 编译失败超过 2 次
- 不确定需求含义
```

---

## 最后提醒

```
1. 每次改动都要小，改完就测试
2. 不确定的方案先问我
3. 核心功能（拖入拖出）改动要特别小心
4. 遇到问题先分析原因，不要盲目尝试
5. Git 是后悔药，善用它
6. 辅助功能权限是第一道坎，提前处理好
7. 拖拽内容只在 drop 回调里获取
```
