# DropKit

A lightweight macOS menu bar utility for quick file staging and clipboard history management.

## Features

### Shelf (File Staging)
- Shake your mouse while dragging files to summon a floating shelf
- Drop files temporarily for quick access
- Drag files out to any destination
- Grid and list view modes
- Quick Look preview support

### Clipboard History
- Automatic clipboard monitoring
- Support for text, images, files, and URLs
- Search through clipboard history
- Pin important items
- Privacy mode to pause monitoring

### Menu Bar Integration
- Quick access from menu bar
- Keyboard shortcuts for all features
- Minimal resource usage

## System Requirements

- macOS 14.0 (Sonoma) or later
- Accessibility permission (for mouse shake detection)

## Installation

### Download

Download the latest release from [GitHub Releases](https://github.com/user/dropkit/releases).

### Installing Unsigned App

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

### Grant Accessibility Permission

DropKit needs accessibility permission to detect mouse shake gestures:

1. Open **System Settings → Privacy & Security → Accessibility**
2. Click the lock icon and authenticate
3. Enable DropKit in the list
4. Restart DropKit for changes to take effect

## Usage

### Shelf
- **Summon**: Shake your mouse left-right while dragging a file
- **Add files**: Drop files onto the shelf
- **Use files**: Drag files out of the shelf to any destination
- **Expand view**: Click the expand button to see all files
- **Quick Look**: Press Space to preview selected file

### Clipboard History
- **Open**: Click menu bar icon → "Clipboard History" or press `⌘⇧V`
- **Paste item**: Click on any item or press Enter
- **Search**: Type to filter items
- **Pin item**: Right-click → Pin
- **Delete item**: Right-click → Delete

### Keyboard Shortcuts

| Action | Shortcut |
|--------|----------|
| Open Clipboard History | `⌘⇧V` |
| Toggle Shelf | `⌘⇧S` |
| Open Settings | `⌘,` |
| Quit | `⌘Q` |

## Building from Source

```bash
git clone https://github.com/user/dropkit.git
cd dropkit/DropKit
xcodebuild -scheme DropKit -configuration Release build
```

## License

MIT License - see [LICENSE](LICENSE) for details.
