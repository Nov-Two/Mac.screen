# Changelog

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
