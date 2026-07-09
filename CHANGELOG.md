# Changelog

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
