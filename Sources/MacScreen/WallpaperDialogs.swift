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

    /// 低分辨率提示的文案。没有任何文件被拒绝时返回 `nil`，表示不应该弹窗。
    ///
    /// 抽成纯函数是为了让"空名单不弹窗"这条规则可以被单元测试直接覆盖，
    /// 而不需要真正弹出 `NSAlert`。
    static func lowResolutionAlertContent(
        for filenames: [String]
    ) -> (message: String, informativeText: String)? {
        guard !filenames.isEmpty else { return nil }

        let visibleNames = filenames.prefix(6).joined(separator: "\n")
        let remainingCount = max(0, filenames.count - 6)
        let remainingText = remainingCount > 0 ? "\n等 \(filenames.count) 个文件" : ""

        return (
            message: "视频分辨率太低，已跳过导入",
            informativeText: "\(visibleNames)\(remainingText)\n\n请使用至少 \(AppConfiguration.minimumImportedVideoWidth)x\(AppConfiguration.minimumImportedVideoHeight) 的视频。低分辨率视频即使强行放大，也无法恢复原本不存在的画面细节，作为桌面壁纸会明显模糊。"
        )
    }

    static func showLowResolutionAlert(_ filenames: [String]) {
        // 没有任何文件被拒绝时不要弹窗，否则会出现空名单的误报提示。
        guard let content = lowResolutionAlertContent(for: filenames) else { return }

        let alert = NSAlert()
        alert.messageText = content.message
        alert.informativeText = content.informativeText
        alert.alertStyle = .warning
        alert.addButton(withTitle: "知道了")
        alert.runModal()
    }

    static func showDuplicateAlert(_ duplicateURLs: [URL]) {
        guard !duplicateURLs.isEmpty else { return }

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

/// 文件选择面板与提示弹窗的抽象。
///
/// `WallpaperStore` 只依赖这个协议，测试中可以注入替身来断言
/// "什么时候弹了窗、弹了几次、内容是什么"，而不需要真的弹出 UI。
@MainActor
protocol WallpaperAlertPresenting: AnyObject {
    func pickVideoFiles() -> [URL]?
    func showLowResolutionAlert(_ filenames: [String])
    func showDuplicateAlert(_ duplicateURLs: [URL])
}

/// 默认实现：走真实的 `NSOpenPanel` / `NSAlert`。
@MainActor
final class SystemWallpaperAlertPresenter: WallpaperAlertPresenting {
    func pickVideoFiles() -> [URL]? {
        WallpaperDialogs.runVideoOpenPanel()
    }

    func showLowResolutionAlert(_ filenames: [String]) {
        WallpaperDialogs.showLowResolutionAlert(filenames)
    }

    func showDuplicateAlert(_ duplicateURLs: [URL]) {
        WallpaperDialogs.showDuplicateAlert(duplicateURLs)
    }
}
