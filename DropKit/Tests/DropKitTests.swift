import XCTest
@testable import DropKit

final class DropKitTests: XCTestCase {
    func testSettingWatchedFolderPersistsBookmarkAndResolvedPath() throws {
        let defaults = try makeDefaults()
        let bookmarkProvider = StubBookmarkProvider()
        let settings = AppSettings(
            defaults: defaults,
            launchAtLoginManager: StubLaunchAtLoginManager(),
            bookmarkStore: FolderBookmarkStore(
                defaults: defaults,
                key: "watchedFolderBookmark",
                bookmarkProvider: bookmarkProvider
            )
        )
        let folderURL = URL(fileURLWithPath: "/tmp/dropkit-tests/watched-folder", isDirectory: true)

        XCTAssertTrue(settings.setWatchedFolder(folderURL))
        XCTAssertEqual(settings.watchedFolderPath, folderURL.path)
        XCTAssertEqual(settings.watchedFolderURL()?.path, folderURL.path)
        XCTAssertEqual(bookmarkProvider.savedURLs, [folderURL])
    }

    func testClearingWatchedFolderRemovesPersistedState() throws {
        let defaults = try makeDefaults()
        let bookmarkProvider = StubBookmarkProvider()
        let settings = AppSettings(
            defaults: defaults,
            launchAtLoginManager: StubLaunchAtLoginManager(),
            bookmarkStore: FolderBookmarkStore(
                defaults: defaults,
                key: "watchedFolderBookmark",
                bookmarkProvider: bookmarkProvider
            )
        )
        let folderURL = URL(fileURLWithPath: "/tmp/dropkit-tests/watched-folder", isDirectory: true)

        XCTAssertTrue(settings.setWatchedFolder(folderURL))

        settings.clearWatchedFolder()

        XCTAssertNil(settings.watchedFolderPath)
        XCTAssertNil(settings.watchedFolderURL())
        XCTAssertNil(defaults.data(forKey: "watchedFolderBookmark"))
    }

    func testInvalidPersistedBookmarkIsIgnoredOnInitialization() throws {
        let defaults = try makeDefaults()
        defaults.set(Data("invalid".utf8), forKey: "watchedFolderBookmark")
        defaults.set("/tmp/legacy-path", forKey: "watchedFolderPath")

        let settings = AppSettings(
            defaults: defaults,
            launchAtLoginManager: StubLaunchAtLoginManager(),
            bookmarkStore: FolderBookmarkStore(
                defaults: defaults,
                key: "watchedFolderBookmark",
                bookmarkProvider: FailingBookmarkProvider()
            )
        )

        XCTAssertNil(settings.watchedFolderPath)
        XCTAssertNil(settings.watchedFolderURL())
        XCTAssertNil(defaults.data(forKey: "watchedFolderBookmark"))
    }

    private func makeDefaults() throws -> UserDefaults {
        let suiteName = "DropKitTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            throw XCTSkip("Failed to create isolated defaults suite")
        }
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}

private final class StubBookmarkProvider: FolderBookmarking {
    private(set) var savedURLs: [URL] = []

    func makeBookmark(for url: URL) throws -> Data {
        savedURLs.append(url)
        return Data(url.path.utf8)
    }

    func resolveBookmark(_ data: Data) throws -> URL {
        guard let path = String(data: data, encoding: .utf8) else {
            throw BookmarkProviderError.invalidData
        }
        return URL(fileURLWithPath: path, isDirectory: true)
    }
}

private struct FailingBookmarkProvider: FolderBookmarking {
    func makeBookmark(for url: URL) throws -> Data {
        Data()
    }

    func resolveBookmark(_ data: Data) throws -> URL {
        throw BookmarkProviderError.invalidData
    }
}

private struct StubLaunchAtLoginManager: LaunchAtLoginManaging {
    func currentStatus() -> Bool { false }
    func setEnabled(_ enabled: Bool) throws {}
}
