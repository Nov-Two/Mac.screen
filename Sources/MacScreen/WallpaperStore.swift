import AppKit
import Foundation
import UniformTypeIdentifiers

@MainActor
final class WallpaperStore: ObservableObject {
    @Published private(set) var items: [WallpaperItem] = []
    @Published var selectedItem: WallpaperItem?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var importMessage: String?

    func load() async {
        isLoading = true
        errorMessage = nil

        let loadedItems = await WallpaperLibrary.loadItems()
        items = loadedItems
        selectedItem = preferredInitialSelection(from: loadedItems)
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
            let importedURLs = try WallpaperLibrary.importVideos(from: panel.urls)
            let loadedItems = await WallpaperLibrary.loadItems()
            items = loadedItems
            selectedItem = preferredSelection(afterImporting: importedURLs, from: loadedItems)
            errorMessage = loadedItems.isEmpty ? "没有在素材目录中找到 mp4 文件。" : nil
            importMessage = importedURLs.isEmpty ? "没有导入支持的视频文件。" : "已导入 \(importedURLs.count) 个视频。"
        } catch {
            errorMessage = "导入失败：\(error.localizedDescription)"
        }

        isLoading = false
    }

    func delete(_ item: WallpaperItem) async {
        isLoading = true
        errorMessage = nil
        importMessage = nil

        do {
            let message = try WallpaperLibrary.deleteVideo(at: item.url)
            if UserDefaults.standard.string(forKey: UserDefaultsKeys.lastWallpaperPath) == item.url.path {
                UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.lastWallpaperPath)
            }

            let loadedItems = await WallpaperLibrary.loadItems()
            items = loadedItems
            selectedItem = preferredSelection(afterDeleting: item, from: loadedItems)
            errorMessage = loadedItems.isEmpty ? "没有在素材目录中找到视频文件。" : nil
            importMessage = message
        } catch {
            errorMessage = "删除失败：\(error.localizedDescription)"
        }

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

    private func preferredSelection(afterDeleting deletedItem: WallpaperItem, from items: [WallpaperItem]) -> WallpaperItem? {
        items.first { $0.url != deletedItem.url }
    }
}
