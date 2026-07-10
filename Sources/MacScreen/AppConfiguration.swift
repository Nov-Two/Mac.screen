import Foundation
import CoreGraphics

enum AppConfiguration {
    static let appName = "MacScreen"
    static let applicationSupportDirectoryName = "MacScreen"
    static let bundledVideoDirectoryName = "Videos"
    static let userVideoDirectoryName = "Videos"
    static let downloadDirectoryName = "Downloads"
    static let thumbnailDirectoryName = "Thumbnails"
    static let localAssetDirectoryName = "Assets"
    static let linkDirectoryName = "Links"
    static let archiveImportTemporaryDirectoryName = "MacScreenArchiveImport"
    static let defaultDownloadFilename = "MacScreenDownload"

    static let supportedVideoExtensions: Set<String> = ["mp4", "mov", "m4v"]
    static let supportedArchiveExtensions: Set<String> = ["zip"]
    static let minimumImportedVideoWidth = 1920
    static let minimumImportedVideoHeight = 1080
    static let generatedThumbnailMaximumSize = CGSize(width: 1280, height: 720)

    static let wallpaperWebsiteURL = URL(string: "https://haowallpaper.com/")!
    static let wallpaperWebsiteTitle = "haowallpaper.com"
    static let githubProfileURL = URL(string: "https://github.com/")!

    static let browserWindowSize = CGSize(width: 1180, height: 760)
    static let lowBatteryPauseThresholdPercent = 20
    static let lowBatteryMonitorInterval: TimeInterval = 60

    static var applicationSupportBaseDirectory: URL {
        FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support", isDirectory: true)
    }
}
