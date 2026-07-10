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
    static let wallpaperCardHover = WallpaperCardHoverConfiguration(
        perspective: 0.85,
        deadZone: 0.16,
        maxTiltDegrees: 7.5,
        maxOffsetX: 8,
        maxOffsetY: 6,
        maxScaleIncrease: 0.028,
        baseMediaScale: 1.03,
        maxMediaScaleIncrease: 0.028,
        mediaOffsetMultiplier: 0.4,
        contentOffsetMultiplier: 0.32,
        actionsOffsetMultiplier: 0.45,
        idleShadowOpacity: 0.08,
        hoverShadowOpacity: 0.24,
        idleShadowRadius: 8,
        hoverShadowRadius: 18,
        shadowYOffset: 6,
        shadowHoverLift: 4,
        isHighlightEnabled: false,
        highlightBaseOpacity: 0.18,
        highlightMaxOpacity: 0.42,
        resetAnimationDuration: 0.18
    )

    static var applicationSupportBaseDirectory: URL {
        FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support", isDirectory: true)
    }
}

struct WallpaperCardHoverConfiguration {
    /// `rotation3DEffect` 的透视强度，越大越接近真实 3D 空间。
    let perspective: CGFloat
    /// 中心死区比例。鼠标在中心附近时先保持更稳定，避免卡片一直轻微抖动。
    let deadZone: CGFloat
    /// 卡片绕 X / Y 轴的最大倾斜角度。
    let maxTiltDegrees: CGFloat
    /// 卡片整体在 hover 时横向最大偏移量。
    let maxOffsetX: CGFloat
    /// 卡片整体在 hover 时纵向最大偏移量。
    let maxOffsetY: CGFloat
    /// 卡片整体最大放大幅度，控制“抬起来”的感觉。
    let maxScaleIncrease: CGFloat
    /// 缩略图底图在静止时的基础缩放，避免边缘露底。
    let baseMediaScale: CGFloat
    /// 缩略图底图在 hover 时额外增加的最大缩放。
    let maxMediaScaleIncrease: CGFloat
    /// 缩略图层跟随整体偏移的倍率，通常比卡片本体更明显一点。
    let mediaOffsetMultiplier: CGFloat
    /// 文本信息层跟随偏移的倍率，用来制造轻微层次差。
    let contentOffsetMultiplier: CGFloat
    /// 右侧操作按钮层跟随偏移的倍率。
    let actionsOffsetMultiplier: CGFloat
    /// 非 hover 状态下阴影透明度。
    let idleShadowOpacity: CGFloat
    /// hover 最强时阴影透明度。
    let hoverShadowOpacity: CGFloat
    /// 非 hover 状态下阴影半径。
    let idleShadowRadius: CGFloat
    /// hover 最强时阴影半径。
    let hoverShadowRadius: CGFloat
    /// 阴影基础纵向位移。
    let shadowYOffset: CGFloat
    /// hover 增强时额外增加的阴影纵向位移。
    let shadowHoverLift: CGFloat
    /// 是否渲染鼠标跟随高光。当前先关闭，只保留参数和实现入口。
    let isHighlightEnabled: Bool
    /// 高光基础透明度，开高光时控制弱 hover 的亮度。
    let highlightBaseOpacity: CGFloat
    /// 高光最大透明度，开高光时控制强 hover 的亮度。
    let highlightMaxOpacity: CGFloat
    /// 鼠标离开后回正动画时长。
    let resetAnimationDuration: Double
}
