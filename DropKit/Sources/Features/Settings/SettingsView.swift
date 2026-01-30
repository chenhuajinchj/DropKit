import SwiftUI

struct SettingsView: View {
    @Bindable var settings = AppSettings.shared

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
        }
        .frame(width: 400, height: 250)
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
            Stepper("最大历史条数: \(settings.clipboardMaxItems)", value: $settings.clipboardMaxItems, in: 10...200, step: 10)
        }
        .padding()
    }
}
