# DropKit

> [English](#english) | [中文](#中文)

---

## 中文

一款轻量级 macOS 菜单栏工具，用于快速文件暂存和剪贴板历史管理。

### 功能特性

#### 文件暂存架 (Shelf)
- 拖拽文件时摇晃鼠标，即可唤出悬浮暂存架
- 临时存放文件，随时拖出使用
- 支持宫格和列表两种视图模式

#### 剪贴板历史
- 自动监控剪贴板变化
- 支持文本、图片、文件和链接
- 搜索和置顶功能
- 隐私模式（暂停监控）
- 按空格键快速预览内容

#### 菜单栏集成
- 菜单栏快速访问
- 全局键盘快捷键
- 资源占用极低

### 系统要求

- macOS 14.0 (Sonoma) 或更高版本
- 辅助功能权限（用于检测鼠标摇晃手势）

### 安装说明

#### 分发状态

DropKit 正在迁移到 Mac App Store 分发。

- `GitHub` 保留为源码仓库、Issue、PR 和文档协作平台
- 面向终端用户的安装与更新将迁移到 `Mac App Store`
- 在商店版本发布前，建议开发者通过源码构建进行评估和调试

#### 授予辅助功能权限

DropKit 需要辅助功能权限来检测鼠标摇晃手势：

1. 打开 **系统设置 → 隐私与安全性 → 辅助功能**
2. 点击锁图标并验证身份
3. 在列表中启用 DropKit
4. 重启 DropKit 使更改生效

### 使用方法

#### 暂存架
- **唤出**：拖拽文件时左右摇晃鼠标
- **添加文件**：将文件拖放到暂存架上
- **使用文件**：从暂存架拖出文件到任意位置
- **展开视图**：点击展开按钮查看所有文件

#### 剪贴板历史
- **打开**：点击菜单栏图标 →「剪贴板历史」或按 `⌘⇧V`
- **粘贴项目**：点击任意项目或按回车键
- **搜索**：输入文字筛选项目
- **预览**：按空格键预览选中项目
- **置顶项目**：右键 → 置顶
- **删除项目**：右键 → 删除

#### 快捷键

| 操作 | 快捷键 |
|------|--------|
| 打开剪贴板历史 | `⌘⇧V` |
| 切换暂存架 | `⌘⇧S` |
| 打开设置 | `⌘,` |
| 退出 | `⌘Q` |

### 从源码构建

```bash
git clone https://github.com/chenhuajinchj/DropKit.git
cd DropKit/DropKit
xcodebuild -scheme DropKit -configuration Release build
```

### 许可证

MIT License - 详见 [LICENSE](LICENSE)

---

## English

A lightweight macOS menu bar utility for quick file staging and clipboard history management.

### Features

#### Shelf (File Staging)
- Shake your mouse while dragging files to summon a floating shelf
- Drop files temporarily for quick access
- Drag files out to any destination
- Grid and list view modes

#### Clipboard History
- Automatic clipboard monitoring
- Support for text, images, files, and URLs
- Search through clipboard history
- Pin important items
- Privacy mode to pause monitoring
- Press Space to preview content

#### Menu Bar Integration
- Quick access from menu bar
- Keyboard shortcuts for all features
- Minimal resource usage

### System Requirements

- macOS 14.0 (Sonoma) or later
- Accessibility permission (for mouse shake detection)

### Installation

#### Distribution Status

DropKit is being prepared for Mac App Store distribution.

- `GitHub` remains the source repository for code, issues, pull requests, and documentation
- End-user installation and updates are intended to move to the `Mac App Store`
- Until the store version is available, developers should build the app from source for evaluation

#### Grant Accessibility Permission

DropKit needs accessibility permission to detect mouse shake gestures:

1. Open **System Settings → Privacy & Security → Accessibility**
2. Click the lock icon and authenticate
3. Enable DropKit in the list
4. Restart DropKit for changes to take effect

### Usage

#### Shelf
- **Summon**: Shake your mouse left-right while dragging a file
- **Add files**: Drop files onto the shelf
- **Use files**: Drag files out of the shelf to any destination
- **Expand view**: Click the expand button to see all files

#### Clipboard History
- **Open**: Click menu bar icon → "Clipboard History" or press `⌘⇧V`
- **Paste item**: Click on any item or press Enter
- **Search**: Type to filter items
- **Preview**: Press Space to preview selected item
- **Pin item**: Right-click → Pin
- **Delete item**: Right-click → Delete

#### Keyboard Shortcuts

| Action | Shortcut |
|--------|----------|
| Open Clipboard History | `⌘⇧V` |
| Toggle Shelf | `⌘⇧S` |
| Open Settings | `⌘,` |
| Quit | `⌘Q` |

### Building from Source

```bash
git clone https://github.com/chenhuajinchj/DropKit.git
cd DropKit/DropKit
xcodebuild -scheme DropKit -configuration Release build
```

### License

MIT License - see [LICENSE](LICENSE) for details.
