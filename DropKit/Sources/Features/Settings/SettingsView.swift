import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    @Bindable var settings = AppSettings.shared
    @State private var showDeleteConfirmation = false
    @State private var showDeleteSuccess = false
    @State private var showFolderPicker = false
    @State private var showAppPicker = false
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            // 自定义 Tab 选择器
            Picker("", selection: $selectedTab) {
                Text("通用").tag(0)
                Text("悬浮窗").tag(1)
                Text("剪切板").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 80)
            .padding(.top, 12)
            .padding(.bottom, 8)

            // Tab 内容
            Group {
                switch selectedTab {
                case 0:
                    generalTab
                case 1:
                    shelfTab
                case 2:
                    clipboardTab
                default:
                    generalTab
                }
            }
        }
        .frame(width: 420, height: 400)
        .background(.background)
    }

    // MARK: - 通用设置（合并原通用 + 快捷键）

    private var generalTab: some View {
        Form {
            Section {
                Toggle("开机自启动", isOn: $settings.launchAtLogin)
            } header: {
                Text("启动")
            }

            Section {
                LabeledContent("显示悬浮窗") {
                    KeyboardShortcuts.Recorder(for: .showShelf)
                }
                LabeledContent("剪切板历史") {
                    KeyboardShortcuts.Recorder(for: .showClipboardHistory)
                }
                LabeledContent("设置") {
                    KeyboardShortcuts.Recorder(for: .showSettings)
                }
            } header: {
                Text("快捷键")
            }

            Section {
                LabeledContent("当前版本") {
                    Text(UpdateChecker.shared.currentVersion)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Button("检查更新") {
                        Task { await UpdateChecker.shared.checkForUpdates() }
                    }
                    .disabled(UpdateChecker.shared.state == .checking)

                    Spacer()

                    updateStatusView
                }

                Toggle("启动时自动检查", isOn: $settings.autoCheckUpdates)
            } header: {
                Text("关于")
            }
        }
        .formStyle(.grouped)
    }

    @ViewBuilder
    private var updateStatusView: some View {
        switch UpdateChecker.shared.state {
        case .checking:
            ProgressView()
                .scaleEffect(0.7)
        case .upToDate:
            Label("已是最新", systemImage: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.caption)
        case .available(let version, _, _):
            Button("v\(version) 可用") {
                UpdateChecker.shared.openDownloadPage()
            }
            .foregroundColor(.orange)
        case .failed(let msg):
            Text(msg)
                .foregroundColor(.red)
                .font(.caption)
        case .idle:
            EmptyView()
        }
    }

    // MARK: - 悬浮窗设置（合并原摇晃触发 + 文件夹监听）

    private var shelfTab: some View {
        Form {
            Section {
                LabeledContent("摇晃次数") {
                    Stepper("\(settings.shakeMinShakes) 次", value: $settings.shakeMinShakes, in: 2...8)
                        .frame(width: 100)
                }

                LabeledContent("时间窗口") {
                    HStack {
                        Slider(value: $settings.shakeTimeWindow, in: 0.2...0.8, step: 0.05)
                            .frame(width: 120)
                        Text("\(String(format: "%.2f", settings.shakeTimeWindow)) 秒")
                            .monospacedDigit()
                            .frame(width: 55, alignment: .trailing)
                    }
                }

                LabeledContent("最小移动") {
                    HStack {
                        Slider(value: $settings.shakeMinMovement, in: 10...60, step: 5)
                            .frame(width: 120)
                        Text("\(Int(settings.shakeMinMovement)) 像素")
                            .monospacedDigit()
                            .frame(width: 55, alignment: .trailing)
                    }
                }
            } header: {
                Text("摇晃触发")
            }

            Section {
                Toggle("启用文件夹监听", isOn: $settings.folderMonitorEnabled)

                LabeledContent("文件夹") {
                    HStack {
                        Text(settings.watchedFolderPath ?? "未选择")
                            .foregroundColor(settings.watchedFolderPath == nil ? .secondary : .primary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .frame(maxWidth: 150, alignment: .leading)
                        Button("选择...") {
                            selectFolder()
                        }
                    }
                }

                Button("使用 macOS 截图文件夹") {
                    if let path = FolderMonitor.getScreenshotFolderPath() {
                        settings.watchedFolderPath = path
                    }
                }
            } header: {
                Text("文件夹监听")
            }

            Section {
                Toggle("自动复制到剪切板", isOn: $settings.autoCopyToClipboard)
                Toggle("自动显示悬浮窗", isOn: $settings.autoShowShelfOnNewFile)
            } header: {
                Text("新文件行为")
            } footer: {
                Text("新文件出现时自动复制路径，可直接 Cmd+V 粘贴")
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - 剪切板设置（保持不变）

    private var clipboardTab: some View {
        Form {
            Section {
                LabeledContent("保留时长") {
                    HStack(spacing: 4) {
                        TextField("", value: $settings.clipboardRetentionDays, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 60)
                            .multilineTextAlignment(.center)
                        Text("天")
                    }
                }

                LabeledContent("最大条数") {
                    HStack(spacing: 4) {
                        TextField("", value: $settings.clipboardMaxItems, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 60)
                            .multilineTextAlignment(.center)
                        Text("条")
                    }
                }
            } header: {
                Text("历史记录")
            } footer: {
                Text("输入 0 表示永久保留，仅统计和删除未收藏条目")
            }

            Section {
                Toggle("忽略密码管理器内容", isOn: $settings.ignoreConcealed)
            } footer: {
                Text("自动跳过来自 1Password、LastPass 等的复制内容")
            }

            Section {
                Toggle("启用应用黑名单", isOn: $settings.clipboardBlacklistEnabled)

                if settings.clipboardBlacklistEnabled {
                    ForEach(Array(settings.clipboardBlacklist).sorted(), id: \.self) { bundleId in
                        HStack {
                            Text(getAppName(for: bundleId) ?? bundleId)
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

                    Button("添加应用...") {
                        showAppPicker = true
                    }
                }
            } footer: {
                Text("忽略来自指定应用的剪切板内容")
            }

            Section {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    HStack {
                        Spacer()
                        Label("删除所有历史记录", systemImage: "trash")
                        Spacer()
                    }
                }

                if showDeleteSuccess {
                    HStack {
                        Spacer()
                        Text("已删除所有历史记录")
                            .foregroundColor(.green)
                        Spacer()
                    }
                }
            }
        }
        .formStyle(.grouped)
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
