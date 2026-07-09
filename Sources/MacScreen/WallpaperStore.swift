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

    func load() async {
        isLoading = true
        errorMessage = nil

        let loadedItems = await WallpaperLibrary.loadItems()
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
            let importResult = try await WallpaperLibrary.importVideos(from: panel.urls)
            let loadedItems = await WallpaperLibrary.loadItems()
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
            let importResult = try await WallpaperLibrary.importResources(from: [url])
            let loadedItems = await WallpaperLibrary.loadItems()
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
            let message = try WallpaperLibrary.deleteVideos(at: Array(deletedURLs))
            if
                let lastPath = UserDefaults.standard.string(forKey: UserDefaultsKeys.lastWallpaperPath),
                deletedURLs.contains(where: { $0.path == lastPath })
            {
                UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.lastWallpaperPath)
            }

            let loadedItems = await WallpaperLibrary.loadItems()
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

        WallpaperLibrary.restoreBundledVideos()

        let loadedItems = await WallpaperLibrary.loadItems()
        items = loadedItems
        selectedItem = preferredInitialSelection(from: loadedItems)
        selectedItems = selectedItem.map { [$0] } ?? []
        errorMessage = loadedItems.isEmpty ? "没有在素材目录中找到视频文件。" : nil
        importMessage = "已初始化内置素材。"
        isLoading = false
    }

    private func preferredInitialSelection(from items: [WallpaperItem]) -> WallpaperItem? {
        guard !items.isEmpty else { return nil }

        if
            let lastPath = UserDefaults.standard.string(forKey: UserDefaultsKeys.lastWallpaperPath),
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
            parts.append("已跳过低分辨率视频：\(filenames)\(suffix)。请使用至少 1920x1080 的视频。")
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
        alert.informativeText = "\(visibleNames)\(remainingText)\n\n请使用至少 1920x1080 的视频。低分辨率视频即使强行放大，也无法恢复原本不存在的画面细节，作为桌面壁纸会明显模糊。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "知道了")
        alert.runModal()
    }
}
