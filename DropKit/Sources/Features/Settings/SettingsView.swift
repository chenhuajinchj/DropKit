import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    @Bindable var settings = AppSettings.shared
    @State private var showDeleteConfirmation = false
    @State private var showDeleteSuccess = false
    @State private var showFolderPicker = false
    @State private var showAppPicker = false

    var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label("通用", systemImage: "gear")
                }

            shakeTab
                .tabItem {
                    Label("摇晃触发", systemImage: "hand.draw")
                }

            clipboardTab
                .tabItem {
                    Label("剪切板", systemImage: "clipboard")
                }

            shortcutsTab
                .tabItem {
                    Label("快捷键", systemImage: "keyboard")
                }

            folderMonitorTab
                .tabItem {
                    Label("文件夹监听", systemImage: "folder.badge.gearshape")
                }
        }
        .frame(width: 420, height: 420)
    }

    private var generalTab: some View {
        Form {
            Toggle("开机自启动", isOn: $settings.launchAtLogin)
        }
        .padding()
    }

    private var shakeTab: some View {
        Form {
            Stepper("摇晃次数: \(settings.shakeMinShakes)", value: $settings.shakeMinShakes, in: 2...8)

            HStack {
                Text("时间窗口: \(String(format: "%.2f", settings.shakeTimeWindow))秒")
                Slider(value: $settings.shakeTimeWindow, in: 0.2...0.8, step: 0.05)
            }

            HStack {
                Text("最小移动: \(Int(settings.shakeMinMovement))像素")
                Slider(value: $settings.shakeMinMovement, in: 10...60, step: 5)
            }
        }
        .padding()
    }

    private var clipboardTab: some View {
        Form {
            // 保留时长
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("保留时长")
                    Spacer()
                    TextField("", value: $settings.clipboardRetentionDays, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                        .multilineTextAlignment(.center)
                    Text("天")
                }
                Text("输入 0 表示永久保留，仅统计和删除未收藏条目")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            // 最大保留条数
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("最大保留条数")
                    Spacer()
                    TextField("", value: $settings.clipboardMaxItems, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                        .multilineTextAlignment(.center)
                    Text("条")
                }
                Text("输入 0 表示永久保留，仅统计和删除未收藏条目")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            // 忽略密码管理器内容
            VStack(alignment: .leading, spacing: 4) {
                Toggle("忽略密码管理器内容", isOn: $settings.ignoreConcealed)
                Text("自动跳过来自 1Password、LastPass 等的复制内容")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            // 应用黑名单
            VStack(alignment: .leading, spacing: 8) {
                Toggle("启用应用黑名单", isOn: $settings.clipboardBlacklistEnabled)
                Text("忽略来自指定应用的剪切板内容")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if settings.clipboardBlacklistEnabled && !settings.clipboardBlacklist.isEmpty {
                    ForEach(Array(settings.clipboardBlacklist).sorted(), id: \.self) { bundleId in
                        HStack {
                            if let appName = getAppName(for: bundleId) {
                                Text(appName)
                                    .font(.callout)
                            } else {
                                Text(bundleId)
                                    .font(.callout)
                            }
                            Spacer()
                            Button {
                                settings.clipboardBlacklist.remove(bundleId)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if settings.clipboardBlacklistEnabled {
                    Button("添加应用...") {
                        showAppPicker = true
                    }
                }
            }

            Divider()

            // 删除历史记录按钮
            HStack {
                Spacer()
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("删除历史记录")
                    }
                }
                .buttonStyle(.bordered)
                Spacer()
            }

            if showDeleteSuccess {
                HStack {
                    Spacer()
                    Text("已删除所有历史记录")
                        .font(.caption)
                        .foregroundColor(.green)
                    Spacer()
                }
            }
        }
        .padding()
        .alert("确认删除", isPresented: $showDeleteConfirmation) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                ClipboardMonitor.shared.clearAll()
                showDeleteSuccess = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showDeleteSuccess = false
                }
            }
        } message: {
            Text("确定要删除所有剪切板历史记录吗？此操作无法撤销。")
        }
        .sheet(isPresented: $showAppPicker) {
            AppPickerView(selectedBundleIds: $settings.clipboardBlacklist)
        }
    }

    private func getAppName(for bundleId: String) -> String? {
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            return FileManager.default.displayName(atPath: appURL.path)
        }
        return nil
    }

    private var shortcutsTab: some View {
        Form {
            KeyboardShortcuts.Recorder("显示悬浮窗:", name: .showShelf)
            KeyboardShortcuts.Recorder("剪切板历史:", name: .showClipboardHistory)
            KeyboardShortcuts.Recorder("设置:", name: .showSettings)
        }
        .padding()
    }

    private var folderMonitorTab: some View {
        Form {
            // 启用开关
            Toggle("启用文件夹监听", isOn: $settings.folderMonitorEnabled)

            Divider()

            // 文件夹路径
            VStack(alignment: .leading, spacing: 8) {
                Text("监听文件夹")
                    .font(.headline)

                HStack {
                    TextField("选择文件夹...", text: Binding(
                        get: { settings.watchedFolderPath ?? "" },
                        set: { settings.watchedFolderPath = $0.isEmpty ? nil : $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .disabled(true)

                    Button("选择...") {
                        selectFolder()
                    }
                }

                Button("使用 macOS 截图文件夹") {
                    if let path = FolderMonitor.getScreenshotFolderPath() {
                        settings.watchedFolderPath = path
                    }
                }
                .font(.caption)
            }

            Divider()

            // 行为选项
            VStack(alignment: .leading, spacing: 8) {
                Text("新文件行为")
                    .font(.headline)

                Toggle("自动复制到剪切板", isOn: $settings.autoCopyToClipboard)
                Text("新文件出现时自动复制路径，可直接 Cmd+V 粘贴")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Toggle("自动显示悬浮窗", isOn: $settings.autoShowShelfOnNewFile)
            }
        }
        .padding()
    }

    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "选择要监听的文件夹"

        if panel.runModal() == .OK, let url = panel.url {
            settings.watchedFolderPath = url.path
        }
    }
}
