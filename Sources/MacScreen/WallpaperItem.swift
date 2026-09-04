import AppKit
import Foundation

struct WallpaperItem: Identifiable, Hashable {
    let id: URL
    let url: URL
    let title: String
    let durationText: String
    let resolutionText: String
    let sizeText: String
    let mainCategory: String
    let displayTags: [String]
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
        let title = url.deletingPathExtension().lastPathComponent
        self.title = title
        self.durationText = durationText
        self.resolutionText = resolutionText
        self.sizeText = sizeText
        self.thumbnail = thumbnail

        let tags = Self.makeDisplayTags(from: title)
        self.displayTags = tags
        self.mainCategory = Self.makeMainCategory(from: title, displayTags: tags)
    }

    static func == (lhs: WallpaperItem, rhs: WallpaperItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    private static func makeDisplayTags(from title: String) -> [String] {
        let separators = CharacterSet(charactersIn: " -_[]【】()（）·")
            .union(.whitespacesAndNewlines)
        let rawTags = title
            .components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let filtered = rawTags.filter { tag in
            tag != "哲风壁纸" && tag != "动态壁纸"
        }

        return Array(filtered.prefix(6))
    }

    private static func makeMainCategory(from title: String, displayTags: [String]) -> String {
        let text = (title + " " + displayTags.joined(separator: " ")).lowercased()

        if text.contains("二次元")
            || text.contains("动漫")
            || text.contains("动画")
            || text.contains("线稿")
            || text.contains("kuroha")
        {
            return "二次元"
        }

        if text.contains("风景")
            || text.contains("云")
            || text.contains("山")
            || text.contains("海")
            || text.contains("户外")
            || text.contains("露营")
        {
            return "风景"
        }

        if text.contains("少女")
            || text.contains("甜妹")
            || text.contains("人物")
            || text.contains("原神")
        {
            return "人物"
        }

        return "其他"
    }
}
