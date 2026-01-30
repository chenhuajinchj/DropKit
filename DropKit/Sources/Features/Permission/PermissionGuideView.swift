import SwiftUI

/// 权限引导视图
struct PermissionGuideView: View {
    @State private var hasPermission = false
    var onPermissionGranted: (() -> Void)?

    var body: some View {
        VStack(spacing: 24) {
            // 图标
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)

            // 标题
            Text("需要辅助功能权限")
                .font(.title)
                .fontWeight(.bold)

            // 说明
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

            // 按钮
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
