import Foundation

@MainActor
protocol WallpaperServicing: AnyObject {
    var lastWallpaperPath: String? { get set }
    var restoresLastWallpaperOnLaunch: Bool { get set }
    var opensAtLogin: Bool { get }
    var pausesOnLowBattery: Bool { get set }
    var cleansDownloadedResourcesAfterImport: Bool { get set }
    var favoriteWallpaperPaths: Set<String> { get set }

    func setOpensAtLogin(_ isEnabled: Bool) throws
    func loadItems() async -> [WallpaperItem]
    func importVideos(from urls: [URL]) async throws -> WallpaperLibrary.ImportResult
    func importResources(from urls: [URL]) async throws -> WallpaperLibrary.ImportResult
    func deleteVideos(at urls: [URL]) throws -> String
    func restoreBundledVideos()
    func isUserVideo(_ url: URL) -> Bool
}

@MainActor
final class DefaultWallpaperService: WallpaperServicing {
    var lastWallpaperPath: String? {
        get {
            UserDefaults.standard.string(forKey: UserDefaultsKeys.lastWallpaperPath)
        }
        set {
            if let newValue {
                UserDefaults.standard.set(newValue, forKey: UserDefaultsKeys.lastWallpaperPath)
            } else {
                UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.lastWallpaperPath)
            }
        }
    }

    var restoresLastWallpaperOnLaunch: Bool {
        get {
            UserDefaults.standard.bool(forKey: UserDefaultsKeys.restoresLastWallpaperOnLaunch)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKeys.restoresLastWallpaperOnLaunch)
        }
    }

    var opensAtLogin: Bool {
        LoginItemController.isEnabled
    }

    var pausesOnLowBattery: Bool {
        get {
            UserDefaults.standard.bool(forKey: UserDefaultsKeys.pausesOnLowBattery)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKeys.pausesOnLowBattery)
        }
    }

    var cleansDownloadedResourcesAfterImport: Bool {
        get {
            if UserDefaults.standard.object(forKey: UserDefaultsKeys.cleansDownloadedResourcesAfterImport) == nil {
                return true
            }

            return UserDefaults.standard.bool(forKey: UserDefaultsKeys.cleansDownloadedResourcesAfterImport)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKeys.cleansDownloadedResourcesAfterImport)
        }
    }

    var favoriteWallpaperPaths: Set<String> {
        get {
            Set(UserDefaults.standard.stringArray(forKey: UserDefaultsKeys.favoriteWallpaperPaths) ?? [])
        }
        set {
            UserDefaults.standard.set(Array(newValue).sorted(), forKey: UserDefaultsKeys.favoriteWallpaperPaths)
        }
    }

    func setOpensAtLogin(_ isEnabled: Bool) throws {
        try LoginItemController.setEnabled(isEnabled)
    }

    func loadItems() async -> [WallpaperItem] {
        await WallpaperLibrary.loadItems()
    }

    func importVideos(from urls: [URL]) async throws -> WallpaperLibrary.ImportResult {
        try await WallpaperLibrary.importVideos(from: urls)
    }

    func importResources(from urls: [URL]) async throws -> WallpaperLibrary.ImportResult {
        try await WallpaperLibrary.importResources(from: urls)
    }

    func deleteVideos(at urls: [URL]) throws -> String {
        try WallpaperLibrary.deleteVideos(at: urls)
    }

    func restoreBundledVideos() {
        WallpaperLibrary.restoreBundledVideos()
    }

    func isUserVideo(_ url: URL) -> Bool {
        WallpaperLibrary.isUserVideo(url)
    }
}
