import XCTest
@testable import DropKit

final class DropKitTests: XCTestCase {
    func testDragMonitorDoesNotRegisterGlobalEventsWithoutAccessibilityPermission() {
        let eventMonitor = RecordingGlobalEventMonitor()
        let monitor = DragMonitor(
            permissionChecker: { false },
            eventMonitor: eventMonitor
        )

        XCTAssertFalse(monitor.start())
        XCTAssertTrue(eventMonitor.addedMasks.isEmpty)
    }

    func testShakeDetectorDoesNotRegisterGlobalEventsWithoutAccessibilityPermission() {
        let eventMonitor = RecordingGlobalEventMonitor()
        let detector = ShakeDetector(
            permissionChecker: { false },
            eventMonitor: eventMonitor
        )

        XCTAssertFalse(detector.start())
        XCTAssertTrue(eventMonitor.addedMasks.isEmpty)
    }

    func testBuiltInSensitiveClipboardAppsAreAlwaysIgnored() throws {
        let defaults = try makeDefaults()
        let settings = AppSettings(
            defaults: defaults,
            launchAtLoginManager: StubLaunchAtLoginManager(),
            bookmarkStore: FolderBookmarkStore(
                defaults: defaults,
                key: "watchedFolderBookmark",
                bookmarkProvider: StubBookmarkProvider()
            )
        )

        XCTAssertFalse(settings.clipboardBlacklistEnabled)
        XCTAssertTrue(settings.isBlacklisted("com.1password.1password"))
        XCTAssertTrue(settings.isBlacklisted("com.bitwarden.desktop"))
    }

    func testCustomClipboardBlacklistStillRequiresUserToggle() throws {
        let defaults = try makeDefaults()
        defaults.set(["com.example.Notes"], forKey: "clipboardBlacklist")
        let settings = AppSettings(
            defaults: defaults,
            launchAtLoginManager: StubLaunchAtLoginManager(),
            bookmarkStore: FolderBookmarkStore(
                defaults: defaults,
                key: "watchedFolderBookmark",
                bookmarkProvider: StubBookmarkProvider()
            )
        )

        XCTAssertFalse(settings.isBlacklisted("com.example.Notes"))

        settings.clipboardBlacklistEnabled = true

        XCTAssertTrue(settings.isBlacklisted("com.example.Notes"))
    }

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

    func testLatestWorkDebouncerRunsOnlyMostRecentScheduledWork() {
        let debouncer = LatestWorkDebouncer()
        let queue = DispatchQueue(label: "DropKitTests.LatestWorkDebouncer")
        let expectation = expectation(description: "latest work runs")
        let lock = NSLock()
        var values: [Int] = []

        expectation.expectedFulfillmentCount = 1

        debouncer.schedule(after: .milliseconds(20), on: queue) {
            lock.lock()
            values.append(1)
            lock.unlock()
            expectation.fulfill()
        }
        debouncer.schedule(after: .milliseconds(20), on: queue) {
            lock.lock()
            values.append(2)
            lock.unlock()
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)

        lock.lock()
        let capturedValues = values
        lock.unlock()
        XCTAssertEqual(capturedValues, [2])
    }

    @MainActor
    func testMainRunLoopCoalescerRunsMultipleRequestsOncePerTurn() async {
        let coalescer = MainRunLoopCoalescer()
        var runCount = 0

        coalescer.schedule {
            runCount += 1
        }
        coalescer.schedule {
            runCount += 1
        }

        XCTAssertEqual(runCount, 0)

        await waitForMainQueueTurn()

        XCTAssertEqual(runCount, 1)

        coalescer.schedule {
            runCount += 1
        }

        await waitForMainQueueTurn()

        XCTAssertEqual(runCount, 2)
    }

    private func makeDefaults() throws -> UserDefaults {
        let suiteName = "DropKitTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            throw XCTSkip("Failed to create isolated defaults suite")
        }
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    private func waitForMainQueueTurn() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                continuation.resume()
            }
        }
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

private final class RecordingGlobalEventMonitor: GlobalEventMonitoring {
    private(set) var addedMasks: [NSEvent.EventTypeMask] = []
    private(set) var removedCount = 0

    func addGlobalMonitor(matching mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent) -> Void) -> Any? {
        addedMasks.append(mask)
        return NSObject()
    }

    func removeMonitor(_ monitor: Any) {
        removedCount += 1
    }
}
