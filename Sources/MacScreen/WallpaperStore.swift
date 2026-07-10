import AppKit
import Foundation
import UniformTypeIdentifiers

@MainActor
final class WallpaperStore: ObservableObject {
    @Published private(set) var items: [WallpaperItem] = []
    @Published var selectedItem: WallpaperItem?
    @Published var selectedItems = Set<WallpaperItem>()
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var importMessage: String?
    @Published private(set) var restoresLastWallpaperOnLaunch: Bool
    @Published private(set) var opensAtLogin: Bool
    @Published private(set) var pausesOnLowBattery: Bool
    @Published private(set) var cleansDownloadedResourcesAfterImport: Bool
    @Published private(set) var favoriteWallpaperPaths: Set<String>

    private let service: WallpaperServicing

    init(service: WallpaperServicing? = nil) {
        let resolvedService = service ?? DefaultWallpaperService()
        self.service = resolvedService
        restoresLastWallpaperOnLaunch = resolvedService.restoresLastWallpaperOnLaunch
        opensAtLogin = resolvedService.opensAtLogin
        pausesOnLowBattery = resolvedService.pausesOnLowBattery
        cleansDownloadedResourcesAfterImport = resolvedService.cleansDownloadedResourcesAfterImport
        favoriteWallpaperPaths = resolvedService.favoriteWallpaperPaths
    }

    func load() async {
        isLoading = true
        errorMessage = nil

        let loadedItems = await service.loadItems()
        items = loadedItems
        selectedItem = preferredInitialSelection(from: loadedItems)
        selectedItems = selectedItem.map { [$0] } ?? []
        errorMessage = loadedItems.isEmpty ? "没有在素材目录中找到 mp4 文件。" : nil
        isLoading = false
    }

    func importVideos() async {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.mpeg4Movie, .quickTimeMovie, .movie]
        panel.prompt = "导入"
        panel.message = "选择一个或多个视频作为自定义动态壁纸素材。"

        guard panel.runModal() == .OK else { return }

        isLoading = true
        errorMessage = nil
        importMessage = nil

        do {
            let importResult = try await service.importVideos(from: panel.urls)
            let loadedItems = await service.loadItems()
            items = loadedItems
            selectedItem = preferredSelection(afterImporting: importResult.importedURLs, from: loadedItems)
            selectedItems = selectedItem.map { [$0] } ?? []
            errorMessage = loadedItems.isEmpty ? "没有在素材目录中找到 mp4 文件。" : nil
            importMessage = importMessage(
                importedCount: importResult.importedURLs.count,
                rejectedLowResolutionFilenames: importResult.rejectedLowResolutionFilenames,
                emptyMessage: "没有导入支持的视频文件。"
            )
            showLowResolutionAlertIfNeeded(importResult.rejectedLowResolutionFilenames)
        } catch {
            errorMessage = "导入失败：\(error.localizedDescription)"
        }

        isLoading = false
    }

    func importDownloadedResource(at url: URL) async {
        isLoading = true
        errorMessage = nil
        importMessage = nil

        do {
            let importResult = try await service.importResources(from: [url])
            let loadedItems = await service.loadItems()
            items = loadedItems
            selectedItem = preferredSelection(afterImporting: importResult.importedURLs, from: loadedItems)
            selectedItems = selectedItem.map { [$0] } ?? []
            errorMessage = loadedItems.isEmpty ? "没有在素材目录中找到视频文件。" : nil
            importMessage = importMessage(
                importedCount: importResult.importedURLs.count,
                rejectedLowResolutionFilenames: importResult.rejectedLowResolutionFilenames,
                emptyMessage: "下载完成，但没有找到符合要求的视频文件。",
                successPrefix: "下载完成，已自动导入"
            )
            cleanDownloadedResourceIfNeeded(at: url, didImport: !importResult.importedURLs.isEmpty)
            showLowResolutionAlertIfNeeded(importResult.rejectedLowResolutionFilenames)
        } catch {
            errorMessage = "自动导入下载资源失败：\(error.localizedDescription)"
        }

        isLoading = false
    }

    func delete(_ itemsToDelete: Set<WallpaperItem>) async {
        guard !itemsToDelete.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        importMessage = nil

        do {
            let deletedURLs = Set(itemsToDelete.map(\.url))
            let message = try service.deleteVideos(at: Array(deletedURLs))
            if
                let lastPath = service.lastWallpaperPath,
                deletedURLs.contains(where: { $0.path == lastPath })
            {
                service.lastWallpaperPath = nil
            }

            let loadedItems = await service.loadItems()
            items = loadedItems
            selectedItem = preferredSelection(afterDeleting: itemsToDelete, from: loadedItems)
            selectedItems = selectedItem.map { [$0] } ?? []
            errorMessage = loadedItems.isEmpty ? "没有在素材目录中找到视频文件。" : nil
            importMessage = message
        } catch {
            errorMessage = "删除失败：\(error.localizedDescription)"
        }

        isLoading = false
    }

    func restoreBundledVideos() async {
        isLoading = true
        errorMessage = nil
        importMessage = nil

        service.restoreBundledVideos()

        let loadedItems = await service.loadItems()
        items = loadedItems
        selectedItem = preferredInitialSelection(from: loadedItems)
        selectedItems = selectedItem.map { [$0] } ?? []
        errorMessage = loadedItems.isEmpty ? "没有在素材目录中找到视频文件。" : nil
        importMessage = "已初始化内置素材。"
        isLoading = false
    }

    var previewItem: WallpaperItem? {
        selectedItems.sorted {
            $0.title.localizedStandardCompare($1.title) == .orderedAscending
        }.first ?? selectedItem
    }

    func select(_ item: WallpaperItem?) {
        selectedItem = item
        selectedItems = item.map { [$0] } ?? []
    }

    func selectNextItem(after activeURL: URL? = nil) -> WallpaperItem? {
        guard !items.isEmpty else {
            select(nil)
            return nil
        }

        let currentURL = activeURL ?? previewItem?.url
        let currentIndex = currentURL.flatMap { url in
            items.firstIndex { $0.url == url }
        }
        let nextIndex = currentIndex.map { items.index(after: $0) } ?? items.startIndex
        let wrappedIndex = nextIndex == items.endIndex ? items.startIndex : nextIndex
        let item = items[wrappedIndex]
        select(item)
        return item
    }

    func clearLastWallpaper() {
        service.lastWallpaperPath = nil
    }

    func rememberLastWallpaper(_ url: URL) {
        service.lastWallpaperPath = url.path
    }

    func toggleRestoresLastWallpaperOnLaunch() {
        restoresLastWallpaperOnLaunch.toggle()
        service.restoresLastWallpaperOnLaunch = restoresLastWallpaperOnLaunch
    }

    func toggleOpensAtLogin() {
        let nextValue = !opensAtLogin

        do {
            try service.setOpensAtLogin(nextValue)
            opensAtLogin = service.opensAtLogin
            importMessage = opensAtLogin ? "已开启开机启动。" : "已关闭开机启动。"
        } catch {
            opensAtLogin = service.opensAtLogin
            errorMessage = "更新开机启动设置失败：\(error.localizedDescription)"
        }
    }

    func togglePausesOnLowBattery() {
        pausesOnLowBattery.toggle()
        service.pausesOnLowBattery = pausesOnLowBattery
    }

    func toggleCleansDownloadedResourcesAfterImport() {
        cleansDownloadedResourcesAfterImport.toggle()
        service.cleansDownloadedResourcesAfterImport = cleansDownloadedResourcesAfterImport
    }

    func isUserVideo(_ url: URL) -> Bool {
        service.isUserVideo(url)
    }

    func isFavorite(_ item: WallpaperItem) -> Bool {
        favoriteWallpaperPaths.contains(item.url.path)
    }

    func toggleFavorite(_ item: WallpaperItem) {
        if favoriteWallpaperPaths.contains(item.url.path) {
            favoriteWallpaperPaths.remove(item.url.path)
        } else {
            favoriteWallpaperPaths.insert(item.url.path)
        }

        service.favoriteWallpaperPaths = favoriteWallpaperPaths
    }

    func downloadsDirectory() -> URL {
        AppConfiguration.applicationSupportBaseDirectory
            .appendingPathComponent(AppConfiguration.applicationSupportDirectoryName, isDirectory: true)
            .appendingPathComponent(AppConfiguration.downloadDirectoryName, isDirectory: true)
    }

    func openDownloadsDirectory() {
        let directory = downloadsDirectory()
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        NSWorkspace.shared.open(directory)
    }

    private func preferredInitialSelection(from items: [WallpaperItem]) -> WallpaperItem? {
        guard !items.isEmpty else { return nil }

        if
            let lastPath = service.lastWallpaperPath,
            let item = items.first(where: { $0.url.path == lastPath })
        {
            return item
        }

        return items.first
    }

    private func preferredSelection(afterImporting importedURLs: [URL], from items: [WallpaperItem]) -> WallpaperItem? {
        guard let importedURL = importedURLs.first else {
            return preferredInitialSelection(from: items)
        }

        return items.first { $0.url == importedURL } ?? preferredInitialSelection(from: items)
    }

    private func preferredSelection(afterDeleting deletedItems: Set<WallpaperItem>, from items: [WallpaperItem]) -> WallpaperItem? {
        items.first { !deletedItems.contains($0) }
    }

    private func importMessage(
        importedCount: Int,
        rejectedLowResolutionFilenames: [String],
        emptyMessage: String,
        successPrefix: String = "已导入"
    ) -> String {
        var parts: [String] = []

        if importedCount > 0 {
            parts.append("\(successPrefix) \(importedCount) 个视频。")
        } else {
            parts.append(emptyMessage)
        }

        if !rejectedLowResolutionFilenames.isEmpty {
            let filenames = rejectedLowResolutionFilenames.prefix(3).joined(separator: "、")
            let suffix = rejectedLowResolutionFilenames.count > 3 ? " 等 \(rejectedLowResolutionFilenames.count) 个文件" : ""
            parts.append("已跳过低分辨率视频：\(filenames)\(suffix)。请使用至少 \(AppConfiguration.minimumImportedVideoWidth)x\(AppConfiguration.minimumImportedVideoHeight) 的视频。")
        }

        return parts.joined(separator: " ")
    }

    private func showLowResolutionAlertIfNeeded(_ filenames: [String]) {
        guard !filenames.isEmpty else { return }

        let visibleNames = filenames.prefix(6).joined(separator: "\n")
        let remainingCount = max(0, filenames.count - 6)
        let remainingText = remainingCount > 0 ? "\n等 \(filenames.count) 个文件" : ""

        let alert = NSAlert()
        alert.messageText = "视频分辨率太低，已跳过导入"
        alert.informativeText = "\(visibleNames)\(remainingText)\n\n请使用至少 \(AppConfiguration.minimumImportedVideoWidth)x\(AppConfiguration.minimumImportedVideoHeight) 的视频。低分辨率视频即使强行放大，也无法恢复原本不存在的画面细节，作为桌面壁纸会明显模糊。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "知道了")
        alert.runModal()
    }

    private func cleanDownloadedResourceIfNeeded(at url: URL, didImport: Bool) {
        guard cleansDownloadedResourcesAfterImport, didImport else { return }

        let downloadsDirectory = downloadsDirectory().standardizedFileURL.path
        guard url.standardizedFileURL.path.hasPrefix(downloadsDirectory + "/") else {
            return
        }

        try? FileManager.default.removeItem(at: url)
    }
}
