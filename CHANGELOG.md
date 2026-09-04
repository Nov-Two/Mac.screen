# Changelog

## 2026-09-04

- 用户导入视频的缩略图首次生成后缓存到 `Application Support/MacScreen/Thumbnails`，后续启动直接读缓存，避免每次启动重复解码
- 移除内置浏览器打开前对 `WKWebsiteDataStore.default()` 的无意义清缓存操作（实际使用非持久化 store）
- 文件名去重统一到 `FileSystemHelper.uniqueFileURL`，替换原来分散在 `WallpaperLibrary` 和 `InAppBrowserWindowController` 的两份实现
- 音量图标映射统一到 `AppConfiguration.volumeSymbolName`，消除主窗口、菜单栏、桌面叠加层的重复判断
- 下载目录路径统一到 `AppConfiguration.downloadsDirectory`
- `applyWallpaper` 收敛为 `WallpaperStore.applyWallpaper(_:with:)` 单一入口，消除 `ContentView` 与 `MacScreenApp` 的重复实现
- `WallpaperStore` 的加载/导入/删除/恢复等刷新流程收敛为 `refreshItems(emptyMessage:selection:)`
- 拆分 `ContentView.swift`（约 1200 行）为 `ContentView` + `WallpaperCardView` + `ToolbarViews` + `PointingHandCursorModifier`
- 抽出 `WallpaperDialogs`，把 `NSOpenPanel`、`NSAlert` 弹窗职责从 `WallpaperStore` 中剥离
- `WallpaperItem` 的分类与标签由“每次渲染现算”改为构造时预计算并存储
- 删除死代码 `availableCategories` 与 `deleteButtonTitle`
- 新增 `FileSystemHelper` 与 `WallpaperItem` 分类/标签的单元测试

## 2026-07-13

- 新增全局音量控制功能：主窗口底部、桌面壁纸叠加层、菜单栏常驻入口三处均提供音量滑块
- 桌面壁纸播放默认取消静音，音量持久化到 UserDefaults
- 新增 `VolumeOverlayView`（AppKit 视图），在桌面壁纸窗口底部居中显示半透明音量控件
- 菜单栏常驻入口新增音量滑块菜单项，支持实时拖动并同步更新图标和百分比数字
- 修复音量 100% 时百分比数字换行问题（增加 frame 宽度并添加 `lineLimit(1)`）
- 修复菜单栏"偏好设置"菜单项打开错误窗口的问题，改用 SwiftUI 标准 `@Environment(\.openSettings)` 打开设置
- 菜单栏状态栏改为仅显示应用图标，不再在图标旁显示壁纸名称，播放状态和壁纸名称改为在菜单首项展示
- 菜单栏图标改用应用图标 `MacScreenIcon.icns`（替换原 SF Symbols 图标），等比缩放为 18×18 点，加载失败时回退到默认图标
- 新增素材卡片 3D hover 动效，鼠标在卡片上移动时产生 tilt/scale/offset 跟随效果，底图、文字、按钮分层响应
- 工具栏新增动态效果开关按钮，关闭后停用连续鼠标跟踪以减轻卡顿，状态持久化
- 动效参数集中到 `AppConfiguration.wallpaperCardHover`，支持透视强度、倾斜角度、偏移量、缩放、阴影、死区等配置
- 新增 About 面板配置（`aboutPanel`）和 Help 弹窗配置（`helpPanel`），走 `AppConfiguration` 集中管理
- 偏好设置新增"打开用户素材目录"和"打开内置素材目录"按钮，可在 Finder 中直接管理素材文件
- 新增重复导入拦截：导入时检测文件名是否已在用户素材目录中存在，存在则弹窗提示并跳过
- 新增素材右键菜单：支持应用、暂停/继续、停止、在 Finder 中查看、删除
- 右键菜单文案和图标配置集中到 `AppConfiguration.contextMenu`

## 2026-07-10

- Centralized runtime configuration in `AppConfiguration`, including resource directory names, external URLs, import limits, browser window size, and low-battery thresholds.
- Removed the development-machine absolute video path fallback from runtime resource loading.
- Added `WallpaperServicing` and `DefaultWallpaperService` so wallpaper loading, importing, deletion, settings, and persistence can be tested outside the UI.
- Added a SwiftPM test target with Store-level tests for last-wallpaper selection, next-wallpaper cycling, startup restore, low-battery pause, and login item toggles.
- Added a menu bar controller with quick actions for showing the main window, adding videos, applying the current selection, pausing or resuming, switching to the next wallpaper, stopping playback, initialization, and opening the wallpaper website.
- Added pause/resume support and changed desktop playback to cover all available screens with the same wallpaper.
- Added single-instance protection so a second app copy activates the existing instance instead of running concurrently.
- Added optional startup restore for the last wallpaper, kept disabled by default.
- Added optional launch-at-login support through `SMAppService.mainApp`.
- Added optional low-battery monitoring. When battery power is low during playback, the app pauses first and asks the user whether to stop the wallpaper, quit the app, or continue playback.
- Added a native preferences window for startup, playback, power, and download settings.
- Simplified in-app downloads so the browser window can download directly and automatically try to import supported resources after completion.
- Redesigned the main page around a fixed-size wallpaper gallery with hover-only metadata overlays.
- Added title/tag search, automatic tag-based category filters, and local favorites.
- Added improved toolbar button styling and hover help for destructive and batch-selection actions.
- Simplified gallery overlays so wallpaper cards show only a main category, title, resolution, duration, favorite, and apply action in fixed regions.
- Kept All and Favorites fixed in the category bar, reduced categories to a few main groups, and added empty-state messaging for filters without results.
- Fixed a startup crash caused by creating `NSStatusItem` during SwiftUI App initialization by delaying status item creation until the app UI appears.

## 2026-07-09

- Added ad-hoc app signing and a static GitHub profile icon link.
- Added visible sidebar controls for single delete, batch delete, and bundled-resource reset.
- Slimmed the repository by keeping generated thumbnails and app icon outputs out of source control.
- Added batch deletion and optional delete-confirmation suppression.
- Added selected wallpaper deletion for both imported videos and bundled defaults.
- Added in-app local video import for custom dynamic wallpaper resources.
- Stabilized the Swift app window lifecycle: closing the main window now hides it, and reopening the app brings the main page back.
- Added internal DMG packaging with `make package`.
- Switched app icon generation to the project-local `Assets/AppIcon/icon.png`.
- Cleaned project structure by removing the historical crash report from source control scope.
- Kept generated build artifacts such as `.build/` and `dist/` out of Git.
- add new version
