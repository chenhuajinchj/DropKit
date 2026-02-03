import SwiftUI
import AppKit

struct AppPickerView: View {
    @Binding var selectedBundleIds: Set<String>
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var apps: [AppInfo] = []

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("选择应用")
                    .font(.headline)
                Spacer()
                Button("完成") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()

            Divider()

            // 搜索框
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("搜索应用...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.primary.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding()

            Divider()

            // 应用列表
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(filteredApps) { app in
                        AppRow(
                            app: app,
                            isSelected: selectedBundleIds.contains(app.bundleId),
                            onToggle: {
                                if selectedBundleIds.contains(app.bundleId) {
                                    selectedBundleIds.remove(app.bundleId)
                                } else {
                                    selectedBundleIds.insert(app.bundleId)
                                }
                            }
                        )
                    }
                }
                .padding(8)
            }
        }
        .frame(width: 400, height: 500)
        .onAppear {
            loadApps()
        }
    }

    private var filteredApps: [AppInfo] {
        if searchText.isEmpty {
            return apps
        }
        return apps.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private func loadApps() {
        var result: [AppInfo] = []
        let fileManager = FileManager.default

        // 扫描 /Applications 目录
        let applicationsPaths = [
            "/Applications",
            "/System/Applications",
            NSHomeDirectory() + "/Applications"
        ]

        for path in applicationsPaths {
            guard let contents = try? fileManager.contentsOfDirectory(atPath: path) else { continue }

            for item in contents where item.hasSuffix(".app") {
                let appPath = (path as NSString).appendingPathComponent(item)
                let appURL = URL(fileURLWithPath: appPath)

                if let bundle = Bundle(url: appURL),
                   let bundleId = bundle.bundleIdentifier {
                    let name = fileManager.displayName(atPath: appPath)
                    let icon = NSWorkspace.shared.icon(forFile: appPath)
                    result.append(AppInfo(name: name, bundleId: bundleId, icon: icon))
                }
            }
        }

        // 按名称排序
        apps = result.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}

struct AppInfo: Identifiable {
    let id = UUID()
    let name: String
    let bundleId: String
    let icon: NSImage
}

struct AppRow: View {
    let app: AppInfo
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button {
            onToggle()
        } label: {
            HStack(spacing: 12) {
                Image(nsImage: app.icon)
                    .resizable()
                    .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(app.name)
                        .font(.system(size: 13))
                        .foregroundStyle(.primary)
                    Text(app.bundleId)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.system(size: 18))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}
