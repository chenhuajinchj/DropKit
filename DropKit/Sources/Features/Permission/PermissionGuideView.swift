import SwiftUI

/// 权限引导视图
struct PermissionGuideView: View {
    @State private var hasPermission = false
    @State private var currentStep: GuideStep = .welcome
    var onPermissionGranted: (() -> Void)?

    enum GuideStep {
        case welcome
        case permission
    }

    var body: some View {
        Group {
            switch currentStep {
            case .welcome:
                welcomeView
            case .permission:
                permissionView
            }
        }
        .animation(.easeInOut, value: currentStep)
    }

    // MARK: - Welcome View

    private var welcomeView: some View {
        VStack(spacing: 24) {
            Image(systemName: "tray.fill")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)

            Text("欢迎使用 DropKit")
                .font(.title)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 16) {
                featureRow(icon: "hand.draw", title: "摇晃触发", description: "拖拽文件时摇晃鼠标，快速打开悬浮窗")
                featureRow(icon: "tray.and.arrow.down", title: "临时存放", description: "将文件拖入悬浮窗暂存，随时拖出使用")
                featureRow(icon: "clipboard", title: "剪切板历史", description: "自动记录复制内容，一键快速粘贴")
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Button(action: {
                currentStep = .permission
            }) {
                Text("开始设置")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
        .padding(32)
        .frame(width: 450)
    }

    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Permission View

    private var permissionView: some View {
        VStack(spacing: 24) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)

            Text("需要辅助功能权限")
                .font(.title)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 12) {
                Text("DropKit 需要辅助功能权限来检测鼠标摇晃手势。")
                    .font(.body)

                Text("具体步骤：")
                    .font(.headline)
                    .padding(.top, 8)

                VStack(alignment: .leading, spacing: 8) {
                    stepRow(number: "1", text: "点击下方按钮打开系统设置")
                    stepRow(number: "2", text: "在「隐私与安全」→「辅助功能」中找到 DropKit")
                    stepRow(number: "3", text: "勾选 DropKit 旁边的复选框")
                    stepRow(number: "4", text: "返回应用，点击「重新检查」按钮")
                }
                .font(.callout)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(spacing: 12) {
                Button(action: {
                    PermissionChecker.openAccessibilitySettings()
                }) {
                    Text("打开系统设置")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)

                Button(action: {
                    checkPermission()
                }) {
                    Text("重新检查权限")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.secondary.opacity(0.2))
                        .foregroundColor(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)

                if hasPermission {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("权限已授予")
                            .foregroundColor(.green)
                            .font(.headline)
                    }
                }
            }
        }
        .padding(32)
        .frame(width: 450)
        .onAppear {
            checkPermission()
        }
    }

    private func stepRow(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(number).")
                .fontWeight(.medium)
            Text(text)
        }
    }

    private func checkPermission() {
        hasPermission = PermissionChecker.checkAccessibilityPermission()
        if hasPermission {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                onPermissionGranted?()
            }
        }
    }
}

#Preview {
    PermissionGuideView()
}
