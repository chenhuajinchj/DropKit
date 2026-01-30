# Phase 1: 最小可用悬浮窗 (MVP)

> 创建日期：2026-01-29
> 状态：待开发

---

## Phase 概述

**目标**：实现一个能拖入文件、能拖出文件的基础悬浮窗

**预计时间**：第 1-3 天

**成功标准**：
- ✅ 悬浮窗能显示在屏幕上
- ✅ 能拖入文件到悬浮窗
- ✅ 能从悬浮窗拖出文件
- ✅ 悬浮窗浮在所有窗口之上
- ✅ 编译通过，无警告

---

## 技术栈总览

本 Phase 涉及的技术栈：

| 组件 | 技术选择 | 原因 |
|------|---------|------|
| 数据模型 | ✅ 纯 Swift | 平台无关，简单高效 |
| 视图模型 | ✅ @MainActor + ObservableObject | 确保主线程安全 |
| UI 视图 | ✅ SwiftUI | 现代 UI，易维护 |
| 窗口容器 | ✅ NSPanel (AppKit) | 需要浮动层级控制 |
| 拖拽接收 | ✅ NSDraggingDestination | 精确控制拖拽 |
| 拖拽源 | ✅ SwiftUI .onDrag | 简单易用 |

**禁止使用**：
- ❌ NSWindow（用 NSPanel）
- ❌ SwiftUI Window（用 NSPanel）
- ❌ MenuBarExtra（Phase 3 用 NSStatusItem）

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
- 编译失败时：先看错误信息，只修复编译错误

**Axiom Skill**（Swift/SwiftUI 专家）：
- ✅ 遇到编译错误时使用
- ✅ 写复杂 SwiftUI 代码前使用
- ✅ 写 AppKit 集成代码前使用
- 使用方式：`/using-axiom [问题]`

---

## 步骤详解

---

### 1.1 首次提交（项目初始化）

**技术栈**：
- ✅ Git 版本控制
- ❌ 不涉及代码编写

**工具使用**：
- 📝 Git 命令行
- ❌ 不需要编译

**任务**：提交当前已暂存的文件

**操作步骤**：

```bash
cd "/Users/chenhuajin/Desktop/Dropkit v2 /DropKit"
git status  # 确认暂存文件
git commit -m "$(cat <<'COMMIT_EOF'
chore: initial project setup

- Xcode project structure
- Basic directory layout (App, Features, Services, Models, Utilities)
- Basic app files (DropKitApp, AppDelegate, AppState)
- Git configuration

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
COMMIT_EOF
)"
```

**验证**：
- `git log` 能看到第一个 commit
- `git status` 显示工作区干净

---

### 1.2 创建 ShelfItem 数据模型

**技术栈**：
- ✅ 纯 Swift 数据模型
- ✅ 使用 Identifiable 协议（SwiftUI 要求）
- ✅ 使用 Equatable 协议（列表比较）
- ❌ 不涉及 UI，不使用 SwiftUI 视图

**工具使用**：
- 📝 编辑器：直接编写代码
- 🔨 编译：使用 XcodeBuildMCP
- ❓ 遇到问题：使用 Axiom skill

**文件**：`Sources/Features/Shelf/ShelfItem.swift`

**代码结构**：

```swift
import Foundation
import AppKit

/// 悬浮窗中的单个项目
struct ShelfItem: Identifiable, Equatable {
    let id: UUID
    let url: URL
    let name: String
    let type: ItemType
    let addedAt: Date
    var thumbnail: NSImage?

    enum ItemType: String, Codable {
        case file       // 普通文件
        case folder     // 文件夹
        case image      // 图片文件
        case text       // 文本内容
        case url        // 网址
    }

    init(url: URL) {
        self.id = UUID()
        self.url = url
        self.name = url.lastPathComponent
        self.addedAt = Date()

        // 判断类型
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) {
            if isDirectory.boolValue {
                self.type = .folder
            } else if url.isImageFile {
                self.type = .image
            } else {
                self.type = .file
            }
        } else {
            self.type = .file
        }

        self.thumbnail = nil
    }

    static func == (lhs: ShelfItem, rhs: ShelfItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - URL Extension
extension URL {
    var isImageFile: Bool {
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic", "webp"]
        return imageExtensions.contains(self.pathExtension.lowercased())
    }
}
```

**详细说明**：

1. **属性设计**：
   - `id`: UUID，用于 SwiftUI 的 Identifiable
   - `url`: 文件的完整路径
   - `name`: 文件名（从 URL 提取）
   - `type`: 文件类型枚举
   - `addedAt`: 添加时间
   - `thumbnail`: 缩略图（可选，Phase 4 实现）

2. **类型判断逻辑**：
   - 使用 `FileManager.fileExists` 判断是否为文件夹
   - 通过扩展名判断是否为图片
   - 默认为普通文件

3. **Equatable 实现**：
   - 只比较 id，确保唯一性

**测试要点**：
- 创建文件 URL，验证类型判断正确
- 创建文件夹 URL，验证类型为 folder
- 创建图片 URL，验证类型为 image

**编译**：
使用 mcp__xcodebuildmcp__build 工具编译项目

**提交**：
```bash
git add Sources/Features/Shelf/ShelfItem.swift
git commit -m "feat: add ShelfItem data model"
```

---

### 1.3 创建 ShelfViewModel

**技术栈**：
- ✅ @MainActor（确保主线程执行）
- ✅ ObservableObject（SwiftUI 状态管理）
- ✅ @Published（自动触发 UI 更新）
- ❌ 不涉及 UI 视图

**工具使用**：
- 📝 编辑器：直接编写代码
- 🔨 编译：使用 XcodeBuildMCP
- ❓ 遇到问题：使用 Axiom skill

**文件**：`Sources/Features/Shelf/ShelfViewModel.swift`

**代码结构**：

```swift
import Foundation
import Combine

/// 悬浮窗的视图模型
@MainActor
class ShelfViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var items: [ShelfItem] = []
    @Published var isVisible: Bool = false

    // MARK: - Constants

    private let maxItems = 20  // 最多存储 20 个项目

    // MARK: - Initialization

    init() {
        print("ShelfViewModel initialized")
    }

    // MARK: - Public Methods

    /// 添加文件到悬浮窗
    func addItems(urls: [URL]) {
        let newItems = urls.map { ShelfItem(url: $0) }

        // 添加到列表开头
        items.insert(contentsOf: newItems, at: 0)

        // 限制最大数量
        if items.count > maxItems {
            items = Array(items.prefix(maxItems))
        }

        print("Added \(newItems.count) items, total: \(items.count)")
    }

    /// 移除指定项目
    func removeItem(_ item: ShelfItem) {
        items.removeAll { $0.id == item.id }
        print("Removed item: \(item.name)")
    }

    /// 清空所有项目
    func clearAll() {
        items.removeAll()
        print("Cleared all items")
    }

    /// 获取项目的拖拽数据
    func getDraggingItem(for item: ShelfItem) -> NSItemProvider {
        return NSItemProvider(object: item.url as NSURL)
    }
}
```

**详细说明**：

1. **@MainActor 标记**：
   - 确保所有操作在主线程执行
   - 避免 UI 更新的线程问题

2. **Published 属性**：
   - `items`: 存储的项目列表
   - `isVisible`: 悬浮窗是否可见（Phase 2 使用）

3. **核心方法**：
   - `addItems`: 添加文件，插入到列表开头，限制最大数量
   - `removeItem`: 移除单个项目
   - `clearAll`: 清空所有项目
   - `getDraggingItem`: 为拖出操作提供数据

4. **数量限制**：
   - 最多 20 个项目，防止内存占用过大

**测试要点**：
- 添加文件，验证列表更新
- 添加超过 20 个文件，验证自动截断
- 移除文件，验证列表正确更新

**编译**：
使用 mcp__xcodebuildmcp__build 工具编译项目

**提交**：
```bash
git add Sources/Features/Shelf/ShelfViewModel.swift
git commit -m "feat: add ShelfViewModel"
```

---

### 1.4 创建 ShelfView（SwiftUI 视图）

**技术栈**：
- ✅ SwiftUI（UI 层）
- ✅ ZStack（叠加布局）
- ✅ LazyVGrid（网格布局）
- ✅ .regularMaterial（毛玻璃效果）
- ❌ 不使用 NSView

**工具使用**：
- 📝 编辑器：编写 SwiftUI 代码
- 🔨 编译：使用 XcodeBuildMCP
- ❓ 复杂布局前：使用 Axiom skill 查询最佳实践

**文件**：`Sources/Features/Shelf/ShelfView.swift`

**代码结构**：

```swift
import SwiftUI

/// 悬浮窗的 SwiftUI 视图
struct ShelfView: View {
    @ObservedObject var viewModel: ShelfViewModel

    var body: some View {
        ZStack {
            // 背景
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)

            // 内容
            if viewModel.items.isEmpty {
                emptyStateView
            } else {
                itemsGridView
            }
        }
        .frame(width: 400, height: 300)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray.and.arrow.down")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("拖入文件到这里")
                .font(.headline)
                .foregroundColor(.primary)

            Text("支持文件、文件夹、图片等")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Items Grid

    private var itemsGridView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 80, maximum: 100), spacing: 16)
            ], spacing: 16) {
                ForEach(viewModel.items) { item in
                    ShelfItemView(item: item, viewModel: viewModel)
                }
            }
            .padding(16)
        }
    }
}

// MARK: - Preview

#Preview {
    ShelfView(viewModel: ShelfViewModel())
}
```

**详细说明**：

1. **布局结构**：
   - 使用 ZStack 叠加背景和内容
   - 背景：圆角矩形 + 毛玻璃效果 + 阴影
   - 内容：根据是否有项目显示不同视图

2. **空状态视图**：
   - 图标：系统 SF Symbol `tray.and.arrow.down`
   - 主文案：提示拖入文件
   - 副文案：说明支持的类型

3. **项目网格视图**：
   - 使用 `LazyVGrid` 自适应布局
   - 每个项目宽度 80-100pt
   - 间距 16pt
   - 可滚动

4. **尺寸**：
   - 固定宽度 400pt
   - 固定高度 300pt
   - Phase 4 可改为动态尺寸

**测试要点**：
- 空状态显示正确
- 添加项目后显示网格
- 网格布局自适应

**编译**：
使用 mcp__xcodebuildmcp__build 工具编译项目

**提交**：
```bash
git add Sources/Features/Shelf/ShelfView.swift
git commit -m "feat: add ShelfView UI"
```

---

### 1.5 创建 ShelfItemView（单个项目视图）

**技术栈**：
- ✅ SwiftUI（UI 层）
- ✅ VStack（垂直布局）
- ✅ .onHover（悬停效果）
- ✅ .contextMenu（右键菜单）
- ❌ 不使用 NSView

**工具使用**：
- 📝 编辑器：编写 SwiftUI 代码
- 🔨 编译：使用 XcodeBuildMCP
- ❓ 遇到问题：使用 Axiom skill

**文件**：`Sources/Features/Shelf/ShelfItemView.swift`

**代码结构**：

```swift
import SwiftUI

/// 单个项目的视图
struct ShelfItemView: View {
    let item: ShelfItem
    @ObservedObject var viewModel: ShelfViewModel
    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 8) {
            // 图标或缩略图
            iconView
                .frame(width: 64, height: 64)

            // 文件名
            Text(item.name)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
        }
        .frame(width: 80, height: 100)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color.accentColor.opacity(0.1) : Color.clear)
        )
        .onHover { hovering in
            isHovered = hovering
        }
        .contextMenu {
            Button("在 Finder 中显示") {
                NSWorkspace.shared.selectFile(item.url.path, inFileViewerRootedAtPath: "")
            }

            Button("移除", role: .destructive) {
                viewModel.removeItem(item)
            }
        }
        // Phase 1: 暂时不实现拖出功能，Phase 1.7 实现
    }

    // MARK: - Icon View

    @ViewBuilder
    private var iconView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.1))

            Image(systemName: iconName)
                .font(.system(size: 32))
                .foregroundColor(.accentColor)
        }
    }

    private var iconName: String {
        switch item.type {
        case .file:
            return "doc"
        case .folder:
            return "folder"
        case .image:
            return "photo"
        case .text:
            return "doc.text"
        case .url:
            return "link"
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel = ShelfViewModel()
    let item = ShelfItem(url: URL(fileURLWithPath: "/Users/test/document.pdf"))

    return ShelfItemView(item: item, viewModel: viewModel)
        .padding()
}
```

**详细说明**：

1. **布局结构**：
   - VStack：图标 + 文件名
   - 固定尺寸：80x100pt
   - 悬停效果：背景高亮

2. **图标显示**：
   - Phase 1：使用 SF Symbol 图标
   - Phase 4：替换为真实缩略图
   - 根据文件类型显示不同图标

3. **交互功能**：
   - 悬停高亮
   - 右键菜单：在 Finder 显示、移除

4. **拖出功能**：
   - Phase 1 暂不实现
   - Phase 1.7 添加

**测试要点**：
- 不同类型文件显示不同图标
- 悬停效果正常
- 右键菜单功能正常

**编译**：
使用 mcp__xcodebuildmcp__build 工具编译项目

**提交**：
```bash
git add Sources/Features/Shelf/ShelfItemView.swift
git commit -m "feat: add ShelfItemView"
```

---

### 1.6 创建 ShelfPanel（NSPanel 窗口容器）

**技术栈**：
- ✅ NSPanel (AppKit)
- ✅ NSHostingView（SwiftUI 集成）
- ✅ NSDraggingDestination（拖拽接收）
- ❌ 不使用 NSWindow
- ❌ 不使用 SwiftUI Window

**工具使用**：
- 📝 编辑器：编写 AppKit 代码
- 🔨 编译：使用 XcodeBuildMCP
- ❓ AppKit 集成前：使用 Axiom skill 查询 NSPanel 用法

**文件**：`Sources/Features/Shelf/ShelfPanel.swift`

**代码结构**：

```swift
import AppKit
import SwiftUI

/// 悬浮窗的 NSPanel 容器
class ShelfPanel: NSPanel {
    private let viewModel: ShelfViewModel
    private var hostingView: NSHostingView<ShelfView>?

    // MARK: - Initialization

    init(viewModel: ShelfViewModel) {
        self.viewModel = viewModel

        // 初始化窗口
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        setupWindow()
        setupContent()
        setupDragAndDrop()
    }

    // MARK: - Setup

    private func setupWindow() {
        // 窗口层级：浮在所有窗口之上
        self.level = .floating

        // 窗口行为
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // 外观
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true

        // 交互
        self.isMovableByWindowBackground = true

        // 初始隐藏
        self.orderOut(nil)

        print("ShelfPanel initialized")
    }

    private func setupContent() {
        // 创建 SwiftUI 视图
        let shelfView = ShelfView(viewModel: viewModel)
        let hostingView = NSHostingView(rootView: shelfView)

        // 设置为内容视图
        self.contentView = hostingView
        self.hostingView = hostingView

        print("ShelfPanel content view set")
    }

    private func setupDragAndDrop() {
        // 注册接收的拖拽类型
        guard let contentView = self.contentView else { return }

        contentView.registerForDraggedTypes([
            .fileURL,
            .URL,
            .string
        ])

        print("ShelfPanel drag types registered")
    }

    // MARK: - Public Methods

    /// 在指定位置显示悬浮窗
    func show(at position: NSPoint? = nil) {
        if let position = position {
            // 在指定位置显示
            self.setFrameOrigin(position)
        } else {
            // 在鼠标位置显示
            let mouseLocation = NSEvent.mouseLocation
            let origin = NSPoint(
                x: mouseLocation.x - self.frame.width / 2,
                y: mouseLocation.y - self.frame.height / 2
            )
            self.setFrameOrigin(origin)
        }

        self.orderFront(nil)
        viewModel.isVisible = true

        print("ShelfPanel shown at: \(self.frame.origin)")
    }

    /// 隐藏悬浮窗
    func hide() {
        self.orderOut(nil)
        viewModel.isVisible = false

        print("ShelfPanel hidden")
    }

    /// 切换显示/隐藏
    func toggle() {
        if self.isVisible {
            hide()
        } else {
            show()
        }
    }
}

// MARK: - NSDraggingDestination

extension ShelfPanel {
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        // 检查是否有文件 URL
        if sender.draggingPasteboard.canReadObject(forClasses: [NSURL.self], options: nil) {
            return .copy
        }
        return []
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let pasteboard = sender.draggingPasteboard

        // 读取文件 URL
        guard let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] else {
            print("No valid URLs in drag operation")
            return false
        }

        // 添加到 ViewModel
        Task { @MainActor in
            viewModel.addItems(urls: urls)
        }

        print("Drag operation performed: \(urls.count) items")
        return true
    }
}
```

**详细说明**：

1. **窗口初始化**：
   - 尺寸：400x300
   - 样式：无边框、非激活面板
   - 缓冲：buffered（性能优化）

2. **窗口属性设置**：
   - `level = .floating`：浮在所有窗口之上
   - `collectionBehavior`：可以在所有空间显示、全屏辅助
   - `isOpaque = false`：透明背景
   - `backgroundColor = .clear`：清除背景色
   - `isMovableByWindowBackground = true`：可拖动

3. **SwiftUI 集成**：
   - 使用 `NSHostingView` 包装 SwiftUI 视图
   - 设置为 contentView

4. **拖拽接收**：
   - 注册类型：fileURL、URL、string
   - `draggingEntered`：返回 .copy 表示接受拖拽
   - `performDragOperation`：读取 URL 并添加到 ViewModel

5. **显示逻辑**：
   - 可指定位置显示
   - 默认在鼠标位置居中显示
   - 更新 ViewModel 的 isVisible 状态

**测试要点**：
- 窗口能正确显示
- 窗口浮在其他窗口之上
- 拖入文件能正确接收
- 窗口可拖动

**编译**：
使用 mcp__xcodebuildmcp__build 工具编译项目

**提交**：
```bash
git add Sources/Features/Shelf/ShelfPanel.swift
git commit -m "feat: add ShelfPanel with drag-in support"
```

---

### 1.7 添加拖出功能

**技术栈**：
- ✅ SwiftUI .onDrag 修饰符
- ✅ NSItemProvider（拖拽数据提供）
- ❌ 不使用 NSDraggingSource（SwiftUI 已封装）

**工具使用**：
- 📝 编辑器：修改 ShelfItemView.swift
- 🔨 编译：使用 XcodeBuildMCP

**修改文件**：`Sources/Features/Shelf/ShelfItemView.swift`

在 body 的 `.contextMenu` 之后添加 `.onDrag` 修饰符：

```swift
.onDrag {
    viewModel.getDraggingItem(for: item)
}
```

**完整的 body 应该是**：

```swift
var body: some View {
    VStack(spacing: 8) {
        // 图标或缩略图
        iconView
            .frame(width: 64, height: 64)

        // 文件名
        Text(item.name)
            .font(.caption)
            .lineLimit(2)
            .multilineTextAlignment(.center)
            .foregroundColor(.primary)
    }
    .frame(width: 80, height: 100)
    .background(
        RoundedRectangle(cornerRadius: 8)
            .fill(isHovered ? Color.accentColor.opacity(0.1) : Color.clear)
    )
    .onHover { hovering in
        isHovered = hovering
    }
    .contextMenu {
        Button("在 Finder 中显示") {
            NSWorkspace.shared.selectFile(item.url.path, inFileViewerRootedAtPath: "")
        }

        Button("移除", role: .destructive) {
            viewModel.removeItem(item)
        }
    }
    .onDrag {
        viewModel.getDraggingItem(for: item)
    }
}
```

**编译**：
使用 mcp__xcodebuildmcp__build 工具编译项目

**提交**：
```bash
git add Sources/Features/Shelf/ShelfItemView.swift
git commit -m "feat: add drag-out support for shelf items"
```

---

### 1.8 集成到 AppDelegate

**技术栈**：
- ✅ AppKit AppDelegate
- ✅ NSApplicationDelegate 协议
- ❌ 不涉及 SwiftUI App

**工具使用**：
- 📝 编辑器：修改 AppDelegate.swift
- 🔨 编译：使用 XcodeBuildMCP

**修改文件**：`Sources/App/AppDelegate.swift`

```swift
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var shelfPanel: ShelfPanel?
    private var shelfViewModel: ShelfViewModel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("DropKit launched")
        setupShelf()
        
        // Phase 1 测试：启动时显示悬浮窗
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.shelfPanel?.show()
        }
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
}
```

**详细说明**：

1. **初始化流程**：
   - 创建 ShelfViewModel
   - 创建 ShelfPanel 并传入 ViewModel
   - 保持强引用

2. **测试代码**：
   - 启动后 0.5 秒自动显示悬浮窗
   - 方便测试功能
   - Phase 2 会移除，改为摇晃触发

3. **重新打开处理**：
   - Dock 图标点击时显示悬浮窗

**编译**：
使用 mcp__xcodebuildmcp__build 工具编译项目

**提交**：
```bash
git add Sources/App/AppDelegate.swift
git commit -m "feat: integrate ShelfPanel into AppDelegate"
```

---

### 1.9 Phase 1 测试清单

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
| 1 | 悬浮窗显示 | 启动应用 | 悬浮窗自动显示 | ⬜ |
| 2 | 窗口层级 | 打开其他窗口 | 悬浮窗在最上层 | ⬜ |
| 3 | 窗口拖动 | 拖动窗口背景 | 窗口可移动 | ⬜ |
| 4 | 空状态显示 | 查看初始状态 | 显示提示文案 | ⬜ |
| 5 | 拖入单文件 | 拖入一个文件 | 文件显示在网格 | ⬜ |
| 6 | 拖入多文件 | 拖入多个文件 | 所有文件显示 | ⬜ |
| 7 | 拖入文件夹 | 拖入文件夹 | 显示文件夹图标 | ⬜ |
| 8 | 拖入图片 | 拖入图片文件 | 显示图片图标 | ⬜ |
| 9 | 悬停效果 | 鼠标悬停项目 | 背景高亮 | ⬜ |
| 10 | 右键菜单 | 右键点击项目 | 显示菜单 | ⬜ |
| 11 | Finder显示 | 点击菜单项 | Finder打开文件 | ⬜ |
| 12 | 移除项目 | 点击移除 | 项目消失 | ⬜ |
| 13 | 拖出到Finder | 拖项目到Finder | 文件复制成功 | ⬜ |
| 14 | 拖出到应用 | 拖到其他应用 | 应用接收文件 | ⬜ |
| 15 | 数量限制 | 拖入>20个文件 | 只保留20个 | ⬜ |
| 16 | 网格布局 | 添加多个文件 | 自动换行 | ⬜ |
| 17 | 滚动功能 | 添加大量文件 | 可滚动查看 | ⬜ |

**测试说明**：
- 所有测试项必须通过才能进入 Phase 2
- 发现问题立即修复，不要累积
- 每修复一个问题，重新编译测试

---

### 1.10 Phase 1 完成提交

**技术栈**：
- ✅ Git 版本控制
- ❌ 不涉及代码编写

**工具使用**：
- 📝 Git 命令行
- ✅ 使用 build-macos-apps skill 完整验证

**提交命令**：

```bash
git add -A
git commit -m "feat: Phase 1 complete - basic shelf drag in/out

Phase 1 MVP 完成：
- ShelfItem 数据模型
- ShelfViewModel 状态管理
- ShelfView SwiftUI 视图
- ShelfItemView 项目视图
- ShelfPanel NSPanel 容器
- 拖入拖出功能
- 右键菜单
- 数量限制

测试状态：全部通过

下一步：Phase 2 - 摇晃触发

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

**Phase 完成验证**：

使用 build-macos-apps skill 进行完整构建验证：
```
/using-build-macos-apps
```

这将：
- 完整构建项目
- 运行所有测试
- 检查性能
- 生成报告

---

## Phase 1 总结

### 已完成功能

✅ **数据层**：
- ShelfItem 数据模型（支持文件、文件夹、图片类型判断）
- ShelfViewModel 状态管理（添加、移除、清空、数量限制）

✅ **UI 层**：
- ShelfView 主视图（空状态、网格布局、毛玻璃效果）
- ShelfItemView 项目视图（图标、文件名、悬停、右键菜单）

✅ **窗口层**：
- ShelfPanel NSPanel 容器（浮动层级、拖拽接收、SwiftUI 集成）

✅ **交互功能**：
- 拖入文件到悬浮窗
- 从悬浮窗拖出文件
- 右键菜单（Finder 显示、移除）
- 窗口拖动

✅ **限制与优化**：
- 最多 20 个项目
- 自动截断超出项目

### 技术亮点

1. **SwiftUI + AppKit 混合架构**：
   - UI 用 SwiftUI（易维护）
   - 窗口用 NSPanel（精确控制）
   - NSHostingView 桥接

2. **@MainActor 线程安全**：
   - 确保 UI 操作在主线程
   - 避免并发问题

3. **拖拽双向支持**：
   - 拖入：NSDraggingDestination
   - 拖出：SwiftUI .onDrag

### 已知限制

❌ **暂未实现**（后续 Phase 完成）：
- 摇晃触发（Phase 2）
- 菜单栏（Phase 3）
- 缩略图（Phase 4）
- 动画效果（Phase 4）
- 剪切板历史（Phase 5）
- 设置页（Phase 6）

❌ **测试代码**：
- AppDelegate 中的自动显示代码（Phase 2 移除）

### 下一步：Phase 2

**目标**：实现摇晃触发功能

**核心任务**：
1. DragMonitor（拖拽状态检测）
2. ShakeDetector（摇晃检测）
3. PermissionChecker（辅助功能权限）
4. PermissionGuideView（权限引导界面）
5. 集成摇晃触发逻辑

**文档**：`phase-2-shake-trigger.md`

---

## 附录：常见问题

### Q1: 编译失败怎么办？

1. 查看完整错误信息
2. 使用 Axiom skill 查询解决方案
3. 只修复编译错误，不改其他代码
4. 修复后重新编译

### Q2: 拖入文件不工作？

检查：
1. `registerForDraggedTypes` 是否调用
2. `draggingEntered` 是否返回 `.copy`
3. `performDragOperation` 是否正确读取 URL

### Q3: 窗口不显示？

检查：
1. `orderFront(nil)` 是否调用
2. `level` 是否设置为 `.floating`
3. `frame` 是否在屏幕内

### Q4: 拖出文件不工作？

检查：
1. `.onDrag` 修饰符是否添加
2. `getDraggingItem` 是否返回正确的 NSItemProvider

---

**Phase 1 完成！🎉**

准备好进入 Phase 2 了吗？打开 `phase-2-shake-trigger.md` 继续开发。

