import AppKit
import Foundation

struct WallpaperItem: Identifiable, Hashable {
    let id: URL
    let url: URL
    let title: String
    let durationText: String
    let resolutionText: String
    let sizeText: String
    var thumbnail: NSImage?

    init(
        url: URL,
        durationText: String = "--",
        resolutionText: String = "--",
        sizeText: String = "--",
        thumbnail: NSImage? = nil
    ) {
        self.id = url
        self.url = url
        self.title = url.deletingPathExtension().lastPathComponent
        self.durationText = durationText
        self.resolutionText = resolutionText
        self.sizeText = sizeText
        self.thumbnail = thumbnail
    }

    static func == (lhs: WallpaperItem, rhs: WallpaperItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
