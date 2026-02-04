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
- 支持 Quick Look 快速预览

#### 剪贴板历史
- 自动监控剪贴板变化
- 支持文本、图片、文件和链接
- 搜索和置顶功能
- 隐私模式（暂停监控）

#### 菜单栏集成
- 菜单栏快速访问
- 全局键盘快捷键
- 资源占用极低

### 系统要求

- macOS 14.0 (Sonoma) 或更高版本
- 辅助功能权限（用于检测鼠标摇晃手势）

### 安装说明

#### 下载

从 [GitHub Releases](https://github.com/chenhuajinchj/DropKit/releases) 下载最新版本。

#### 安装未签名应用

由于 DropKit 未使用 Apple 开发者证书签名，macOS 会显示安全警告。安装方法如下：

**方法一：右键打开**
1. 下载 `DropKit-x.x.x.dmg` 或 `DropKit-x.x.x.zip`
2. 如果是 DMG，打开后将 DropKit 拖到「应用程序」文件夹
3. 如果是 ZIP，解压后将 DropKit.app 移动到「应用程序」文件夹
4. **右键点击** DropKit.app
5. 选择「打开」
6. 在弹出的对话框中点击「打开」

**方法二：系统设置**
1. 尝试正常打开 DropKit（会被阻止）
2. 打开 **系统设置 → 隐私与安全性**
3. 向下滚动找到关于 DropKit 被阻止的提示
4. 点击「仍要打开」

**方法三：终端命令（如果上述方法无效）**
```bash
xattr -cr /Applications/DropKit.app
```

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
- **快速预览**：按空格键预览选中的文件

#### 剪贴板历史
- **打开**：点击菜单栏图标 →「剪贴板历史」或按 `⌘⇧V`
- **粘贴项目**：点击任意项目或按回车键
- **搜索**：输入文字筛选项目
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
- Quick Look preview support

#### Clipboard History
- Automatic clipboard monitoring
- Support for text, images, files, and URLs
- Search through clipboard history
- Pin important items
- Privacy mode to pause monitoring

#### Menu Bar Integration
- Quick access from menu bar
- Keyboard shortcuts for all features
- Minimal resource usage

### System Requirements

- macOS 14.0 (Sonoma) or later
- Accessibility permission (for mouse shake detection)

### Installation

#### Download

Download the latest release from [GitHub Releases](https://github.com/chenhuajinchj/DropKit/releases).

#### Installing Unsigned App

Since DropKit is not signed with an Apple Developer certificate, macOS will show a security warning. Here's how to install:

**Method 1: Right-click to Open**
1. Download `DropKit-x.x.x.dmg` or `DropKit-x.x.x.zip`
2. If using DMG, open it and drag DropKit to Applications
3. If using ZIP, extract and move DropKit.app to Applications
4. **Right-click** (or Control-click) on DropKit.app
5. Select "Open" from the context menu
6. Click "Open" in the dialog that appears

**Method 2: System Settings**
1. Try to open DropKit normally (it will be blocked)
2. Go to **System Settings → Privacy & Security**
3. Scroll down to find the message about DropKit being blocked
4. Click "Open Anyway"

**Method 3: Terminal (if above methods fail)**
```bash
xattr -cr /Applications/DropKit.app
```

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
- **Quick Look**: Press Space to preview selected file

#### Clipboard History
- **Open**: Click menu bar icon → "Clipboard History" or press `⌘⇧V`
- **Paste item**: Click on any item or press Enter
- **Search**: Type to filter items
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
