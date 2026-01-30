# Phase 5: 剪切板历史

> 创建日期：2026-01-29
> 状态：待开发

---

## Phase 概述

**目标**：实现剪切板历史记录功能

**预计时间**：第 10-12 天

**成功标准**：
- ✅ 监听剪切板变化
- ✅ 记录历史内容
- ✅ 显示历史列表
- ✅ 搜索和筛选
- ✅ 数据持久化

---

## 技术栈总览

本 Phase 涉及的技术栈：

| 组件 | 技术选择 | 原因 |
|------|---------|------|
| 剪切板监听 | ✅ NSPasteboard.general | 系统剪切板 API |
| 定时检查 | ✅ Timer | 定期检查变化 |
| 数据模型 | ✅ Codable | JSON 序列化 |
| 持久化 | ✅ FileManager + JSON | 简单可靠 |
| UI 视图 | ✅ SwiftUI | 现代 UI |
| 窗口容器 | ✅ NSWindow | 标准窗口 |
| 响应式 | ✅ Combine | 数据流管理 |

**关键技术**：
- ✅ NSPasteboard.changeCount（检测变化）
- ✅ Timer.scheduledTimer（定时检查）
- ✅ JSONEncoder/JSONDecoder（持久化）
- ✅ Combine Publishers（响应式更新）

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
- ✅ 写 Combine 代码前使用
- 使用方式：`/using-axiom [问题]`

---

## 步骤详解

---

### 5.1 创建 ClipboardItem 数据模型

**技术栈**：
- ✅ 纯 Swift 数据模型
- ✅ Codable（JSON 序列化）
- ✅ Identifiable（SwiftUI 要求）
- ❌ 不涉及 UI

**工具使用**：
- 📝 编辑器：编写数据模型
- 🔨 编译：使用 XcodeBuildMCP

**文件**：`Sources/Features/Clipboard/ClipboardItem.swift`

**代码结构**：

```swift
import Foundation
import AppKit

/// 剪切板项目
struct ClipboardItem: Identifiable, Codable {
    let id: UUID
    let type: ItemType
    let content: String
    let timestamp: Date
    var isFavorite: Bool

    enum ItemType: String, Codable {
        case text
        case url
        case image
        case file
    }

    init(type: ItemType, content: String) {
        self.id = UUID()
        self.type = type
        self.content = content
        self.timestamp = Date()
        self.isFavorite = false
    }

    /// 显示的预览文本
    var preview: String {
        let maxLength = 100
        if content.count > maxLength {
            return String(content.prefix(maxLength)) + "..."
        }
        return content
    }

    /// 格式化的时间
    var formattedTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}
```

**详细说明**：

1. **属性设计**：
   - `id`: UUID 唯一标识
   - `type`: 内容类型（文本、URL、图片、文件）
   - `content`: 内容字符串
   - `timestamp`: 时间戳
   - `isFavorite`: 是否收藏

2. **辅助属性**：
   - `preview`: 预览文本（限制长度）
   - `formattedTime`: 相对时间（如"5分钟前"）

3. **Codable**：
   - 支持 JSON 序列化
   - 用于持久化存储

**测试要点**：
- 创建不同类型的项目
- 预览文本正确截断
- 时间格式化正确

**编译**：
使用 mcp__xcodebuildmcp__build 工具编译项目

**提交**：
```bash
git add Sources/Features/Clipboard/ClipboardItem.swift
git commit -m "feat: add ClipboardItem data model"
```

---

### 5.2 创建 ClipboardMonitor（监听剪切板变化）

**技术栈**：
- ✅ NSPasteboard.general（系统剪切板）
- ✅ Timer.scheduledTimer（定时检查）
- ✅ Combine（发布变化事件）
- ❌ 不涉及 UI

**工具使用**：
- 📝 编辑器：编写监听逻辑
- 🔨 编译：使用 XcodeBuildMCP
- ❓ Combine 代码前：使用 Axiom skill

**文件**：`Sources/Services/ClipboardMonitor.swift`

**代码结构**：

```swift
import Foundation
import AppKit
import Combine

/// 剪切板监听器
class ClipboardMonitor: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var latestItem: ClipboardItem?
    
    // MARK: - Private Properties
    
    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private let checkInterval: TimeInterval = 0.5
    
    // MARK: - Initialization
    
    init() {
        lastChangeCount = NSPasteboard.general.changeCount
    }
    
    // MARK: - Public Methods
    
    /// 开始监听
    func startMonitoring() {
        guard timer == nil else { return }
        
        timer = Timer.scheduledTimer(
            withTimeInterval: checkInterval,
            repeats: true
        ) { [weak self] _ in
            self?.checkPasteboard()
        }
        
        // 立即检查一次
        checkPasteboard()
    }
    
    /// 停止监听
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Private Methods
    
    private func checkPasteboard() {
        let currentChangeCount = NSPasteboard.general.changeCount
        
        // 检测到变化
        guard currentChangeCount != lastChangeCount else { return }
        lastChangeCount = currentChangeCount
        
        // 读取剪切板内容
        if let item = readPasteboardContent() {
            latestItem = item
        }
    }
    
    private func readPasteboardContent() -> ClipboardItem? {
        let pasteboard = NSPasteboard.general
        
        // 1. 检查文件 URL
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self]) as? [URL],
           let url = urls.first {
            return ClipboardItem(type: .file, content: url.path)
        }
        
        // 2. 检查图片
        if let image = NSImage(pasteboard: pasteboard) {
            // 将图片转为 base64 存储
            if let tiffData = image.tiffRepresentation,
               let bitmap = NSBitmapImageRep(data: tiffData),
               let pngData = bitmap.representation(using: .png, properties: [:]) {
                let base64 = pngData.base64EncodedString()
                return ClipboardItem(type: .image, content: base64)
            }
        }
        
        // 3. 检查 URL
        if let urlString = pasteboard.string(forType: .URL),
           let _ = URL(string: urlString) {
            return ClipboardItem(type: .url, content: urlString)
        }
        
        // 4. 检查纯文本
        if let text = pasteboard.string(forType: .string), !text.isEmpty {
            // 判断是否为 URL
            if let _ = URL(string: text), text.hasPrefix("http") {
                return ClipboardItem(type: .url, content: text)
            }
            return ClipboardItem(type: .text, content: text)
        }
        
        return nil
    }
    
    deinit {
        stopMonitoring()
    }
}
```

**详细说明**：

1. **定时检查机制**：
   - 使用 Timer 每 0.5 秒检查一次
   - 通过 changeCount 判断是否有变化
   - 避免频繁读取剪切板内容

2. **内容类型判断**：
   - 优先级：文件 > 图片 > URL > 文本
   - 文件：通过 NSURL 类读取
   - 图片：转为 base64 存储
   - URL：检查是否为有效 URL
   - 文本：默认类型

3. **Combine 集成**：
   - 使用 @Published 发布变化
   - 其他组件可订阅 latestItem

4. **生命周期管理**：
   - startMonitoring：启动监听
   - stopMonitoring：停止监听
   - deinit：自动清理

**测试要点**：
- 复制文本，检查是否捕获
- 复制图片，检查是否捕获
- 复制文件，检查是否捕获
- 复制 URL，检查类型判断正确

**编译**：
使用 mcp__xcodebuildmcp__build 工具编译项目

**提交**：
```bash
git add Sources/Services/ClipboardMonitor.swift
git commit -m "feat: add ClipboardMonitor service"
```

---

### 5.3 创建 ClipboardViewModel（状态管理）

**技术栈**：
- ✅ ObservableObject（SwiftUI 状态管理）
- ✅ Combine（响应式编程）
- ✅ @Published（自动通知 UI）
- ❌ 不涉及 UI

**工具使用**：
- 📝 编辑器：编写 ViewModel
- 🔨 编译：使用 XcodeBuildMCP
- ❓ Combine 代码前：使用 Axiom skill

**文件**：`Sources/Features/Clipboard/ClipboardViewModel.swift`

**代码结构**：

```swift
import Foundation
import Combine

/// 剪切板历史视图模型
class ClipboardViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var items: [ClipboardItem] = []
    @Published var searchText: String = ""
    @Published var selectedType: ClipboardItem.ItemType?
    
    // MARK: - Computed Properties
    
    /// 过滤后的项目
    var filteredItems: [ClipboardItem] {
        var result = items
        
        // 按类型过滤
        if let type = selectedType {
            result = result.filter { $0.type == type }
        }
        
        // 按搜索文本过滤
        if !searchText.isEmpty {
            result = result.filter { item in
                item.content.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return result
    }
    
    /// 收藏的项目
    var favoriteItems: [ClipboardItem] {
        items.filter { $0.isFavorite }
    }
    
    // MARK: - Private Properties
    
    private let monitor: ClipboardMonitor
    private let storage: ClipboardStorage
    private var cancellables = Set<AnyCancellable>()
    private let maxItems = 100
    
    // MARK: - Initialization
    
    init(monitor: ClipboardMonitor, storage: ClipboardStorage) {
        self.monitor = monitor
        self.storage = storage
        
        // 加载历史记录
        loadHistory()
        
        // 订阅剪切板变化
        monitor.$latestItem
            .compactMap { $0 }
            .sink { [weak self] item in
                self?.addItem(item)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// 添加项目
    func addItem(_ item: ClipboardItem) {
        // 避免重复（检查最近 5 条）
        let recentItems = items.prefix(5)
        if recentItems.contains(where: { $0.content == item.content }) {
            return
        }
        
        // 插入到开头
        items.insert(item, at: 0)
        
        // 限制数量
        if items.count > maxItems {
            items = Array(items.prefix(maxItems))
        }
        
        // 保存
        saveHistory()
    }
    
    /// 删除项目
    func deleteItem(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
        saveHistory()
    }
    
    /// 清空历史
    func clearHistory() {
        items.removeAll()
        saveHistory()
    }
    
    /// 切换收藏状态
    func toggleFavorite(_ item: ClipboardItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].isFavorite.toggle()
            saveHistory()
        }
    }
    
    /// 复制到剪切板
    func copyToClipboard(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        switch item.type {
        case .text, .url:
            pasteboard.setString(item.content, forType: .string)
            
        case .file:
            if let url = URL(string: item.content) {
                pasteboard.writeObjects([url as NSURL])
            }
            
        case .image:
            // 从 base64 还原图片
            if let data = Data(base64Encoded: item.content),
               let image = NSImage(data: data) {
                pasteboard.writeObjects([image])
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func loadHistory() {
        items = storage.load()
    }
    
    private func saveHistory() {
        storage.save(items)
    }
}
```

**详细说明**：

1. **状态管理**：
   - `items`: 所有历史项目
   - `searchText`: 搜索关键词
   - `selectedType`: 类型过滤

2. **计算属性**：
   - `filteredItems`: 根据搜索和类型过滤
   - `favoriteItems`: 收藏的项目

3. **核心功能**：
   - `addItem`: 添加新项目（去重、限制数量）
   - `deleteItem`: 删除项目
   - `clearHistory`: 清空历史
   - `toggleFavorite`: 切换收藏
   - `copyToClipboard`: 复制到剪切板

4. **Combine 集成**：
   - 订阅 ClipboardMonitor 的变化
   - 自动添加新项目

5. **持久化**：
   - 每次修改后自动保存
   - 启动时加载历史

**测试要点**：
- 添加项目后自动保存
- 搜索功能正确
- 类型过滤正确
- 收藏功能正常
- 复制到剪切板成功

**编译**：
使用 mcp__xcodebuildmcp__build 工具编译项目

**提交**：
```bash
git add Sources/Features/Clipboard/ClipboardViewModel.swift
git commit -m "feat: add ClipboardViewModel"
```

---

### 5.4 创建 ClipboardHistoryView（UI 界面）

**技术栈**：
- ✅ SwiftUI（UI 框架）
- ✅ List（列表视图）
- ✅ SearchField（搜索框）
- ✅ Picker（类型选择器）

**工具使用**：
- 📝 编辑器：编写 SwiftUI 视图
- 🔨 编译：使用 XcodeBuildMCP
- ❓ 复杂 UI 前：使用 Axiom skill

**文件**：`Sources/Features/Clipboard/ClipboardHistoryView.swift`

**代码结构**：

```swift
import SwiftUI

/// 剪切板历史视图
struct ClipboardHistoryView: View {
    
    @ObservedObject var viewModel: ClipboardViewModel
    @State private var hoveredItemId: UUID?
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部工具栏
            toolbarView
            
            Divider()
            
            // 主内容区
            if viewModel.filteredItems.isEmpty {
                emptyView
            } else {
                listView
            }
        }
        .frame(width: 400, height: 600)
        .background(.regularMaterial)
    }
    
    // MARK: - Toolbar
    
    private var toolbarView: some View {
        VStack(spacing: 12) {
            // 搜索框
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("搜索历史...", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                
                if !viewModel.searchText.isEmpty {
                    Button(action: { viewModel.searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color.primary.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // 类型过滤
            HStack(spacing: 8) {
                typeFilterButton(type: nil, label: "全部", icon: "square.grid.2x2")
                typeFilterButton(type: .text, label: "文本", icon: "doc.text")
                typeFilterButton(type: .url, label: "链接", icon: "link")
                typeFilterButton(type: .image, label: "图片", icon: "photo")
                typeFilterButton(type: .file, label: "文件", icon: "doc")
                
                Spacer()
                
                // 清空按钮
                Button(action: { viewModel.clearHistory() }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .help("清空历史")
            }
        }
        .padding(12)
    }
    
    private func typeFilterButton(type: ClipboardItem.ItemType?, label: String, icon: String) -> some View {
        Button(action: { viewModel.selectedType = type }) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                Text(label)
                    .font(.caption)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(viewModel.selectedType == type ? Color.accentColor : Color.clear)
            .foregroundColor(viewModel.selectedType == type ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - List
    
    private var listView: some View {
        ScrollView {
            LazyVStack(spacing: 1) {
                ForEach(viewModel.filteredItems) { item in
                    ClipboardItemView(
                        item: item,
                        isHovered: hoveredItemId == item.id,
                        onCopy: { viewModel.copyToClipboard(item) },
                        onDelete: { viewModel.deleteItem(item) },
                        onToggleFavorite: { viewModel.toggleFavorite(item) }
                    )
                    .onHover { isHovered in
                        hoveredItemId = isHovered ? item.id : nil
                    }
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("暂无历史记录")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("复制内容后会自动记录")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
```

**详细说明**：

1. **布局结构**：
   - 顶部：搜索框 + 类型过滤
   - 中间：列表视图
   - 空状态：提示信息

2. **搜索功能**：
   - 实时搜索
   - 清除按钮
   - 搜索图标

3. **类型过滤**：
   - 全部、文本、链接、图片、文件
   - 选中状态高亮
   - 图标 + 文字

4. **列表视图**：
   - LazyVStack（性能优化）
   - 悬停效果
   - 项目视图（下一步实现）

5. **空状态**：
   - 图标 + 文字提示
   - 居中显示

**测试要点**：
- 搜索框输入正常
- 类型过滤切换正常
- 列表滚动流畅
- 空状态显示正确

**编译**：
使用 mcp__xcodebuildmcp__build 工具编译项目

**提交**：
```bash
git add Sources/Features/Clipboard/ClipboardHistoryView.swift
git commit -m "feat: add ClipboardHistoryView UI"
```

---

### 5.5 创建 ClipboardItemView（单个项目视图）

**技术栈**：
- ✅ SwiftUI（UI 框架）
- ✅ ContextMenu（右键菜单）
- ✅ 悬停效果
- ✅ SF Symbols（图标）

**工具使用**：
- 📝 编辑器：编写 SwiftUI 视图
- 🔨 编译：使用 XcodeBuildMCP

**文件**：`Sources/Features/Clipboard/ClipboardItemView.swift`

**代码结构**：

```swift
import SwiftUI

/// 剪切板项目视图
struct ClipboardItemView: View {
    
    let item: ClipboardItem
    let isHovered: Bool
    let onCopy: () -> Void
    let onDelete: () -> Void
    let onToggleFavorite: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // 类型图标
            typeIcon
                .frame(width: 32, height: 32)
            
            // 内容区
            VStack(alignment: .leading, spacing: 4) {
                // 预览文本
                Text(item.preview)
                    .font(.body)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                
                // 时间 + 类型
                HStack(spacing: 8) {
                    Text(item.formattedTime)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(typeLabel)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // 收藏图标
            if item.isFavorite {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.caption)
            }
            
            // 悬停时显示操作按钮
            if isHovered {
                actionButtons
            }
        }
        .padding(12)
        .background(isHovered ? Color.primary.opacity(0.05) : Color.clear)
        .contentShape(Rectangle())
        .contextMenu {
            contextMenuItems
        }
        .onTapGesture(count: 2) {
            onCopy()
        }
    }
    
    // MARK: - Type Icon
    
    @ViewBuilder
    private var typeIcon: some View {
        ZStack {
            Circle()
                .fill(iconBackgroundColor)
            
            Image(systemName: iconName)
                .foregroundColor(iconColor)
                .font(.system(size: 16))
        }
    }
    
    private var iconName: String {
        switch item.type {
        case .text: return "doc.text"
        case .url: return "link"
        case .image: return "photo"
        case .file: return "doc"
        }
    }
    
    private var iconColor: Color {
        switch item.type {
        case .text: return .blue
        case .url: return .purple
        case .image: return .green
        case .file: return .orange
        }
    }
    
    private var iconBackgroundColor: Color {
        iconColor.opacity(0.15)
    }
    
    private var typeLabel: String {
        switch item.type {
        case .text: return "文本"
        case .url: return "链接"
        case .image: return "图片"
        case .file: return "文件"
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack(spacing: 8) {
            // 复制按钮
            Button(action: onCopy) {
                Image(systemName: "doc.on.doc")
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
            .help("复制")
            
            // 收藏按钮
            Button(action: onToggleFavorite) {
                Image(systemName: item.isFavorite ? "star.fill" : "star")
                    .foregroundColor(.yellow)
            }
            .buttonStyle(.plain)
            .help(item.isFavorite ? "取消收藏" : "收藏")
            
            // 删除按钮
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
            .help("删除")
        }
    }
    
    // MARK: - Context Menu
    
    @ViewBuilder
    private var contextMenuItems: some View {
        Button(action: onCopy) {
            Label("复制", systemImage: "doc.on.doc")
        }
        
        Button(action: onToggleFavorite) {
            Label(
                item.isFavorite ? "取消收藏" : "收藏",
                systemImage: item.isFavorite ? "star.slash" : "star"
            )
        }
        
        Divider()
        
        Button(action: onDelete) {
            Label("删除", systemImage: "trash")
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        ClipboardItemView(
            item: ClipboardItem(type: .text, content: "这是一段测试文本"),
            isHovered: false,
            onCopy: {},
            onDelete: {},
            onToggleFavorite: 
        )
        
        ClipboardItemView(
            item: ClipboardItem(type: .url, content: "https://example.com"),
            isHovered: true,
            onCopy: {},
            onDelete: {},
            onToggleFavorite: {}
        )
        
        ClipboardItemView(
            item: ClipboardItem(type: .image, content: "base64..."),
            isHovered: false,
            onCopy: {},
            onDelete: {},
            onToggleFavorite: {}
        )
    }
    .frame(width: 400)
}
```

**详细说明**：

1. **布局结构**：
   - 左侧：类型图标（圆形背景）
   - 中间：预览文本 + 时间/类型
   - 右侧：收藏图标 + 操作按钮

2. **类型图标**：
   - 不同类型不同颜色
   - 圆形背景 + SF Symbol
   - 颜色：文本蓝、链接紫、图片绿、文件橙

3. **交互功能**：
   - 悬停：显示操作按钮
   - 双击：复制到剪切板
   - 右键：上下文菜单

4. **操作按钮**：
   - 复制、收藏、删除
   - 悬停时显示
   - 图标 + 提示

5. **上下文菜单**：
   - 复制、收藏、删除
   - 分隔线
   - 图标 + 文字

**测试要点**：
- 不同类型显示正确
- 悬停效果正常
- 双击复制成功
- 右键菜单正常
- 操作按钮功能正常

**编译**：
使用 mcp__xcodebuildmcp__build 工具编译项目

**提交**：
```bash
git add Sources/Features/Clipboard/ClipboardItemView.swift
git commit -m "feat: add ClipboardItemView component"
```

---

### 5.6 创建 ClipboardWindow（窗口容器）

**技术栈**：
- ✅ NSWindow（标准窗口）
- ✅ NSHostingView（SwiftUI 桥接）
- ✅ 窗口样式配置
- ❌ 不使用 NSPanel

**工具使用**：
- 📝 编辑器：编写 AppKit 代码
- 🔨 编译：使用 XcodeBuildMCP

**文件**：`Sources/Features/Clipboard/ClipboardWindow.swift`

**代码结构**：

```swift
import AppKit
import SwiftUI

/// 剪切板历史窗口
class ClipboardWindow: NSWindow {
    
    private let viewModel: ClipboardViewModel
    
    // MARK: - Initialization
    
    init(viewModel: ClipboardViewModel) {
        self.viewModel = viewModel
        
        // 窗口配置
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 600),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        setupWindow()
        setupContent()
        centerWindow()
    }
    
    // MARK: - Setup
    
    private func setupWindow() {
        title = "剪切板历史"
        
        // 窗口行为
        isReleasedWhenClosed = false
        
        // 最小尺寸
        minSize = NSSize(width: 300, height: 400)
        
        // 标题栏样式
        titlebarAppearsTransparent = false
        
        // 工具栏样式
        toolbarStyle = .unified
    }
    
    private func setupContent() {
        let contentView = ClipboardHistoryView(viewModel: viewModel)
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
    
    /// 切换显示/隐藏
    func toggle() {
        if isVisible {
            hide()
        } else {
            show()
        }
    }
}
```

**详细说明**：

1. **窗口配置**：
   - 标准窗口样式（标题栏 + 关闭按钮 + 可调整大小）
   - 初始尺寸：400x600
   - 最小尺寸：300x400

2. **窗口行为**：
   - `isReleasedWhenClosed = false`：关闭时不释放
   - 统一工具栏样式
   - 居中显示

3. **SwiftUI 集成**：
   - 使用 NSHostingView 桥接
   - 传入 ViewModel

4. **公共方法**：
   - `show()`: 显示并激活
   - `hide()`: 隐藏
   - `toggle()`: 切换显示状态

**测试要点**：
- 窗口显示正常
- 窗口居中
- 可调整大小
- 关闭后不释放
- 快捷键切换正常

**编译**：
使用 mcp__xcodebuildmcp__build 工具编译项目

**提交**：
```bash
git add Sources/Features/Clipboard/ClipboardWindow.swift
git commit -m "feat: add ClipboardWindow container"
```

---

### 5.7 数据持久化（ClipboardStorage）

**技术栈**：
- ✅ FileManager（文件管理）
- ✅ JSONEncoder/JSONDecoder（JSON 序列化）
- ✅ Application Support 目录
- ❌ 不使用 UserDefaults（数据量大）

**工具使用**：
- 📝 编辑器：编写持久化逻辑
- 🔨 编译：使用 XcodeBuildMCP

**文件**：`Sources/Services/ClipboardStorage.swift`

**代码结构**：

```swift
import Foundation

/// 剪切板历史存储
class ClipboardStorage {
    
    // MARK: - Properties
    
    private let fileManager = FileManager.default
    private let fileName = "clipboard-history.json"
    
    private var fileURL: URL {
        let appSupport = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        
        let appFolder = appSupport.appendingPathComponent("DropKit")
        
        // 确保目录存在
        try? fileManager.createDirectory(
            at: appFolder,
            withIntermediateDirectories: true
        )
        
        return appFolder.appendingPathComponent(fileName)
    }
    
    // MARK: - Public Methods
    
    /// 保存历史记录
    func save(_ items: [ClipboardItem]) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            
            let data = try encoder.encode(items)
            try data.write(to: fileURL, options: .atomic)
            
            print("✅ 保存剪切板历史成功: \(items.count) 项")
        } catch {
            print("❌ 保存剪切板历史失败: \(error)")
        }
    }
    
    /// 加载历史记录
    func load() -> [ClipboardItem] {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            print("ℹ️ 历史文件不存在，返回空数组")
            return []
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let items = try decoder.decode([ClipboardItem].self, from: data)
            
            print("✅ 加载剪切板历史成功: \(items.count) 项")
            return items
        } catch {
            print("❌ 加载剪切板历史失败: \(error)")
            return []
        }
    }
    
    /// 清空历史文件
    func clear() {
        do {
            if fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.removeItem(at: fileURL)
                print("✅ 清空剪切板历史成功")
            }
        } catch {
            print("❌ 清空剪切板历史失败: \(error)")
        }
    }
    
    /// 获取文件大小
    func getFileSize() -> String {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return "0 KB"
        }
        
        do {
            let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
            if let size = attributes[.size] as? Int64 {
                return formatBytes(size)
            }
        } catch {
            print("❌ 获取文件大小失败: \(error)")
        }
        
        return "未知"
    }
    
    // MARK: - Private Methods
    
    private func formatBytes(_ bytes: Int64) -> String {
        let kb = Double(bytes) / 1024.0
        if kb < 1024 {
            return String(format: "%.1f KB", kb)
        }
        
        let mb = kb / 1024.0
        return String(format: "%.1f MB", mb)
    }
}
```

**详细说明**：

1. **存储位置**：
   - Application Support 目录
   - `~/Library/Application Support/DropKit/clipboard-history.json`
   - 自动创建目录

2. **序列化格式**：
   - JSON 格式
   - ISO8601 日期格式
   - Pretty Print（便于调试）

3. **核心方法**：
   - `save()`: 保存历史记录
   - `load()`: 加载历史记录
   - `clear()`: 清空历史文件
   - `getFileSize()`: 获取文件大小

4. **错误处理**：
   - 文件不存在返回空数组
   - 解析失败返回空数组
   - 打印日志便于调试

5. **原子写入**：
   - 使用 `.atomic` 选项
   - 避免写入过程中崩溃导致数据损坏

**测试要点**：
- 保存后文件存在
- 加载数据正确
- 清空功能正常
- 文件大小计算正确
- 目录自动创建

**编译**：
使用 mcp__xcodebuildmcp__build 工具编译项目

**提交**：
```bash
git add Sources/Services/ClipboardStorage.swift
git commit -m "feat: add ClipboardStorage service"
```

---

### 5.8 集成到 AppState

**技术栈**：
- ✅ 依赖注入
- ✅ 生命周期管理
- ✅ 快捷键绑定
- ❌ 不涉及新文件

**工具使用**：
- 📝 编辑器：修改 AppState
- 🔨 编译：使用 XcodeBuildMCP

**文件**：`Sources/AppState.swift`

**代码修改**：

```swift
import SwiftUI
import AppKit

@MainActor
class AppState: ObservableObject {
    
    // MARK: - Existing Properties
    
    // ... 现有属性 ...
    
    // MARK: - Clipboard Properties (新增)
    
    let clipboardMonitor: ClipboardMonitor
    let clipboardStorage: ClipboardStorage
    let clipboardViewModel: ClipboardViewModel
    private(set) var clipboardWindow: ClipboardWindow?
    
    // MARK: - Initialization
    
    init() {
        // ... 现有初始化代码 ...
        
        // 初始化剪切板组件
        self.clipboardStorage = ClipboardStorage()
        self.clipboardMonitor = ClipboardMonitor()
        self.clipboardViewModel = ClipboardViewModel(
            monitor: clipboardMonitor,
            storage: clipboardStorage
        )
        
        // 启动剪切板监听
        clipboardMonitor.startMonitoring()
        
        // 创建剪切板窗口
        self.clipboardWindow = ClipboardWindow(viewModel: clipboardViewModel)
        
        // 注册快捷键
        setupClipboardHotkey()
    }
    
    // MARK: - Clipboard Methods (新增)
    
    /// 切换剪切板历史窗口
    func toggleClipboardHistory() {
        clipboardWindow?.toggle()
    }
    
    /// 显示剪切板历史窗口
    func showClipboardHistory() {
        clipboardWindow?.show()
    }
    
    /// 隐藏剪切板历史窗口
    func hideClipboardHistory() {
        clipboardWindow?.hide()
    }
    
    // MARK: - Private Methods (新增)
    
    private func setupClipboardHotkey() {
        // 注册全局快捷键 ⌘⇧V
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // ⌘⇧V
            if event.modifierFlags.contains([.command, .shift]),
               event.charactersIgnoringModifiers == "v" {
                self?.toggleClipboardHistory()
                return nil // 消费事件
            }
            return event
        }
    }
    
    // MARK: - Cleanup
    
    deinit {
        clipboardMonitor.stopMonitoring()
    }
}
```

**MenuBarView 修改**：

```swift
// 在 MenuBarView.swift 中添加菜单项

struct MenuBarView: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        // ... 现有菜单项 ...
        
        // 剪切板历史菜单项（新增）
        Button("剪切板历史") {
            appState.showClipboardHistory()
        }
        .keyboardShortcut("v", modifiers: [.command, .shift])
        
        Divider()
        
        // ... 其他菜单项 ...
    }
}
```

**详细说明**：

1. **依赖注入**：
   - ClipboardStorage → ClipboardMonitor → ClipboardViewModel
   - 单向依赖，清晰明了

2. **生命周期管理**：
   - 初始化时启动监听
   - deinit 时停止监听
   - 窗口不释放（isReleasedWhenClosed = false）

3. **快捷键绑定**：
   - 全局快捷键：⌘⇧V
   - 本地监听（应用内）
   - 消费事件避免传递

4. **公共方法**：
   - `toggleClipboardHistory()`: 切换显示
   - `showClipboardHistory()`: 显示窗口
   - `hideClipboardHistory()`: 隐藏窗口

5. **菜单集成**：
   - 添加菜单项
   - 显示快捷键提示
   - 点击显示窗口

**测试要点**：
- 应用启动后自动监听剪切板
- 复制内容后自动记录
- ⌘⇧V 切换窗口显示
- 菜单项点击正常
- 窗口关闭后不释放

**编译**：
使用 mcp__xcodebuildmcp__build 工具编译项目

**提交**：
```bash
git add Sources/AppState.swift Sources/Features/MenuBar/MenuBarView.swift
git commit -m "feat: integrate clipboard history into AppState"
```

---

## 下一步

完成 Phase 5 后，你已经实现了完整的剪切板历史功能：

✅ **已完成**：
- 剪切板监听（ClipboardMonitor）
- 数据模型（ClipboardItem）
- 状态管理（ClipboardViewModel）
- UI 界面（ClipboardHistoryView + ClipboardItemView）
- 窗口容器（ClipboardWindow）
- 数据持久化（ClipboardStorage）
- 集成到应用（AppState）

🎯 **下一步：Phase 6 - 设置页**

进入 `phase-6-settings.md`，实现：
- 通用设置（启动项、快捷键）
- 悬浮窗设置（灵敏度、显示位置）
- 剪切板设置（历史数量、忽略类型）
- 关于页面

---

## 附录：常见问题

### Q1: 剪切板监听不工作

**可能原因**：
- Timer 没有启动
- changeCount 检测失败
- 读取剪切板权限问题

**解决方案**：
```swift
// 检查 Timer 是否运行
print("Timer running: \(monitor.timer != nil)")

// 检查 changeCount
print("Change count: \(NSPasteboard.general.changeCount)")

// 检查剪切板内容
if let string = NSPasteboard.general.string(forType: .string) {
    print("Clipboard content: \(string)")
}
```

### Q2: 图片保存失败

**可能原因**：
- base64 编码失败
- 图片格式不支持
- 数据量过大

**解决方案**：
```swift
// 限制图片大小
let maxSize = CGSize(width: 800, height: 800)
let resized = image.resized(to: maxSize)

// 使用 JPEG 压缩
if let jpegData = resized.jpegData(compressionQuality: 0.7) {
    let base64 = jpegData.base64EncodedString()
    // 保存
}
```

### Q3: 历史记录加载慢

**可能原因**：
- 数据量过大
- JSON 解析慢
- 主线程阻塞

**解决方案**：
```swift
// 异步加载
Task {
    let items = await storage.loadAsync()
    await MainActor.run {
        self.items = items
    }
}

// 限制数量
let maxItems = 100
items = Array(items.prefix(maxItems))
```

### Q4: 快捷键冲突

**可能原因**：
- 系统快捷键冲突
- 其他应用占用
- 监听器未注册

**解决方案**：
```swift
// 使用不同的快捷键组合
// ⌘⇧V → ⌘⌥V
if event.modifierFlags.contains([.command, .option]),
   event.charactersIgnoringModifiers == "v" {
    // ...
}

// 或者使用全局快捷键库
// 如 MASShortcut、HotKey
```

### Q5: 窗口位置不正确

**可能原因**：
- 多显示器环境
- 屏幕坐标计算错误
- 窗口尺寸变化

**解决方案**：
```swift
// 使用鼠标所在屏幕
if let screen = NSScreen.screens.first(where: { screen in
    NSMouseInRect(NSEvent.mouseLocation, screen.frame, false)
}) {
    // 在该屏幕居中
    let screenRect = screen.visibleFrame
    // ...
}

// 记住窗口位置
UserDefaults.standard.set(frame, forKey: "clipboardWindowFrame")
```

---

**Phase 5 完成！** 🎉

