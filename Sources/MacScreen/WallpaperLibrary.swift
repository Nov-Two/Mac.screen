import AppKit
import AVFoundation
import Foundation

enum WallpaperLibrary {
    static var defaultVideoDirectory: URL {
        let candidates = [
            Bundle.main.resourceURL?.appendingPathComponent("Videos", isDirectory: true),
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("Videos", isDirectory: true),
            URL(fileURLWithPath: "/Users/user/Desktop/project/Mac.screen/Videos", isDirectory: true)
        ].compactMap { $0 }

        return candidates.first { url in
            (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
        } ?? candidates[0]
    }

    static func loadItems(from directory: URL = defaultVideoDirectory) async -> [WallpaperItem] {
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
            .filter { $0.pathExtension.lowercased() == "mp4" }
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

    private static func thumbnail(for videoURL: URL, asset: AVAsset) -> NSImage? {
        let name = videoURL.lastPathComponent + ".png"
        let candidates = [
            Bundle.main.resourceURL?.appendingPathComponent("Thumbnails", isDirectory: true).appendingPathComponent(name),
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("Assets/Thumbnails", isDirectory: true).appendingPathComponent(name)
        ].compactMap { $0 }

        if let bundledThumbnail = candidates.lazy.compactMap({ NSImage(contentsOf: $0) }).first {
            return bundledThumbnail
        }

        return generatedThumbnail(for: asset)
    }

    private static func generatedThumbnail(for asset: AVAsset) -> NSImage? {
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 1280, height: 720)

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
