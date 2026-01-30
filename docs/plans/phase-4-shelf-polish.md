# Phase 4: 悬浮窗完善

> 创建日期：2026-01-29
> 状态：待开发

---

## Phase 概述

**目标**：美化悬浮窗，添加缩略图、动画、多文件优化

**预计时间**：第 7-9 天

**成功标准**：
- ✅ 图片文件显示真实缩略图
- ✅ 添加/移除动画流畅
- ✅ 支持多文件批量操作
- ✅ UI 美化完成

---

## 技术栈总览

本 Phase 涉及的技术栈：

| 组件 | 技术选择 | 原因 |
|------|---------|------|
| 缩略图生成 | ✅ QuickLook API | 系统级缩略图支持 |
| 异步处理 | ✅ async/await + Task | 避免阻塞主线程 |
| 动画 | ✅ SwiftUI Animation | 流畅的过渡效果 |
| 图片处理 | ✅ NSImage | 标准图片 API |

**关键技术**：
- ✅ QLThumbnailGenerator（QuickLook 缩略图）
- ✅ Task.detached（后台线程）
- ✅ @MainActor（主线程更新）
- ✅ .transition + .animation（SwiftUI 动画）

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
- ✅ 写复杂动画前使用
- ✅ 写异步代码前使用
- 使用方式：`/using-axiom [问题]`

---

## 步骤详解

---

### 4.1 创建缩略图生成器

**技术栈**：
- ✅ QuickLook API（QLThumbnailGenerator）
- ✅ async/await（异步处理）
- ✅ Task.detached（后台线程）
- ❌ 不涉及 UI

**工具使用**：
- 📝 编辑器：编写异步代码
- 🔨 编译：使用 XcodeBuildMCP
- ❓ 异步代码前：使用 Axiom skill

**文件**：`Sources/Utilities/ThumbnailGenerator.swift`

**代码结构**：

```swift
import AppKit
import QuickLook

/// 缩略图生成器
class ThumbnailGenerator {

    /// 生成文件缩略图
    static func generate(for url: URL, size: CGSize = CGSize(width: 128, height: 128)) async -> NSImage? {
        // 检查文件是否存在
        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }

        // 判断文件类型
        if url.isImageFile {
            return await generateImageThumbnail(for: url, size: size)
        } else {
            return await generateQuickLookThumbnail(for: url, size: size)
        }
    }

    /// 生成图片缩略图（直接加载）
    private static func generateImageThumbnail(for url: URL, size: CGSize) async -> NSImage? {
        return await Task.detached {
            guard let image = NSImage(contentsOf: url) else {
                return nil
            }

            // 调整大小
            let thumbnail = NSImage(size: size)
            thumbnail.lockFocus()

            let targetRect = NSRect(origin: .zero, size: size)
            image.draw(in: targetRect, from: .zero, operation: .copy, fraction: 1.0)

            thumbnail.unlockFocus()
            return thumbnail
        }.value
    }

    /// 生成 QuickLook 缩略图（其他文件类型）
    private static func generateQuickLookThumbnail(for url: URL, size: CGSize) async -> NSImage? {
        return await withCheckedContinuation { continuation in
            let request = QLThumbnailGenerator.Request(
                fileAt: url,
                size: size,
                scale: NSScreen.main?.backingScaleFactor ?? 2.0,
                representationTypes: .thumbnail
            )

            QLThumbnailGenerator.shared.generateRepresentations(for: request) { thumbnail, type, error in
                if let thumbnail = thumbnail {
                    continuation.resume(returning: thumbnail.nsImage)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
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

1. **异步生成**：
   - 使用 `async/await` 避免阻塞主线程
   - 图片文件：直接加载并缩放
   - 其他文件：使用 QuickLook API

2. **QuickLook API**：
   - `QLThumbnailGenerator` 系统缩略图生成器
   - 支持 PDF、视频、文档等多种格式
   - 自动适配 Retina 屏幕

3. **性能优化**：
   - 使用 `Task.detached` 在后台线程处理
   - 缩略图尺寸固定为 128x128

**测试要点**：
- 图片文件生成缩略图
- PDF 文件生成缩略图
- 视频文件生成缩略图
- 不存在的文件返回 nil

**编译**：
使用 mcp__xcodebuildmcp__build 工具编译项目

**提交**：
```bash
git add Sources/Utilities/ThumbnailGenerator.swift
git commit -m "feat: add ThumbnailGenerator"
```

---

### 4.2 更新 ShelfViewModel 支持缩略图

**技术栈**：
- ✅ async/await（异步处理）
- ✅ @MainActor（主线程更新）
- ✅ Task（启动异步任务）
- ❌ 不涉及 UI

**工具使用**：
- 📝 编辑器：修改 ShelfViewModel.swift
- 🔨 编译：使用 XcodeBuildMCP

**修改文件**：`Sources/Features/Shelf/ShelfViewModel.swift`

**修改 `addItems` 方法**：

```swift
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

    // 异步生成缩略图
    Task {
        await generateThumbnails(for: newItems)
    }
}

/// 生成缩略图
private func generateThumbnails(for items: [ShelfItem]) async {
    for item in items {
        if let thumbnail = await ThumbnailGenerator.generate(for: item.url) {
            await MainActor.run {
                if let index = self.items.firstIndex(where: { $0.id == item.id }) {
                    self.items[index].thumbnail = thumbnail
                }
            }
        }
    }
}
```

**详细说明**：

1. **异步流程**：
   - 添加文件后立即显示（使用默认图标）
   - 后台异步生成缩略图
   - 生成完成后更新 UI

2. **线程安全**：
   - 使用 @MainActor.run 确保 UI 更新在主线程
   - 避免并发问题

**编译**：
使用 mcp__xcodebuildmcp__build 工具编译项目

**提交**：
```bash
git add Sources/Features/Shelf/ShelfViewModel.swift
git commit -m "feat: add thumbnail generation to ShelfViewModel"
```

---

### 4.3 更新 ShelfItem 支持缩略图

**技术栈**：
- ✅ 纯 Swift 数据模型
- ✅ var 属性（可变）
- ❌ 不涉及 UI

**工具使用**：
- 📝 编辑器：修改 ShelfItem.swift
- 🔨 编译：使用 XcodeBuildMCP

**修改文件**：`Sources/Features/Shelf/ShelfItem.swift`

**修改 `ShelfItem` 结构体**：

```swift
struct ShelfItem: Identifiable, Equatable {
    let id: UUID
    let url: URL
    let name: String
    let type: ItemType
    let addedAt: Date
    var thumbnail: NSImage?  // 改为 var，支持后续更新

    // ... 其他代码保持不变

    static func == (lhs: ShelfItem, rhs: ShelfItem) -> Bool {
        lhs.id == rhs.id
    }

    // 添加 mutating 方法更新缩略图
    mutating func updateThumbnail(_ image: NSImage) {
        self.thumbnail = image
    }
}
```

**详细说明**：

1. **可变属性**：
   - thumbnail 改为 var
   - 支持后续更新

2. **Equatable**：
   - 只比较 id
   - 缩略图变化不影响相等性判断

**编译**：
使用 mcp__xcodebuildmcp__build 工具编译项目

**提交**：
```bash
git add Sources/Features/Shelf/ShelfItem.swift
git commit -m "refactor: make ShelfItem.thumbnail mutable"
```

---

### 4.4 更新 ShelfItemView 显示缩略图

**技术栈**：
- ✅ SwiftUI（UI 层）
- ✅ Image(nsImage:)（显示 NSImage）
- ✅ @ViewBuilder（条件视图）
- ❌ 不使用 NSView

**工具使用**：
- 📝 编辑器：修改 ShelfItemView.swift
- 🔨 编译：使用 XcodeBuildMCP

**修改文件**：`Sources/Features/Shelf/ShelfItemView.swift`

**修改 `iconView` 属性**：

```swift
@ViewBuilder
private var iconView: some View {
    ZStack {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.secondary.opacity(0.1))

        if let thumbnail = item.thumbnail {
            // 显示真实缩略图
            Image(nsImage: thumbnail)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            // 显示默认图标
            Image(systemName: iconName)
                .font(.system(size: 32))
                .foregroundColor(.accentColor)
        }
    }
}
```

**详细说明**：

1. **条件显示**：
   - 有缩略图：显示真实缩略图
   - 无缩略图：显示默认图标
   - 自动切换，无需手动刷新

2. **图片处理**：
   - .resizable()：允许调整大小
   - .aspectRatio(contentMode: .fill)：填充模式
   - .clipShape()：裁剪为圆角矩形

**编译**：
使用 mcp__xcodebuildmcp__build 工具编译项目

**提交**：
```bash
git add Sources/Features/Shelf/ShelfItemView.swift
git commit -m "feat: display real thumbnails in ShelfItemView"
```

---

### 4.5 添加动画效果

**技术栈**：
- ✅ SwiftUI Animation
- ✅ .transition（过渡动画）
- ✅ .spring（弹簧动画）
- ❌ 不使用 Core Animation

**工具使用**：
- 📝 编辑器：修改 ShelfView.swift
- 🔨 编译：使用 XcodeBuildMCP
- ❓ 复杂动画前：使用 Axiom skill

**修改文件**：`Sources/Features/Shelf/ShelfView.swift`

**修改 `itemsGridView`**：

```swift
private var itemsGridView: some View {
    ScrollView {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 80, maximum: 100), spacing: 16)
        ], spacing: 16) {
            ForEach(viewModel.items) { item in
                ShelfItemView(item: item, viewModel: viewModel)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(16)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.items.count)
    }
}
```

**详细说明**：

1. **过渡动画**：
   - .scale：缩放效果
   - .opacity：透明度变化
   - .combined：组合两种效果

2. **弹簧动画**：
   - response: 0.3（响应时间）
   - dampingFraction: 0.7（阻尼系数）
   - 更自然的动画效果

3. **触发条件**：
   - value: viewModel.items.count
   - 项目数量变化时触发动画

**编译**：
使用 mcp__xcodebuildmcp__build 工具编译项目

**提交**：
```bash
git add Sources/Features/Shelf/ShelfView.swift
git commit -m "feat: add animations to shelf items"
```

---

### 4.6 优化 ShelfItemView 交互

**技术栈**：
- ✅ SwiftUI（UI 层）
- ✅ .onHover（悬停检测）
- ✅ .scaleEffect（缩放效果）
- ✅ withAnimation（动画包装）
- ❌ 不使用 NSView

**工具使用**：
- 📝 编辑器：修改 ShelfItemView.swift
- 🔨 编译：使用 XcodeBuildMCP

**修改文件**：`Sources/Features/Shelf/ShelfItemView.swift`

**完整代码**：

```swift
import SwiftUI

/// 单个项目的视图
struct ShelfItemView: View {
    let item: ShelfItem
    @ObservedObject var viewModel: ShelfViewModel
    @State private var isHovered = false
    @State private var isDragging = false

    var body: some View {
        VStack(spacing: 8) {
            // 图标或缩略图
            iconView
                .frame(width: 64, height: 64)
                .scaleEffect(isDragging ? 0.9 : 1.0)
                .opacity(isDragging ? 0.5 : 1.0)

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
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isHovered ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 2)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .contextMenu {
            Button("在 Finder 中显示") {
                NSWorkspace.shared.selectFile(item.url.path, inFileViewerRootedAtPath: "")
            }

            Button("拷贝路径") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(item.url.path, forType: .string)
            }

            Divider()

            Button("移除", role: .destructive) {
                withAnimation {
                    viewModel.removeItem(item)
                }
            }
        }
        .onDrag {
            isDragging = true
            return viewModel.getDraggingItem(for: item)
        }
    }

    // MARK: - Icon View

    @ViewBuilder
    private var iconView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.1))

            if let thumbnail = item.thumbnail {
                Image(nsImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Image(systemName: iconName)
                    .font(.system(size: 32))
                    .foregroundColor(.accentColor)
            }
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
```

**详细说明**：

1. **悬停效果**：
   - 背景高亮
   - 边框显示
   - 带动画过渡

2. **拖拽反馈**：
   - 拖拽时缩小
   - 拖拽时半透明
   - 视觉反馈清晰

3. **右键菜单增强**：
   - 在 Finder 中显示
   - 拷贝路径（新增）
   - 移除（带动画）

**编译**：
使用 mcp__xcodebuildmcp__build 工具编译项目

**提交**：
```bash
git add Sources/Features/Shelf/ShelfItemView.swift
git commit -m "feat: enhance ShelfItemView interactions"
```

---

### 4.7 Phase 4 测试清单

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
| 1 | 图片缩略图 | 拖入图片文件 | 显示真实缩略图 | ⬜ |
| 2 | PDF 缩略图 | 拖入 PDF 文件 | 显示 PDF 预览 | ⬜ |
| 3 | 视频缩略图 | 拖入视频文件 | 显示视频帧 | ⬜ |
| 4 | 文档缩略图 | 拖入文档文件 | 显示文档预览 | ⬜ |
| 5 | 默认图标 | 拖入未知类型 | 显示默认图标 | ⬜ |
| 6 | 添加动画 | 拖入文件 | 缩放+淡入动画 | ⬜ |
| 7 | 移除动画 | 移除文件 | 缩放+淡出动画 | ⬜ |
| 8 | 悬停效果 | 鼠标悬停 | 背景高亮+边框 | ⬜ |
| 9 | 拖拽反馈 | 拖拽项目 | 缩小+半透明 | ⬜ |
| 10 | 拷贝路径 | 右键→拷贝路径 | 路径复制到剪切板 | ⬜ |
| 11 | 异步加载 | 拖入大图片 | 先显示图标后显示缩略图 | ⬜ |
| 12 | 多文件 | 同时拖入多个文件 | 所有文件都生成缩略图 | ⬜ |
| 13 | 动画流畅 | 快速添加/移除 | 动画不卡顿 | ⬜ |
| 14 | 边框动画 | 悬停进出 | 边框平滑过渡 | ⬜ |
| 15 | Retina 支持 | 在 Retina 屏幕查看 | 缩略图清晰 | ⬜ |

**性能测试**：

| # | 测试项 | 操作步骤 | 预期结果 | 状态 |
|---|--------|----------|----------|------|
| 1 | 大图片 | 拖入 10MB+ 图片 | 不阻塞 UI | ⬜ |
| 2 | 多文件 | 同时拖入 20 个文件 | 缩略图逐个生成 | ⬜ |
| 3 | 内存占用 | 添加大量文件 | 内存占用合理 | ⬜ |
| 4 | CPU 占用 | 生成缩略图时 | CPU 占用合理 | ⬜ |

**测试说明**：
- 所有测试项必须通过才能进入 Phase 5
- 发现问题立即修复，不要累积
- 每修复一个问题，重新编译测试

---

### 4.8 Phase 4 完成提交

**技术栈**：
- ✅ Git 版本控制
- ❌ 不涉及代码编写

**工具使用**：
- 📝 Git 命令行
- ✅ 使用 build-macos-apps skill 完整验证

**提交命令**：

```bash
git add -A
git commit -m "feat: Phase 4 complete - shelf polish

Phase 4 完成：
- ThumbnailGenerator 缩略图生成器
- QuickLook API 集成
- 异步缩略图生成
- 真实缩略图显示
- 添加/移除动画
- 悬停效果优化
- 拖拽反馈
- 右键菜单增强

功能：
- 图片/PDF/视频缩略图
- 流畅的动画效果
- 优化的交互体验
- 性能优化

测试状态：全部通过

下一步：Phase 5 - 剪切板历史

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

**Phase 完成验证**：

使用 build-macos-apps skill 进行完整构建验证：
```
/using-build-macos-apps
```

---

## Phase 4 总结

### 已完成功能

✅ **缩略图生成**：
- ThumbnailGenerator 缩略图生成器
- QuickLook API 集成
- 支持图片、PDF、视频、文档
- 异步生成，不阻塞 UI

✅ **UI 美化**：
- 真实缩略图显示
- 悬停效果（背景+边框）
- 拖拽反馈（缩放+透明度）
- 右键菜单增强（拷贝路径）

✅ **动画效果**：
- 添加动画（缩放+淡入）
- 移除动画（缩放+淡出）
- 弹簧动画（自然流畅）
- 悬停动画（平滑过渡）

✅ **性能优化**：
- Task.detached 后台处理
- @MainActor 主线程更新
- 异步加载，先显示后更新

### 技术亮点

1. **QuickLook 集成**：
   - 系统级缩略图支持
   - 支持多种文件格式
   - 自动适配 Retina

2. **异步处理**：
   - async/await 模式
   - 不阻塞主线程
   - 性能优化

3. **SwiftUI 动画**：
   - 声明式动画
   - 弹簧动画
   - 流畅自然

### 已知限制

❌ **暂未实现**（后续 Phase 完成）：
- 剪切板历史（Phase 5）
- 设置页（Phase 6）
- 关于页（Phase 7）

### 下一步：Phase 5

**目标**：实现剪切板历史功能

**核心任务**：
1. ClipboardItem 数据模型
2. ClipboardMonitor 剪切板监听
3. ClipboardViewModel 状态管理
4. ClipboardHistoryView UI 界面
5. ClipboardWindow 窗口容器
6. 数据持久化

**文档**：`phase-5-clipboard-history.md`

---

## 附录：常见问题

### Q1: 缩略图不显示？

检查：
1. 文件是否存在
2. QuickLook 权限是否正常
3. 异步任务是否执行
4. 查看控制台错误信息

### Q2: 动画卡顿？

检查：
1. 是否在主线程更新 UI
2. 缩略图生成是否阻塞
3. 动画参数是否合理
4. 项目数量是否过多

### Q3: 缩略图模糊？

检查：
1. size 参数是否正确
2. scale 是否适配 Retina
3. aspectRatio 是否正确

### Q4: 内存占用过高？

检查：
1. 缩略图尺寸是否过大
2. 是否有内存泄漏
3. 项目数量限制是否生效

---

**Phase 4 完成！🎉**

准备好进入 Phase 5 了吗？打开 `phase-5-clipboard-history.md` 继续开发。

