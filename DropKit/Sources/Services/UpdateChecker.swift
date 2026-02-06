import Foundation
import AppKit

enum UpdateCheckState: Equatable {
    case idle
    case checking
    case upToDate
    case available(version: String, url: URL, notes: String?)
    case failed(String)

    static func == (lhs: UpdateCheckState, rhs: UpdateCheckState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.checking, .checking), (.upToDate, .upToDate):
            return true
        case let (.available(v1, u1, n1), .available(v2, u2, n2)):
            return v1 == v2 && u1 == u2 && n1 == n2
        case let (.failed(m1), .failed(m2)):
            return m1 == m2
        default:
            return false
        }
    }
}

struct GitHubRelease: Codable {
    let tagName: String
    let htmlUrl: String
    let body: String?
    let assets: [GitHubAsset]

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlUrl = "html_url"
        case body, assets
    }
}

struct GitHubAsset: Codable {
    let name: String
    let browserDownloadUrl: String

    enum CodingKeys: String, CodingKey {
        case name
        case browserDownloadUrl = "browser_download_url"
    }
}

@Observable
class UpdateChecker {
    static let shared = UpdateChecker()

    private let owner = "chenhuajinchj"
    private let repo = "DropKit"

    private(set) var state: UpdateCheckState = .idle
    private(set) var downloadURL: URL?

    private init() {}

    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    func checkForUpdates() async {
        guard state != .checking else { return }

        await MainActor.run { state = .checking }

        let urlString = "https://api.github.com/repos/\(owner)/\(repo)/releases/latest"
        guard let url = URL(string: urlString) else {
            await MainActor.run { state = .failed("无效的 API 地址") }
            return
        }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                await MainActor.run { state = .failed("服务器错误") }
                return
            }

            let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
            let remoteVersion = release.tagName.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))

            await MainActor.run {
                AppSettings.shared.lastUpdateCheckDate = Date()
            }

            let comparison = compareVersions(currentVersion, remoteVersion)

            await MainActor.run {
                if comparison == .orderedAscending {
                    if let asset = release.assets.first(where: {
                        $0.name.hasSuffix(".dmg") || $0.name.hasSuffix(".zip")
                    }) {
                        downloadURL = URL(string: asset.browserDownloadUrl)
                    } else {
                        downloadURL = URL(string: release.htmlUrl)
                    }
                    state = .available(
                        version: remoteVersion,
                        url: downloadURL ?? URL(string: release.htmlUrl)!,
                        notes: release.body
                    )
                } else {
                    state = .upToDate
                }
            }
        } catch {
            await MainActor.run { state = .failed("检查失败") }
        }
    }

    func compareVersions(_ v1: String, _ v2: String) -> ComparisonResult {
        let c1 = v1.split(separator: ".").compactMap { Int($0) }
        let c2 = v2.split(separator: ".").compactMap { Int($0) }
        let maxLen = max(c1.count, c2.count)

        for i in 0..<maxLen {
            let p1 = i < c1.count ? c1[i] : 0
            let p2 = i < c2.count ? c2[i] : 0
            if p1 < p2 { return .orderedAscending }
            if p1 > p2 { return .orderedDescending }
        }
        return .orderedSame
    }

    func openDownloadPage() {
        if let url = downloadURL { NSWorkspace.shared.open(url) }
    }

    func reset() { state = .idle }
}
