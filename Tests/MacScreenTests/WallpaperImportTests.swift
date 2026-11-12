import XCTest
@testable import MacScreen

// MARK: - 导入流程与弹窗契约
//
// 回归背景：导入完全正常的高清视频时，仍然弹出“视频分辨率太低，已跳过导入”。
// 根因不是分辨率判定算错，而是弹窗触发条件缺失——`rejectedLowResolutionFilenames`
// 为空时依旧弹窗，表现为弹窗正文里一个文件名都没有。
//
// 下面这组用例从两个层面锁死该行为：
// 1. `WallpaperStore` 层：没有文件被拒绝时，连弹窗调用都不应该发生。
// 2. `WallpaperDialogs` 层：即使被调用，空名单也必须返回 nil 内容、不弹窗。

@MainActor
final class WallpaperImportAlertTests: XCTestCase {
    private let normalVideo = URL(fileURLWithPath: "/tmp/正常高清视频.mp4")
    private let lowResolutionVideo = URL(fileURLWithPath: "/tmp/低分辨率视频.mp4")
    private let anotherLowResolutionVideo = URL(fileURLWithPath: "/tmp/另一个低分辨率视频.mp4")

    // MARK: - 文件选择面板导入

    func testImportVideosDoesNotShowLowResolutionAlertWhenNothingWasRejected() async {
        let service = StubWallpaperService()
        let alerts = RecordingAlertPresenter()
        alerts.pickedVideoFiles = [normalVideo]
        service.importVideosResult = WallpaperLibrary.ImportResult(
            importedURLs: [normalVideo],
            rejectedLowResolutionFilenames: []
        )

        let store = WallpaperStore(service: service, alerts: alerts)
        await store.importVideos()

        XCTAssertTrue(
            alerts.lowResolutionAlertCalls.isEmpty,
            "没有任何文件被拒绝时，不应该弹出低分辨率提示"
        )
        XCTAssertEqual(service.importedSourceURLs, [[normalVideo]], "正常视频应该被真实导入")
    }

    func testImportVideosShowsLowResolutionAlertWhenFileWasRejected() async {
        let service = StubWallpaperService()
        let alerts = RecordingAlertPresenter()
        alerts.pickedVideoFiles = [lowResolutionVideo]
        service.importVideosResult = WallpaperLibrary.ImportResult(
            importedURLs: [],
            rejectedLowResolutionFilenames: [lowResolutionVideo.lastPathComponent]
        )

        let store = WallpaperStore(service: service, alerts: alerts)
        await store.importVideos()

        XCTAssertEqual(
            alerts.lowResolutionAlertCalls,
            [[lowResolutionVideo.lastPathComponent]],
            "确实存在被拒文件时，必须弹出一次提示"
        )
    }

    func testImportVideosAlertListsOnlyRejectedFilesInMixedBatch() async {
        let service = StubWallpaperService()
        let alerts = RecordingAlertPresenter()
        alerts.pickedVideoFiles = [normalVideo, lowResolutionVideo, anotherLowResolutionVideo]
        service.importVideosResult = WallpaperLibrary.ImportResult(
            importedURLs: [normalVideo],
            rejectedLowResolutionFilenames: [
                lowResolutionVideo.lastPathComponent,
                anotherLowResolutionVideo.lastPathComponent
            ]
        )

        let store = WallpaperStore(service: service, alerts: alerts)
        await store.importVideos()

        XCTAssertEqual(alerts.lowResolutionAlertCalls.count, 1)
        XCTAssertEqual(
            alerts.lowResolutionAlertCalls.first,
            [lowResolutionVideo.lastPathComponent, anotherLowResolutionVideo.lastPathComponent],
            "提示里只应出现被拒绝的文件，不能混入导入成功的文件"
        )
        XCTAssertFalse(
            alerts.lowResolutionAlertCalls.first?.contains(normalVideo.lastPathComponent) == true,
            "导入成功的文件不应出现在低分辨率提示里"
        )
    }

    func testImportVideosDoesNothingWhenPickerIsCancelled() async {
        let service = StubWallpaperService()
        let alerts = RecordingAlertPresenter()
        alerts.pickedVideoFiles = nil

        let store = WallpaperStore(service: service, alerts: alerts)
        await store.importVideos()

        XCTAssertEqual(alerts.pickCallCount, 1)
        XCTAssertTrue(alerts.lowResolutionAlertCalls.isEmpty)
        XCTAssertTrue(alerts.duplicateAlertCalls.isEmpty)
        XCTAssertTrue(service.importedSourceURLs.isEmpty, "用户取消选择后不应调用导入")
    }

    func testImportVideosShowsDuplicateAlertAndSkipsImport() async {
        let service = StubWallpaperService()
        let alerts = RecordingAlertPresenter()
        alerts.pickedVideoFiles = [normalVideo]
        service.duplicateURLs = [normalVideo]

        let store = WallpaperStore(service: service, alerts: alerts)
        await store.importVideos()

        XCTAssertEqual(alerts.duplicateAlertCalls, [[normalVideo]])
        XCTAssertTrue(alerts.lowResolutionAlertCalls.isEmpty)
        XCTAssertTrue(service.importedSourceURLs.isEmpty, "重复文件应被跳过，不进入导入流程")
    }

    // MARK: - 状态栏文案

    func testImportMessageOmitsLowResolutionHintWhenNothingWasRejected() async throws {
        let service = StubWallpaperService()
        let alerts = RecordingAlertPresenter()
        alerts.pickedVideoFiles = [normalVideo]
        service.importVideosResult = WallpaperLibrary.ImportResult(
            importedURLs: [normalVideo],
            rejectedLowResolutionFilenames: []
        )

        let store = WallpaperStore(service: service, alerts: alerts)
        await store.importVideos()

        let message = try XCTUnwrap(store.importMessage)
        XCTAssertEqual(message, "已导入 1 个视频。")
        XCTAssertFalse(message.contains("低分辨率"))
    }

    func testImportMessageMentionsRejectedFiles() async throws {
        let service = StubWallpaperService()
        let alerts = RecordingAlertPresenter()
        alerts.pickedVideoFiles = [lowResolutionVideo]
        service.importVideosResult = WallpaperLibrary.ImportResult(
            importedURLs: [],
            rejectedLowResolutionFilenames: [lowResolutionVideo.lastPathComponent]
        )

        let store = WallpaperStore(service: service, alerts: alerts)
        await store.importVideos()

        let message = try XCTUnwrap(store.importMessage)
        XCTAssertTrue(message.contains("低分辨率"))
        XCTAssertTrue(message.contains(lowResolutionVideo.lastPathComponent))
    }

    // MARK: - 下载后自动导入

    func testImportDownloadedResourceDoesNotShowLowResolutionAlertWhenNothingWasRejected() async {
        let service = StubWallpaperService()
        let alerts = RecordingAlertPresenter()
        service.importResourcesResult = WallpaperLibrary.ImportResult(
            importedURLs: [normalVideo],
            rejectedLowResolutionFilenames: []
        )

        let store = WallpaperStore(service: service, alerts: alerts)
        await store.importDownloadedResource(at: normalVideo)

        XCTAssertTrue(
            alerts.lowResolutionAlertCalls.isEmpty,
            "下载导入正常视频时，不应该弹出低分辨率提示"
        )
        XCTAssertEqual(service.importedResourceURLs, [[normalVideo]])
    }

    func testImportDownloadedResourceShowsLowResolutionAlertWhenFileWasRejected() async {
        let service = StubWallpaperService()
        let alerts = RecordingAlertPresenter()
        service.importResourcesResult = WallpaperLibrary.ImportResult(
            importedURLs: [],
            rejectedLowResolutionFilenames: [lowResolutionVideo.lastPathComponent]
        )

        let store = WallpaperStore(service: service, alerts: alerts)
        await store.importDownloadedResource(at: lowResolutionVideo)

        XCTAssertEqual(alerts.lowResolutionAlertCalls, [[lowResolutionVideo.lastPathComponent]])
    }

    func testImportDownloadedResourceShowsDuplicateAlertAndSkipsImport() async {
        let service = StubWallpaperService()
        let alerts = RecordingAlertPresenter()
        service.duplicateURLs = [normalVideo]

        let store = WallpaperStore(service: service, alerts: alerts)
        await store.importDownloadedResource(at: normalVideo)

        XCTAssertEqual(alerts.duplicateAlertCalls, [[normalVideo]])
        XCTAssertTrue(service.importedResourceURLs.isEmpty)
    }
}

// MARK: - 弹窗内容层
//
// 即使上游把空名单传下来，弹窗层也必须拒绝渲染。

@MainActor
final class WallpaperLowResolutionAlertContentTests: XCTestCase {
    func testContentIsNilWhenNoFileWasRejected() {
        XCTAssertNil(
            WallpaperDialogs.lowResolutionAlertContent(for: []),
            "空名单必须返回 nil，这是误报弹窗的最后一道防线"
        )
    }

    func testContentListsRejectedFilenames() throws {
        let content = try XCTUnwrap(
            WallpaperDialogs.lowResolutionAlertContent(for: ["低清A.mp4", "低清B.mp4"])
        )

        XCTAssertEqual(content.message, "视频分辨率太低，已跳过导入")
        XCTAssertTrue(content.informativeText.contains("低清A.mp4"))
        XCTAssertTrue(content.informativeText.contains("低清B.mp4"))
        XCTAssertFalse(content.informativeText.contains("等 "), "两个文件时不应出现省略提示")
    }

    func testContentTruncatesAfterSixFiles() throws {
        let names = (1...8).map { "低清\($0).mp4" }
        let content = try XCTUnwrap(WallpaperDialogs.lowResolutionAlertContent(for: names))

        XCTAssertTrue(content.informativeText.contains("低清6.mp4"))
        XCTAssertFalse(content.informativeText.contains("低清7.mp4"), "第 7 个及之后应被省略")
        XCTAssertTrue(content.informativeText.contains("等 8 个文件"))
    }

    func testContentMentionsConfiguredThreshold() throws {
        let content = try XCTUnwrap(WallpaperDialogs.lowResolutionAlertContent(for: ["低清.mp4"]))
        let threshold = "\(AppConfiguration.minimumImportedVideoWidth)x\(AppConfiguration.minimumImportedVideoHeight)"

        XCTAssertEqual(threshold, "1920x1080")
        XCTAssertTrue(content.informativeText.contains(threshold))
    }
}

// MARK: - 测试替身

@MainActor
private final class RecordingAlertPresenter: WallpaperAlertPresenting {
    var pickedVideoFiles: [URL]?
    private(set) var pickCallCount = 0
    /// 记录的是「上游发起的弹窗请求」，不做空名单过滤——
    /// 这样即使 Store 层漏了判断，测试也能直接发现。
    private(set) var lowResolutionAlertCalls: [[String]] = []
    private(set) var duplicateAlertCalls: [[URL]] = []

    func pickVideoFiles() -> [URL]? {
        pickCallCount += 1
        return pickedVideoFiles
    }

    func showLowResolutionAlert(_ filenames: [String]) {
        lowResolutionAlertCalls.append(filenames)
    }

    func showDuplicateAlert(_ duplicateURLs: [URL]) {
        duplicateAlertCalls.append(duplicateURLs)
    }
}

@MainActor
private final class StubWallpaperService: WallpaperServicing {
    var lastWallpaperPath: String?
    var restoresLastWallpaperOnLaunch = false
    var opensAtLogin = false
    var pausesOnLowBattery = false
    var cleansDownloadedResourcesAfterImport = true
    var favoriteWallpaperPaths = Set<String>()

    var items: [WallpaperItem] = []
    var duplicateURLs: [URL] = []
    var importVideosResult = WallpaperLibrary.ImportResult(
        importedURLs: [],
        rejectedLowResolutionFilenames: []
    )
    var importResourcesResult = WallpaperLibrary.ImportResult(
        importedURLs: [],
        rejectedLowResolutionFilenames: []
    )
    private(set) var importedSourceURLs: [[URL]] = []
    private(set) var importedResourceURLs: [[URL]] = []

    func loadItems() async -> [WallpaperItem] {
        items
    }

    func duplicateSourceURLs(in urls: [URL]) -> [URL] {
        duplicateURLs
    }

    func setOpensAtLogin(_ isEnabled: Bool) throws {
        opensAtLogin = isEnabled
    }

    func importVideos(from urls: [URL]) async throws -> WallpaperLibrary.ImportResult {
        importedSourceURLs.append(urls)
        return importVideosResult
    }

    func importResources(from urls: [URL]) async throws -> WallpaperLibrary.ImportResult {
        importedResourceURLs.append(urls)
        return importResourcesResult
    }

    func deleteVideos(at urls: [URL]) throws -> String {
        ""
    }

    func restoreBundledVideos() {}

    func isUserVideo(_ url: URL) -> Bool {
        false
    }
}
