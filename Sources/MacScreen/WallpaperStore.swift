import Foundation

@MainActor
final class WallpaperStore: ObservableObject {
    @Published private(set) var items: [WallpaperItem] = []
    @Published var selectedItem: WallpaperItem?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    func load() async {
        isLoading = true
        errorMessage = nil

        let loadedItems = await WallpaperLibrary.loadItems()
        items = loadedItems
        selectedItem = preferredInitialSelection(from: loadedItems)
        errorMessage = loadedItems.isEmpty ? "没有在素材目录中找到 mp4 文件。" : nil
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
}
