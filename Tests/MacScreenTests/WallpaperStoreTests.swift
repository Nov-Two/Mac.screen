import XCTest
@testable import MacScreen

@MainActor
final class WallpaperStoreTests: XCTestCase {
    func testLoadSelectsLastWallpaperWhenAvailable() async {
        let first = WallpaperItem(url: URL(fileURLWithPath: "/tmp/first.mp4"))
        let second = WallpaperItem(url: URL(fileURLWithPath: "/tmp/second.mp4"))
        let service = MockWallpaperService(items: [first, second])
        service.lastWallpaperPath = second.url.path

        let store = WallpaperStore(service: service)
        await store.load()

        XCTAssertEqual(store.previewItem, second)
        XCTAssertEqual(store.selectedItems, [second])
    }

    func testSelectNextItemWrapsAround() async {
        let first = WallpaperItem(url: URL(fileURLWithPath: "/tmp/first.mp4"))
        let second = WallpaperItem(url: URL(fileURLWithPath: "/tmp/second.mp4"))
        let service = MockWallpaperService(items: [first, second])
        let store = WallpaperStore(service: service)
        await store.load()

        XCTAssertEqual(store.selectNextItem(after: first.url), second)
        XCTAssertEqual(store.selectNextItem(after: second.url), first)
    }

    func testToggleRestoreOnLaunchPersistsSetting() {
        let service = MockWallpaperService(items: [])
        let store = WallpaperStore(service: service)

        XCTAssertFalse(store.restoresLastWallpaperOnLaunch)
        store.toggleRestoresLastWallpaperOnLaunch()

        XCTAssertTrue(store.restoresLastWallpaperOnLaunch)
        XCTAssertTrue(service.restoresLastWallpaperOnLaunch)
    }

    func testToggleLowBatteryPausePersistsSetting() {
        let service = MockWallpaperService(items: [])
        let store = WallpaperStore(service: service)

        XCTAssertFalse(store.pausesOnLowBattery)
        store.togglePausesOnLowBattery()

        XCTAssertTrue(store.pausesOnLowBattery)
        XCTAssertTrue(service.pausesOnLowBattery)
    }

    func testToggleOpenAtLoginDelegatesToService() {
        let service = MockWallpaperService(items: [])
        let store = WallpaperStore(service: service)

        XCTAssertFalse(store.opensAtLogin)
        store.toggleOpensAtLogin()

        XCTAssertTrue(store.opensAtLogin)
        XCTAssertTrue(service.opensAtLogin)
    }

    func testToggleDownloadCleanupPersistsSetting() {
        let service = MockWallpaperService(items: [])
        let store = WallpaperStore(service: service)

        XCTAssertTrue(store.cleansDownloadedResourcesAfterImport)
        store.toggleCleansDownloadedResourcesAfterImport()

        XCTAssertFalse(store.cleansDownloadedResourcesAfterImport)
        XCTAssertFalse(service.cleansDownloadedResourcesAfterImport)
    }

    func testToggleFavoritePersistsPath() {
        let item = WallpaperItem(url: URL(fileURLWithPath: "/tmp/favorite.mp4"))
        let service = MockWallpaperService(items: [item])
        let store = WallpaperStore(service: service)

        XCTAssertFalse(store.isFavorite(item))
        store.toggleFavorite(item)

        XCTAssertTrue(store.isFavorite(item))
        XCTAssertEqual(service.favoriteWallpaperPaths, [item.url.path])
    }
}

@MainActor
private final class MockWallpaperService: WallpaperServicing {
    var lastWallpaperPath: String?
    var restoresLastWallpaperOnLaunch = false
    var opensAtLogin = false
    var pausesOnLowBattery = false
    var cleansDownloadedResourcesAfterImport = true
    var favoriteWallpaperPaths = Set<String>()
    private let items: [WallpaperItem]

    init(items: [WallpaperItem]) {
        self.items = items
    }

    func loadItems() async -> [WallpaperItem] {
        items
    }

    func setOpensAtLogin(_ isEnabled: Bool) throws {
        opensAtLogin = isEnabled
    }

    func importVideos(from urls: [URL]) async throws -> WallpaperLibrary.ImportResult {
        WallpaperLibrary.ImportResult(importedURLs: [], rejectedLowResolutionFilenames: [])
    }

    func importResources(from urls: [URL]) async throws -> WallpaperLibrary.ImportResult {
        WallpaperLibrary.ImportResult(importedURLs: [], rejectedLowResolutionFilenames: [])
    }

    func deleteVideos(at urls: [URL]) throws -> String {
        ""
    }

    func restoreBundledVideos() {}

    func isUserVideo(_ url: URL) -> Bool {
        false
    }
}
