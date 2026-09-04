import AppKit
import UniformTypeIdentifiers

@MainActor
enum WallpaperDialogs {
    static func runVideoOpenPanel() -> [URL]? {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.mpeg4Movie, .quickTimeMovie, .movie]
        panel.prompt = "导入"
        panel.message = "选择一个或多个视频作为自定义动态壁纸素材。"

        guard panel.runModal() == .OK else { return nil }
        return panel.urls
    }

    static func showLowResolutionAlert(_ filenames: [String]) {
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

    static func showDuplicateAlert(_ duplicateURLs: [URL]) {
        let visibleNames = duplicateURLs.prefix(6).map(\.lastPathComponent).joined(separator: "\n")
        let remainingCount = max(0, duplicateURLs.count - 6)
        let remainingText = remainingCount > 0 ? "\n等 \(duplicateURLs.count) 个文件" : ""

        let alert = NSAlert()
        alert.messageText = "视频已存在，已跳过导入"
        alert.informativeText = "\(visibleNames)\(remainingText)\n\n以下文件已存在于素材目录中，无需重复导入。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "知道了")
        alert.runModal()
    }
}
