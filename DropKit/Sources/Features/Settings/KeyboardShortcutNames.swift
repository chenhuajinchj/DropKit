import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let showShelf = Self("showShelf", default: .init(.s, modifiers: [.command, .shift]))
    static let showClipboardHistory = Self("showClipboardHistory", default: .init(.v, modifiers: [.command, .shift]))
    static let showSettings = Self("showSettings", default: .init(.comma, modifiers: [.command]))
}
