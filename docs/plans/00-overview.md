# DropKit v2 开发文档总览

> 创建日期：2026-01-29
> 版本：2.0.0

---

## 项目简介

**DropKit v2** 是一个功能强大的 macOS 菜单栏应用，提供悬浮窗和剪切板历史两大核心功能。

### 核心功能

1. **悬浮窗（Shelf）**
   - 拖拽文件时摇晃鼠标触发
   - 临时存放文件
   - 支持拖入拖出
   - 显示文件缩略图

2. **剪切板历史（Clipboard History）**
   - 自动记录复制内容
   - 支持文本、图片、文件、URL
   - 搜索和筛选功能
   - 数据持久化

### 技术栈

```
语言：Swift 5.9+
框架：SwiftUI + AppKit
系统：macOS 14.0+ (Sonoma)
架构：MVVM + 服务层
```

---

## 文档结构

本文档集包含以下部分：

### 开发阶段文档

1. **[Phase 1: MVP 悬浮窗](phase-1-mvp-shelf.md)** (1147 行)
   - 基础悬浮窗实现
   - 拖入拖出功能
   - 数据模型设计

2. **[Phase 2: 摇晃触发](phase-2-shake-trigger.md)** (1027 行)
   - 摇晃检测器
   - 拖拽监听器
   - 权限处理

3. **[Phase 3: 菜单栏](phase-3-menubar.md)** (744 行)
   - 菜单栏集成
   - 快捷键支持
   - 应用状态管理

4. **[Phase 4: 悬浮窗完善](phase-4-shelf-polish.md)** (804 行)
   - 缩略图生成
   - 动画效果
   - 多文件支持

5. **[Phase 5: 剪切板历史](phase-5-clipboard-history.md)** (1599 行)
   - 剪切板监听
   - 历史记录管理
   - UI 界面实现

6. **[Phase 6: 设置页](phase-6-settings.md)** (1691 行)
   - 设置数据模型
   - 通用设置
   - 悬浮窗设置
   - 剪切板设置

7. **[Phase 7: 收尾发布](phase-7-polish-release.md)** (1790 行)
   - 应用图标
   - 性能优化
   - 错误处理
   - 用户引导
   - 打包发布

### 辅助文档

8. **[附录：工具和技巧](appendix-tools-and-tips.md)** (909 行)
   - 工具详解
   - 常见问题
   - 调试技巧
   - 性能优化
   - 安全注意事项

---

## 技术架构

### 架构图

```
┌─────────────────────────────────────────────────────────┐
│                        DropKit v2                        │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │   MenuBar    │  │    Shelf     │  │  Clipboard   │ │
│  │   (菜单栏)    │  │   (悬浮窗)    │  │   (剪切板)    │ │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘ │
│         │                 │                  │          │
│         └─────────────────┼──────────────────┘          │
│                           │                             │
│                    ┌──────▼───────┐                     │
│                    │   AppState   │                     │
│                    │  (应用状态)   │                     │
│                    └──────┬───────┘                     │
│                           │                             │
│         ┌─────────────────┼─────────────────┐          │
│         │                 │                 │          │
│  ┌──────▼───────┐  ┌──────▼───────┐  ┌──────▼───────┐ │
│  │ShakeDetector │  │ DragMonitor  │  │ClipboardMon. │ │
│  │ (摇晃检测)    │  │ (拖拽监听)    │  │ (剪切板监听)  │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
│                                                          │
├─────────────────────────────────────────────────────────┤
│                      Services Layer                      │
│                       (服务层)                           │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │   Storage    │  │  Thumbnail   │  │    Error     │ │
│  │   (存储)      │  │  (缩略图)     │  │  (错误处理)   │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### 目录结构

```
DropKit/
├── Sources/
│   ├── App/
│   │   ├── DropKitApp.swift          # 应用入口
│   │   └── AppState.swift            # 应用状态管理
│   │
│   ├── Features/
│   │   ├── Shelf/                    # 悬浮窗功能
│   │   │   ├── ShelfPanel.swift
│   │   │   ├── ShelfView.swift
│   │   │   ├── ShelfViewModel.swift
│   │   │   └── ShelfItem.swift
│   │   │
│   │   ├── Clipboard/                # 剪切板功能
│   │   │   ├── ClipboardWindow.swift
│   │   │   ├── ClipboardHistoryView.swift
│   │   │   ├── ClipboardViewModel.swift
│   │   │   └── ClipboardItem.swift
│   │   │
│   │   ├── MenuBar/                  # 菜单栏
│   │   │   ├── MenuBarView.swift
│   │   │   └── MenuBarIconManager.swift
│   │   │
│   │   ├── Settings/                 # 设置页
│   │   │   ├── SettingsWindow.swift
│   │   │   ├── SettingsView.swift
│   │   │   └── SettingsViewModel.swift
│   │   │
│   │   └── Onboarding/               # 用户引导
│   │       └── OnboardingView.swift
│   │
│   ├── Services/                     # 服务层
│   │   ├── ShakeDetector.swift       # 摇晃检测
│   │   ├── DragMonitor.swift         # 拖拽监听
│   │   ├── ClipboardMonitor.swift    # 剪切板监听
│   │   └── ClipboardStorage.swift    # 剪切板存储
│   │
│   ├── Models/                       # 数据模型
│   │   └── Settings.swift
│   │
│   └── Utilities/                    # 工具类
│       ├── ThumbnailGenerator.swift  # 缩略图生成
│       ├── ErrorHandling.swift       # 错误处理
│       └── Extensions/               # 扩展
│
├── Assets.xcassets/                  # 资源文件
├── DropKit.entitlements              # 权限配置
└── Info.plist                        # 应用配置
```

---

## 开发流程

### 推荐开发顺序

```
Phase 1 (第 1-3 天)
    ↓
Phase 2 (第 4-6 天)
    ↓
Phase 3 (第 7 天)
    ↓
Phase 4 (第 7-9 天)
    ↓
Phase 5 (第 10-12 天)
    ↓
Phase 6 (第 13-15 天)
    ↓
Phase 7 (第 16-18 天)
    ↓
发布 🎉
```

### 每个 Phase 的标准流程

1. **阅读文档**
   - 理解目标和成功标准
   - 查看技术栈总览
   - 了解工具使用方法

2. **编写代码**
   - 按步骤逐个实现
   - 每个步骤包含完整代码
   - 遵循命名规范

3. **编译测试**
   - 使用 XcodeBuildMCP 编译
   - 测试功能是否正常
   - 修复编译错误

4. **Git 提交**
   - 每个步骤完成后提交
   - 使用规范的提交消息
   - 保持提交历史清晰

---

## 快速开始指南

### 环境准备

1. **系统要求**
   ```
   macOS 14.0+ (Sonoma)
   Xcode 15.0+
   Swift 5.9+
   ```

2. **安装工具**
   ```bash
   # 安装 Xcode Command Line Tools
   xcode-select --install
   
   # 安装 Homebrew（可选）
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

3. **克隆项目**
   ```bash
   git clone https://github.com/yourusername/dropkit.git
   cd dropkit
   ```

---

### 开始开发

#### 方式 1：使用 Claude Code（推荐）

```bash
# 1. 打开项目
cd "/Users/chenhuajin/Desktop/Dropkit v2 "

# 2. 阅读 Phase 1 文档
cat docs/plans/phase-1-mvp-shelf.md

# 3. 按照文档步骤开发
# 每个步骤都有完整的代码示例

# 4. 使用 XcodeBuildMCP 编译
mcp__xcodebuildmcp__build

# 5. 测试功能

# 6. Git 提交
git add .
git commit -m "feat: complete phase 1"
```

#### 方式 2：使用 Xcode

```bash
# 1. 打开项目
open DropKit.xcodeproj

# 2. 选择 DropKit scheme

# 3. 按照文档步骤开发

# 4. 编译运行（⌘R）

# 5. 测试功能

# 6. Git 提交
```

---

### 开发建议

1. **按顺序开发**
   - 严格按照 Phase 1 → Phase 7 的顺序
   - 不要跳过任何步骤
   - 每个 Phase 完成后再进入下一个

2. **小步迭代**
   - 每次只实现一个步骤
   - 实现后立即编译测试
   - 测试通过后再继续

3. **遇到问题**
   - 先查看附录的常见问题
   - 使用 Axiom skill 寻求帮助
   - 查看 Phase 文档的调试部分

4. **代码质量**
   - 遵循命名规范
   - 保持代码简洁
   - 添加必要注释

---

## 核心概念

### 1. 悬浮窗（Shelf）

**触发机制**：
```
用户拖拽文件
    ↓
DragMonitor 检测到拖拽
    ↓
用户摇晃鼠标
    ↓
ShakeDetector 检测到摇晃
    ↓
显示 ShelfPanel
```

**关键点**：
- 使用 NSPanel 而非 NSWindow
- level 设置为 .floating
- 拖入：NSDraggingDestination
- 拖出：NSDraggingSource

---

### 2. 摇晃检测（Shake Detection）

**检测原理**：
```
监听全局鼠标移动
    ↓
记录 X 坐标变化方向
    ↓
短时间内方向反转 >= 3 次
    ↓
触发摇晃事件
```

**关键点**：
- 需要辅助功能权限
- 只在拖拽时检测
- 可调节灵敏度

---

### 3. 剪切板历史（Clipboard History）

**监听机制**：
```
定时检查 NSPasteboard.changeCount
    ↓
检测到变化
    ↓
读取剪切板内容
    ↓
保存到历史记录
```

**关键点**：
- 使用 Timer 定时检查
- 支持多种内容类型
- 数据持久化到文件

---

### 4. 权限管理

**辅助功能权限**：
```swift
// 检查权限
let hasPermission = AXIsProcessTrusted()

// 请求权限
let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
AXIsProcessTrustedWithOptions(options as CFDictionary)
```

**为什么需要**：
- 全局事件监听需要此权限
- 没有权限时监听器不工作
- 必须在首次启动时引导用户授权

---

## 关键技术点

### SwiftUI + AppKit 混合

**原则**：
- UI 使用 SwiftUI
- 窗口容器使用 AppKit
- 全局事件使用 AppKit

**示例**：
```swift
// AppKit 窗口
class ShelfPanel: NSPanel {
    init() {
        super.init(...)
        
        // SwiftUI 内容
        let contentView = ShelfView(viewModel: viewModel)
        self.contentView = NSHostingView(rootView: contentView)
    }
}
```

---

### 异步处理

**原则**：
- 耗时操作使用 async/await
- UI 更新在主线程
- 避免阻塞主线程

**示例**：
```swift
// 后台生成缩略图
func loadThumbnail() async {
    let thumbnail = await ThumbnailGenerator.generate(for: url)
    
    // 主线程更新 UI
    await MainActor.run {
        self.thumbnail = thumbnail
    }
}
```

---

### 状态管理

**架构**：
```
AppState (全局状态)
    ↓
各个 ViewModel (功能状态)
    ↓
SwiftUI View (UI)
```

**示例**：
```swift
@MainActor
class AppState: ObservableObject {
    let shelfViewModel: ShelfViewModel
    let clipboardViewModel: ClipboardViewModel
    let settingsViewModel: SettingsViewModel
    
    // 协调各个功能
}
```

---

## 常见陷阱

### 1. 拖拽内容获取

❌ **错误方式**：
```swift
// 在 DragMonitor 中读取 NSPasteboard.general
let pasteboard = NSPasteboard.general
let urls = pasteboard.readObjects(forClasses: [NSURL.self])
// 这样会拿到上一次复制的内容！
```

✅ **正确方式**：
```swift
// 在 performDragOperation 中读取 draggingPasteboard
func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
    let pasteboard = sender.draggingPasteboard
    let urls = pasteboard.readObjects(forClasses: [NSURL.self])
    // 这样才能拿到正在拖拽的内容
}
```

---

### 2. 权限检测

❌ **错误方式**：
```swift
// 假设有权限，直接使用
NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDragged) { event in
    // 没有权限时这个回调永远不会触发！
}
```

✅ **正确方式**：
```swift
// 先检查权限
if AXIsProcessTrusted() {
    NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDragged) { event in
        // 处理事件
    }
} else {
    // 请求权限
    requestPermission()
}
```

---

### 3. 窗口层级

❌ **错误方式**：
```swift
// 使用默认 level
let panel = NSPanel(...)
// 窗口会被其他窗口遮挡
```

✅ **正确方式**：
```swift
// 设置为 floating level
let panel = NSPanel(...)
panel.level = .floating
panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
// 窗口浮在所有窗口之上
```

---

### 4. 内存管理

❌ **错误方式**：
```swift
// 循环引用
class ViewModel {
    var closure: (() -> Void)?
    
    init() {
        closure = {
            self.doSomething()  // 强引用 self
        }
    }
}
```

✅ **正确方式**：
```swift
// 使用 weak self
class ViewModel {
    var closure: (() -> Void)?
    
    init() {
        closure = { [weak self] in
            self?.doSomething()
        }
    }
}
```

---

## 测试指南

### 功能测试

**悬浮窗测试**：
```
1. 拖拽一个文件
2. 在拖拽过程中快速左右摇晃鼠标
3. 悬浮窗应该出现在鼠标附近
4. 将文件拖入悬浮窗
5. 文件应该显示在悬浮窗中
6. 从悬浮窗拖出文件
7. 文件应该可以拖到其他位置
```

**剪切板测试**：
```
1. 复制一段文本（⌘C）
2. 按 ⌘⇧V 打开剪切板历史
3. 历史窗口应该显示刚才复制的文本
4. 双击该文本
5. 文本应该被复制到剪切板
```

**设置测试**：
```
1. 按 ⌘, 打开设置
2. 调整摇晃灵敏度
3. 关闭设置窗口
4. 测试摇晃触发是否按新灵敏度工作
```

---

### 性能测试

**启动时间**：
```bash
# 测量启动时间
time open -a DropKit

# 目标：< 1 秒
```

**内存占用**：
```bash
# 查看内存占用
ps aux | grep DropKit

# 目标：< 100MB
```

**CPU 占用**：
```bash
# 查看 CPU 占用
top -pid $(pgrep DropKit)

# 目标：空闲时 < 1%
```

---

## 发布清单

### 发布前检查

- [ ] 所有功能测试通过
- [ ] 性能测试达标
- [ ] 无内存泄漏
- [ ] 无编译警告
- [ ] 代码已审查
- [ ] 文档已更新
- [ ] 版本号已更新
- [ ] Git 标签已创建

### 打包步骤

1. **编译 Release 版本**
   ```bash
   xcodebuild -scheme DropKit -configuration Release archive
   ```

2. **签名和公证**
   ```bash
   codesign --sign "Developer ID" DropKit.app
   xcrun notarytool submit DropKit.zip
   ```

3. **创建 DMG**
   ```bash
   create-dmg DropKit.app
   ```

4. **发布到 GitHub**
   ```bash
   gh release create v2.0.0 DropKit.dmg
   ```

---

## 学习资源

### 官方文档

- [Swift 官方文档](https://swift.org/documentation/)
- [SwiftUI 教程](https://developer.apple.com/tutorials/swiftui)
- [AppKit 文档](https://developer.apple.com/documentation/appkit)

### 推荐阅读

- Phase 文档：按顺序阅读 Phase 1-7
- 附录文档：查看工具使用和最佳实践
- CLAUDE.md：了解项目规则和约定

### 获取帮助

- 查看附录的常见问题
- 使用 Axiom skill
- 查看 Phase 文档的调试部分
- GitHub Issues

---

## 贡献指南

### 提交代码

1. **Fork 项目**
2. **创建分支**
   ```bash
   git checkout -b feature/your-feature
   ```

3. **编写代码**
   - 遵循代码规范
   - 添加必要测试
   - 更新文档

4. **提交代码**
   ```bash
   git commit -m "feat: add your feature"
   ```

5. **推送分支**
   ```bash
   git push origin feature/your-feature
   ```

6. **创建 Pull Request**

### 代码规范

- 遵循 Swift 官方风格指南
- 使用 SwiftLint 检查代码
- 保持代码简洁清晰
- 添加必要注释

---

## 版本历史

### v2.0.0 (2026-01-29)

**新功能**：
- ✨ 悬浮窗功能
- ✨ 剪切板历史
- ✨ 设置页面
- ✨ 用户引导

**改进**：
- 🚀 性能优化
- 🎨 UI 美化
- 🌙 深色模式支持

**修复**：
- 🐛 修复多显示器问题
- 🐛 修复内存泄漏
- 🐛 修复权限检测

---

## 许可证

MIT License

Copyright (c) 2026 DropKit

---

## 联系方式

- GitHub: https://github.com/yourusername/dropkit
- Issues: https://github.com/yourusername/dropkit/issues
- Email: your@email.com

---

**开始你的 DropKit v2 开发之旅吧！** 🚀

