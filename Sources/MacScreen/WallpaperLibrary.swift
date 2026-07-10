import AppKit
import AVFoundation
import Foundation

enum WallpaperLibrary {
    struct ImportResult {
        let importedURLs: [URL]
        let rejectedLowResolutionFilenames: [String]
    }

    static var bundledVideoDirectory: URL {
        let candidates = [
            Bundle.main.resourceURL?.appendingPathComponent(AppConfiguration.bundledVideoDirectoryName, isDirectory: true),
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent(AppConfiguration.bundledVideoDirectoryName, isDirectory: true)
        ].compactMap { $0 }

        return candidates.first { url in
            (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
        } ?? candidates[0]
    }

    static var userVideoDirectory: URL {
        AppConfiguration.applicationSupportBaseDirectory
            .appendingPathComponent(AppConfiguration.applicationSupportDirectoryName, isDirectory: true)
            .appendingPathComponent(AppConfiguration.userVideoDirectoryName, isDirectory: true)
    }

    static func loadItems() async -> [WallpaperItem] {
        var seenPaths = Set<String>()
        var allItems: [WallpaperItem] = []
        let hiddenPaths = hiddenWallpaperPaths()

        for directory in [bundledVideoDirectory, userVideoDirectory] {
            let items = await loadItems(from: directory)
            for item in items where !hiddenPaths.contains(item.url.path) && seenPaths.insert(item.url.path).inserted {
                allItems.append(item)
            }
        }

        return allItems.sorted {
            $0.title.localizedStandardCompare($1.title) == .orderedAscending
        }
    }

    static func importVideos(from sourceURLs: [URL]) async throws -> ImportResult {
        let fileManager = FileManager.default
        try fileManager.createDirectory(
            at: userVideoDirectory,
            withIntermediateDirectories: true
        )

        var importedURLs: [URL] = []
        var rejectedLowResolutionFilenames: [String] = []
        for sourceURL in sourceURLs where isSupportedVideo(sourceURL) {
            guard await isHighEnoughResolution(sourceURL) else {
                rejectedLowResolutionFilenames.append(sourceURL.lastPathComponent)
                continue
            }

            let destinationURL = uniqueDestinationURL(
                for: sourceURL.lastPathComponent,
                in: userVideoDirectory
            )
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            importedURLs.append(destinationURL)
        }

        return ImportResult(
            importedURLs: importedURLs,
            rejectedLowResolutionFilenames: rejectedLowResolutionFilenames
        )
    }

    static func importResources(from sourceURLs: [URL]) async throws -> ImportResult {
        var importedURLs: [URL] = []
        var rejectedLowResolutionFilenames: [String] = []

        for sourceURL in sourceURLs {
            if isSupportedVideo(sourceURL) {
                let result = try await importVideos(from: [sourceURL])
                importedURLs.append(contentsOf: result.importedURLs)
                rejectedLowResolutionFilenames.append(contentsOf: result.rejectedLowResolutionFilenames)
            } else if isSupportedArchive(sourceURL) {
                let result = try await importVideosFromArchive(sourceURL)
                importedURLs.append(contentsOf: result.importedURLs)
                rejectedLowResolutionFilenames.append(contentsOf: result.rejectedLowResolutionFilenames)
            }
        }

        return ImportResult(
            importedURLs: importedURLs,
            rejectedLowResolutionFilenames: rejectedLowResolutionFilenames
        )
    }

    static func deleteVideos(at urls: [URL]) throws -> String {
        var customCount = 0
        var bundledCount = 0

        for url in urls {
            if isUserVideo(url) {
                if FileManager.default.fileExists(atPath: url.path) {
                    try FileManager.default.removeItem(at: url)
                }
                customCount += 1
            } else {
                hideBundledVideo(at: url)
                bundledCount += 1
            }
        }

        if customCount > 0 && bundledCount > 0 {
            return "已删除 \(customCount) 个自定义素材，并移除 \(bundledCount) 个内置素材。"
        } else if customCount > 0 {
            return "已删除 \(customCount) 个自定义素材。"
        } else {
            return "已从列表移除 \(bundledCount) 个内置素材。"
        }
    }

    static func restoreBundledVideos() {
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.hiddenWallpaperPaths)
    }

    static func isUserVideo(_ url: URL) -> Bool {
        url.standardizedFileURL.path.hasPrefix(userVideoDirectory.standardizedFileURL.path + "/")
    }

    private static func loadItems(from directory: URL) async -> [WallpaperItem] {
        let fileManager = FileManager.default
        guard
            let urls = try? fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.fileSizeKey],
                options: [.skipsHiddenFiles]
            )
        else {
            return []
        }

        let videoURLs = urls
            .filter(isSupportedVideo)
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }

        var items: [WallpaperItem] = []
        for url in videoURLs {
            let asset = AVURLAsset(url: url)
            let duration = await durationText(for: asset)
            let resolution = await resolutionText(for: asset)
            let thumbnail = thumbnail(for: url, asset: asset)
            let size = sizeText(for: url)

            items.append(
                WallpaperItem(
                    url: url,
                    durationText: duration,
                    resolutionText: resolution,
                    sizeText: size,
                    thumbnail: thumbnail
                )
            )
        }

        return items
    }

    private static func isSupportedVideo(_ url: URL) -> Bool {
        AppConfiguration.supportedVideoExtensions.contains(url.pathExtension.lowercased())
    }

    private static func isSupportedArchive(_ url: URL) -> Bool {
        AppConfiguration.supportedArchiveExtensions.contains(url.pathExtension.lowercased())
    }

    private static func importVideosFromArchive(_ archiveURL: URL) async throws -> ImportResult {
        let fileManager = FileManager.default
        let extractionDirectory = fileManager.temporaryDirectory
            .appendingPathComponent(AppConfiguration.archiveImportTemporaryDirectoryName, isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)

        try fileManager.createDirectory(
            at: extractionDirectory,
            withIntermediateDirectories: true
        )

        defer {
            try? fileManager.removeItem(at: extractionDirectory)
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        process.arguments = ["-x", "-k", archiveURL.path, extractionDirectory.path]

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            return ImportResult(importedURLs: [], rejectedLowResolutionFilenames: [])
        }

        let videoURLs = recursiveFiles(in: extractionDirectory).filter(isSupportedVideo)
        return try await importVideos(from: videoURLs)
    }

    private static func recursiveFiles(in directory: URL) -> [URL] {
        guard
            let enumerator = FileManager.default.enumerator(
                at: directory,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            )
        else {
            return []
        }

        return enumerator
            .compactMap { $0 as? URL }
            .filter { url in
                (try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true
            }
    }

    private static func hiddenWallpaperPaths() -> Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: UserDefaultsKeys.hiddenWallpaperPaths) ?? [])
    }

    private static func hideBundledVideo(at url: URL) {
        var hiddenPaths = hiddenWallpaperPaths()
        hiddenPaths.insert(url.path)
        UserDefaults.standard.set(Array(hiddenPaths).sorted(), forKey: UserDefaultsKeys.hiddenWallpaperPaths)
    }

    private static func uniqueDestinationURL(for filename: String, in directory: URL) -> URL {
        let fileManager = FileManager.default
        let sourceURL = URL(fileURLWithPath: filename)
        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        let pathExtension = sourceURL.pathExtension.isEmpty ? "mp4" : sourceURL.pathExtension

        var destinationURL = directory.appendingPathComponent("\(baseName).\(pathExtension)")
        var index = 2
        while fileManager.fileExists(atPath: destinationURL.path) {
            destinationURL = directory.appendingPathComponent("\(baseName) \(index).\(pathExtension)")
            index += 1
        }

        return destinationURL
    }

    private static func durationText(for asset: AVAsset) async -> String {
        do {
            let duration = try await asset.load(.duration)
            let seconds = duration.seconds
            guard seconds.isFinite else { return "--" }
            return String(format: "%.1fs", seconds)
        } catch {
            return "--"
        }
    }

    private static func resolutionText(for asset: AVAsset) async -> String {
        do {
            let tracks = try await asset.loadTracks(withMediaType: .video)
            guard let track = tracks.first else { return "--" }
            let naturalSize = try await track.load(.naturalSize)
            let transform = try await track.load(.preferredTransform)
            let transformed = naturalSize.applying(transform)
            let width = Int(abs(transformed.width).rounded())
            let height = Int(abs(transformed.height).rounded())
            return "\(width)x\(height)"
        } catch {
            return "--"
        }
    }

    private static func isHighEnoughResolution(_ url: URL) async -> Bool {
        guard let resolution = await videoResolution(for: AVURLAsset(url: url)) else {
            return false
        }

        return resolution.width >= AppConfiguration.minimumImportedVideoWidth
            && resolution.height >= AppConfiguration.minimumImportedVideoHeight
    }

    private static func videoResolution(for asset: AVAsset) async -> (width: Int, height: Int)? {
        do {
            let tracks = try await asset.loadTracks(withMediaType: .video)
            guard let track = tracks.first else { return nil }
            let naturalSize = try await track.load(.naturalSize)
            let transform = try await track.load(.preferredTransform)
            let transformed = naturalSize.applying(transform)
            let width = Int(abs(transformed.width).rounded())
            let height = Int(abs(transformed.height).rounded())
            return (width, height)
        } catch {
            return nil
        }
    }

    private static func thumbnail(for videoURL: URL, asset: AVAsset) -> NSImage? {
        let name = videoURL.lastPathComponent + ".png"
        let candidates = [
            Bundle.main.resourceURL?
                .appendingPathComponent(AppConfiguration.thumbnailDirectoryName, isDirectory: true)
                .appendingPathComponent(name),
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent(AppConfiguration.localAssetDirectoryName, isDirectory: true)
                .appendingPathComponent(AppConfiguration.thumbnailDirectoryName, isDirectory: true)
                .appendingPathComponent(name)
        ].compactMap { $0 }

        if let bundledThumbnail = candidates.lazy.compactMap({ NSImage(contentsOf: $0) }).first {
            return bundledThumbnail
        }

        return generatedThumbnail(for: asset)
    }

    private static func generatedThumbnail(for asset: AVAsset) -> NSImage? {
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = AppConfiguration.generatedThumbnailMaximumSize

        do {
            let image = try generator.copyCGImage(at: .zero, actualTime: nil)
            return NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))
        } catch {
            return nil
        }
    }

    private static func sizeText(for url: URL) -> String {
        guard
            let values = try? url.resourceValues(forKeys: [.fileSizeKey]),
            let bytes = values.fileSize
        else {
            return "--"
        }

        return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }
}
