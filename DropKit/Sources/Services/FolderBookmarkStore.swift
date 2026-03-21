import Foundation
import ServiceManagement

enum BookmarkProviderError: Error {
    case invalidData
}

protocol FolderBookmarking {
    func makeBookmark(for url: URL) throws -> Data
    func resolveBookmark(_ data: Data) throws -> URL
}

struct SecurityScopedFolderBookmarkProvider: FolderBookmarking {
    func makeBookmark(for url: URL) throws -> Data {
        try url.bookmarkData(
            options: [.withSecurityScope],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
    }

    func resolveBookmark(_ data: Data) throws -> URL {
        var isStale = false
        let url = try URL(
            resolvingBookmarkData: data,
            options: [.withSecurityScope],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )

        return url
    }
}

final class FolderBookmarkStore {
    private let defaults: UserDefaults
    private let key: String
    private let bookmarkProvider: any FolderBookmarking

    init(
        defaults: UserDefaults,
        key: String = "watchedFolderBookmark",
        bookmarkProvider: any FolderBookmarking = SecurityScopedFolderBookmarkProvider()
    ) {
        self.defaults = defaults
        self.key = key
        self.bookmarkProvider = bookmarkProvider
    }

    func save(_ url: URL) throws -> URL {
        let bookmarkData = try bookmarkProvider.makeBookmark(for: url)
        defaults.set(bookmarkData, forKey: key)
        return try bookmarkProvider.resolveBookmark(bookmarkData)
    }

    func restoreURL() -> URL? {
        guard let bookmarkData = defaults.data(forKey: key) else {
            return nil
        }

        do {
            return try bookmarkProvider.resolveBookmark(bookmarkData)
        } catch {
            defaults.removeObject(forKey: key)
            return nil
        }
    }

    func clear() {
        defaults.removeObject(forKey: key)
    }
}

protocol LaunchAtLoginManaging {
    func currentStatus() -> Bool
    func setEnabled(_ enabled: Bool) throws
}

struct SystemLaunchAtLoginManager: LaunchAtLoginManaging {
    func currentStatus() -> Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }

        return false
    }

    func setEnabled(_ enabled: Bool) throws {
        guard #available(macOS 13.0, *) else { return }

        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}
