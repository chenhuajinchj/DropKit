# DropKit v2 项目结构文档

> 版本：2.0  
> 技术栈：SwiftUI + AppKit 混合  
> 目标系统：macOS 14.0+

---

## 1. 项目概述

### 1.1 产品定位
DropKit 是一个 macOS 菜单栏应用，核心功能是**悬浮窗文件暂存区**（类似 Dropover），附带剪切板历史管理。

### 1.2 核心功能优先级

| 优先级 | 功能 | 描述 |
|--------|------|------|
| P0 | 悬浮窗 | 拖拽文件时摇晃鼠标触发，文件可拖入拖出 |
| P0 | 菜单栏 | 常驻菜单栏，提供快捷操作入口 |
| P1 | 剪切板历史 | 记录复制历史，可搜索、筛选、粘贴 |
| P2 | 设置 | 自定义快捷键、行为、外观 |

### 1.3 技术选型

```
┌─────────────────────────────────────────────────────┐
│                    DropKit v2                        │
├─────────────────────────────────────────────────────┤
│  UI 层 (SwiftUI)                                    │
│  ├── ShelfView (悬浮窗内容)                          │
│  ├── ClipboardHistoryView (剪切板历史)               │
│  └── SettingsView (设置页)                          │
├─────────────────────────────────────────────────────┤
│  窗口层 (AppKit)                                    │
│  ├── ShelfPanel (NSPanel 悬浮窗容器)                 │
│  ├── ClipboardHistoryWindow (NSWindow)              │
│  └── StatusBarController (NSStatusItem 菜单栏)       │
├─────────────────────────────────────────────────────┤
│  服务层 (Swift)                                     │
│  ├── ShakeDetector (摇晃手势检测)                    │
│  ├── DragMonitor (全局拖拽状态监听)                  │
│  ├── ClipboardMonitor (剪切板监听)                   │
│  └── HotkeyManager (全局快捷键)                      │
├─────────────────────────────────────────────────────┤
│  数据层 (Swift)                                     │
│  ├── ShelfItem (暂存项模型)                          │
│  ├── ClipboardItem (剪切板项模型)                    │
│  ├── AppSettings (设置模型)                          │
│  └── DataStore (本地持久化)                          │
└─────────────────────────────────────────────────────┘
```

---

## 2. 目录结构

```
DropKit/
├── DropKit.xcodeproj
├── DropKit/
│   ├── App/
│   │   ├── DropKitApp.swift          # 应用入口
│   │   ├── AppDelegate.swift         # AppKit 生命周期
│   │   └── AppState.swift            # 全局状态管理
│   │
│   ├── Features/
│   │   ├── Shelf/                    # 悬浮窗功能模块
│   │   │   ├── ShelfPanel.swift      # NSPanel 窗口容器
│   │   │   ├── ShelfView.swift       # SwiftUI 视图
│   │   │   ├── ShelfItemView.swift   # 单个项目视图
│   │   │   ├── ShelfViewModel.swift  # 视图模型
│   │   │   └── ShelfItem.swift       # 数据模型
│   │   │
│   │   ├── Clipboard/                # 剪切板功能模块
│   │   │   ├── ClipboardWindow.swift # NSWindow 容器
│   │   │   ├── ClipboardHistoryView.swift
│   │   │   ├── ClipboardItemRow.swift
│   │   │   ├── ClipboardViewModel.swift
│   │   │   └── ClipboardItem.swift
│   │   │
│   │   ├── MenuBar/                  # 菜单栏模块
│   │   │   ├── StatusBarController.swift
│   │   │   └── StatusBarMenu.swift
│   │   │
│   │   └── Settings/                 # 设置模块
│   │       ├── SettingsWindow.swift
│   │       ├── SettingsView.swift
│   │       ├── GeneralSettingsView.swift
│   │       ├── ShelfSettingsView.swift
│   │       ├── ClipboardSettingsView.swift
│   │       └── ShortcutsSettingsView.swift
│   │
│   ├── Services/                     # 核心服务
│   │   ├── ShakeDetector.swift       # 摇晃手势检测
│   │   ├── DragMonitor.swift         # 全局拖拽监听
│   │   ├── ClipboardMonitor.swift    # 剪切板监听
│   │   ├── HotkeyManager.swift       # 全局快捷键
│   │   └── ScreenshotMonitor.swift   # 截图监听（可选）
│   │
│   ├── Models/                       # 数据模型
│   │   ├── AppSettings.swift         # 设置模型
│   │   └── DataStore.swift           # 本地存储
│   │
│   ├── Utilities/                    # 工具类
│   │   ├── Constants.swift           # 常量定义
│   │   ├── Extensions/
│   │   │   ├── NSImage+Extensions.swift
│   │   │   ├── URL+Extensions.swift
│   │   │   └── View+Extensions.swift
│   │   └── Helpers/
│   │       ├── ThumbnailGenerator.swift
│   │       └── HTMLStripper.swift
│   │
│   ├── Resources/
│   │   ├── Assets.xcassets
│   │   ├── Info.plist
│   │   └── DropKit.entitlements
│   │
│   └── Preview Content/
│       └── Preview Assets.xcassets
│
├── CLAUDE.md                         # AI 开发规范
├── AGENTS.md                         # 通用 AI 指令
├── README.md
├── CHANGELOG.md
└── .gitignore
```

---

## 3. 模块详细设计

### 3.1 悬浮窗模块 (Shelf)

**职责**：文件暂存、拖入拖出、显示缩略图

#### ShelfPanel.swift (AppKit)
```swift
// NSPanel 子类，负责：
// - 窗口层级（浮在所有窗口之上）
// - 窗口位置（跟随鼠标或固定位置）
// - 接收拖拽（NSPasteboardReading）
// - 毛玻璃背景

class ShelfPanel: NSPanel {
    // 关键属性
    level = .floating
    styleMask = [.borderless, .nonactivatingPanel]
    isMovableByWindowBackground = true
    
    // 关键方法
    func show(at position: NSPoint)
    func hide()
    func addItems(_ urls: [URL])
}
```

#### ShelfView.swift (SwiftUI)
```swift
// 悬浮窗内部 UI，负责：
// - 显示项目网格/列表
// - 空状态提示
// - 项目操作（删除、在 Finder 显示）

struct ShelfView: View {
    @ObservedObject var viewModel: ShelfViewModel
    
    // 状态
    // - 空：显示虚线框 + 提示
    // - 有内容：显示缩略图网格
}
```

#### ShelfItem.swift (数据模型)
```swift
struct ShelfItem: Identifiable {
    let id: UUID
    let url: URL
    let name: String
    let type: ItemType  // file, folder, image, text, url
    let thumbnail: NSImage?
    let addedAt: Date
    
    enum ItemType {
        case file, folder, image, text, url
    }
}
```

### 3.2 拖拽与摇晃检测 (Services)

#### DragMonitor.swift
```swift
// 监听全局拖拽状态
// 关键：判断用户是否正在拖拽文件

class DragMonitor {
    // 使用 NSEvent.addGlobalMonitorForEvents 监听
    // 检测 .leftMouseDragged 事件
    // 配合 NSPasteboard.general 判断是否有拖拽内容
    
    var isDragging: Bool { get }
    var onDragStart: (() -> Void)?
    var onDragEnd: (() -> Void)?
}
```

#### ShakeDetector.swift
```swift
// 检测鼠标摇晃手势
// 核心逻辑：短时间内鼠标 X 方向多次反向移动

class ShakeDetector {
    // 配置
    var sensitivity: Double  // 灵敏度 0-1
    var minShakes: Int = 3   // 最少摇晃次数
    var timeWindow: Double = 0.5  // 时间窗口（秒）
    
    // 回调
    var onShakeDetected: (() -> Void)?
    
    // 关键：只在 DragMonitor.isDragging == true 时才检测
}
```

### 3.3 菜单栏模块 (MenuBar)

#### StatusBarController.swift
```swift
class StatusBarController {
    private var statusItem: NSStatusItem
    
    // 菜单项
    // - 打开剪切板历史 (⌘H)
    // - 显示悬浮窗 (⌘⇧V)
    // - 分隔线
    // - 设置... (⌘,)
    // - 关于 DropKit
    // - 分隔线
    // - 退出 (⌘Q)
}
```

### 3.4 剪切板模块 (Clipboard)

#### ClipboardMonitor.swift
```swift
class ClipboardMonitor {
    // 定时检查 NSPasteboard.general.changeCount
    // 检测到变化时解析内容并保存
    
    var onNewItem: ((ClipboardItem) -> Void)?
    var excludedApps: [String]  // 排除的应用（如密码管理器）
}
```

#### ClipboardItem.swift
```swift
struct ClipboardItem: Identifiable, Codable {
    let id: UUID
    let content: ClipboardContent
    let sourceApp: String?
    let createdAt: Date
    var isFavorite: Bool
    var isPinned: Bool
    
    enum ClipboardContent: Codable {
        case text(String)
        case html(String, plainText: String)
        case image(Data)
        case file([URL])
        case url(URL, title: String?)
    }
}
```

### 3.5 设置模块 (Settings)

#### AppSettings.swift
```swift
class AppSettings: ObservableObject {
    // 通用
    @AppStorage("launchAtLogin") var launchAtLogin = false
    
    // 悬浮窗
    @AppStorage("shelfOpacity") var shelfOpacity = 1.0
    @AppStorage("shakeSensitivity") var shakeSensitivity = 0.5
    @AppStorage("shelfReuseWindow") var shelfReuseWindow = 30  // 秒
    
    // 剪切板
    @AppStorage("clipboardEnabled") var clipboardEnabled = true
    @AppStorage("clipboardMaxItems") var clipboardMaxItems = 100
    @AppStorage("clipboardRetentionDays") var clipboardRetentionDays = 7
    
    // 快捷键
    @AppStorage("hotkeyClipboard") var hotkeyClipboard = "⌘⇧V"
    @AppStorage("hotkeyShelf") var hotkeyShelf = "⌘⇧S"
}
```

---

## 4. 开发顺序

### Phase 1：最小可用悬浮窗（MVP）
```
目标：能拖入文件、能拖出文件

1.1 项目初始化 + Git
1.2 AppDelegate + 基础生命周期
1.3 ShelfPanel (NSPanel 空窗口)
1.4 ShelfView (空状态 UI)
1.5 拖入功能 (registerForDraggedTypes)
1.6 拖出功能 (NSDraggingSource)
1.7 测试 → commit "feat: basic shelf drag in/out"
```

### Phase 2：摇晃触发
```
目标：拖拽文件时摇晃鼠标触发悬浮窗

2.1 DragMonitor (全局拖拽检测)
2.2 ShakeDetector (摇晃检测)
2.3 整合：拖拽中摇晃 → 显示悬浮窗
2.4 测试 → commit "feat: shake to show shelf"
```

### Phase 3：菜单栏
```
目标：菜单栏图标 + 基础菜单

3.1 StatusBarController
3.2 菜单项（设置、退出）
3.3 测试 → commit "feat: menu bar"
```

### Phase 4：悬浮窗完善
```
目标：缩略图、多文件、UI 美化

4.1 ThumbnailGenerator
4.2 ShelfItemView (带缩略图)
4.3 多文件支持
4.4 毛玻璃 + 动画
4.5 测试 → commit "feat: shelf thumbnails and polish"
```

### Phase 5：剪切板历史
```
目标：基础剪切板历史功能

5.1 ClipboardMonitor
5.2 ClipboardItem + DataStore
5.3 ClipboardHistoryView
5.4 搜索 + 筛选
5.5 测试 → commit "feat: clipboard history"
```

### Phase 6：设置页
```
目标：完整设置界面

6.1 SettingsWindow
6.2 各设置页 (General, Shelf, Clipboard, Shortcuts)
6.3 AppSettings 持久化
6.4 测试 → commit "feat: settings"
```

### Phase 7：收尾
```
7.1 全局快捷键
7.2 开机启动
7.3 关于页面
7.4 错误处理 + 边界情况
7.5 性能优化
7.6 测试 → commit "feat: polish and release prep"
```

---

## 5. 关键技术点

### 5.1 悬浮窗层级

```swift
// ShelfPanel 必须设置这些属性才能正确浮动
panel.level = .floating  // 或 .statusBar
panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
panel.styleMask = [.borderless, .nonactivatingPanel]
panel.isOpaque = false
panel.backgroundColor = .clear
```

### 5.2 全局拖拽检测

```swift
// 检测是否有东西正在被拖拽
NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDragged) { event in
    // 配合 NSPasteboard 检查
}
```

### 5.3 摇晃检测算法

```swift
// 记录鼠标 X 坐标变化
// 检测短时间内的方向反转次数
// 反转次数 >= 3 且在时间窗口内 → 触发
```

### 5.4 拖拽接收

```swift
// ShelfPanel 需要注册接收的类型
panel.registerForDraggedTypes([
    .fileURL,
    .URL,
    .string,
    .png,
    .tiff
])
```

---

## 6. 注意事项

### 6.1 必须避免的坑

1. **不要用纯 SwiftUI 做悬浮窗**：MenuBarExtra 和 Window 都无法实现 Dropover 那种效果
2. **不要在主线程做 IO**：缩略图生成、文件读取都要异步
3. **不要忘记权限**：辅助功能权限（全局事件监听需要）

### 6.2 权限配置 (Entitlements)

```xml
<!-- DropKit.entitlements -->
<key>com.apple.security.automation.apple-events</key>
<true/>
```

### 6.3 Info.plist 配置

```xml
<!-- 隐藏 Dock 图标，只显示菜单栏 -->
<key>LSUIElement</key>
<true/>
```

---

## 7. 参考资源

- [Dropover 官网](https://dropoverapp.com/)：功能参考
- [Apple HIG - Menu Bar](https://developer.apple.com/design/human-interface-guidelines/the-menu-bar)
- [NSPanel 文档](https://developer.apple.com/documentation/appkit/nspanel)
- [NSDraggingDestination](https://developer.apple.com/documentation/appkit/nsdraggingdestination)
