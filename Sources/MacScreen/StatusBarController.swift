import AppKit
import Combine

@MainActor
final class StatusBarController: NSObject {
    private var statusItem: NSStatusItem?
    private weak var store: WallpaperStore?
    private weak var wallpaperController: WallpaperWindowController?
    private var cancellables = Set<AnyCancellable>()

    var showMainWindow: (() -> Void)?
    var importVideos: (() -> Void)?
    var restoreBundledVideos: (() -> Void)?
    var applySelectedWallpaper: (() -> Void)?
    var applyNextWallpaper: (() -> Void)?
    var stopWallpaper: (() -> Void)?
    var togglePause: (() -> Void)?
    var toggleRestoreOnLaunch: (() -> Void)?
    var toggleOpenAtLogin: (() -> Void)?
    var togglePauseOnLowBattery: (() -> Void)?
    var openWallpaperWebsite: (() -> Void)?
    var openPreferences: (() -> Void)?

    func configure(store: WallpaperStore, wallpaperController: WallpaperWindowController) {
        self.store = store
        self.wallpaperController = wallpaperController

        let statusItem = statusItem ?? NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.statusItem = statusItem
        statusItem.button?.image = NSImage(systemSymbolName: "play.rectangle.fill", accessibilityDescription: AppConfiguration.appName)
        statusItem.button?.title = " \(AppConfiguration.appName)"
        statusItem.button?.imagePosition = .imageLeading

        cancellables.removeAll()

        store.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { @MainActor in self?.rebuildMenu() }
            }
            .store(in: &cancellables)

        wallpaperController.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { @MainActor in self?.rebuildMenu() }
            }
            .store(in: &cancellables)

        rebuildMenu()
    }

    private func rebuildMenu() {
        let menu = NSMenu()
        let selectedTitle = store?.previewItem?.title
        let activeTitle = wallpaperController?.activeURL?.deletingPathExtension().lastPathComponent
        let hasItems = !(store?.items.isEmpty ?? true)
        let hasSelection = store?.previewItem != nil
        let isActive = wallpaperController?.activeURL != nil
        let isPaused = wallpaperController?.isPaused == true
        let restoresOnLaunch = store?.restoresLastWallpaperOnLaunch == true
        let opensAtLogin = store?.opensAtLogin == true
        let pausesOnLowBattery = store?.pausesOnLowBattery == true

        updateStatusButton(activeTitle: activeTitle, isPaused: isPaused)

        let statusTitle: String
        if let activeTitle {
            statusTitle = "\(isPaused ? "已暂停" : "播放中")：\(activeTitle)"
        } else if let selectedTitle {
            statusTitle = "已选择：\(selectedTitle)"
        } else {
            statusTitle = "未选择动态壁纸"
        }

        let statusMenuItem = NSMenuItem(title: statusTitle, action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)
        menu.addItem(.separator())

        menu.addItem(menuItem("显示主窗口", action: #selector(showMainWindowAction), keyEquivalent: ""))
        menu.addItem(menuItem("添加视频...", action: #selector(importVideosAction), keyEquivalent: ""))
        menu.addItem(.separator())

        let applyItem = menuItem("应用当前选择", action: #selector(applySelectedWallpaperAction), keyEquivalent: "")
        applyItem.isEnabled = hasSelection
        menu.addItem(applyItem)

        let toggleItem = menuItem(isPaused ? "继续播放" : "暂停播放", action: #selector(togglePauseAction), keyEquivalent: "")
        toggleItem.isEnabled = isActive
        menu.addItem(toggleItem)

        let nextItem = menuItem("下一个动态壁纸", action: #selector(applyNextWallpaperAction), keyEquivalent: "")
        nextItem.isEnabled = hasItems
        menu.addItem(nextItem)

        let stopItem = menuItem("停止动态壁纸", action: #selector(stopWallpaperAction), keyEquivalent: "")
        stopItem.isEnabled = isActive
        menu.addItem(stopItem)

        menu.addItem(.separator())
        menu.addItem(makeVolumeMenuItem())

        menu.addItem(.separator())
        let openAtLoginItem = menuItem("开机启动", action: #selector(toggleOpenAtLoginAction), keyEquivalent: "")
        openAtLoginItem.state = opensAtLogin ? .on : .off
        menu.addItem(openAtLoginItem)

        let restoreOnLaunchItem = menuItem("启动时恢复上次壁纸", action: #selector(toggleRestoreOnLaunchAction), keyEquivalent: "")
        restoreOnLaunchItem.state = restoresOnLaunch ? .on : .off
        menu.addItem(restoreOnLaunchItem)

        let pauseOnLowBatteryItem = menuItem("低电量时暂停并提醒", action: #selector(togglePauseOnLowBatteryAction), keyEquivalent: "")
        pauseOnLowBatteryItem.state = pausesOnLowBattery ? .on : .off
        menu.addItem(pauseOnLowBatteryItem)

        menu.addItem(.separator())
        menu.addItem(menuItem("偏好设置...", action: #selector(openPreferencesAction), keyEquivalent: ","))
        menu.addItem(menuItem("初始化资源", action: #selector(restoreBundledVideosAction), keyEquivalent: ""))
        menu.addItem(menuItem("打开壁纸网站", action: #selector(openWallpaperWebsiteAction), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(menuItem("退出 \(AppConfiguration.appName)", action: #selector(quitAction), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    private func makeVolumeMenuItem() -> NSMenuItem {
        let volume = wallpaperController?.volume ?? 0
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 176, height: 28))

        let iconName: String
        if volume == 0 {
            iconName = "speaker.slash.fill"
        } else if volume < 0.5 {
            iconName = "speaker.wave.1.fill"
        } else {
            iconName = "speaker.wave.3.fill"
        }

        let iconView = NSImageView(image: NSImage(systemSymbolName: iconName, accessibilityDescription: nil) ?? NSImage())
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.frame = NSRect(x: 8, y: 6, width: 16, height: 16)
        iconView.autoresizingMask = [.minYMargin, .maxYMargin]
        view.addSubview(iconView)

        let slider = NSSlider(value: Double(volume), minValue: 0, maxValue: 1, target: self, action: #selector(menuVolumeChanged(_:)))
        slider.controlSize = .mini
        slider.frame = NSRect(x: 30, y: 4, width: 100, height: 20)
        slider.autoresizingMask = [.minYMargin, .maxYMargin]
        view.addSubview(slider)

        let percentage = Int(volume * 100)
        let label = NSTextField(labelWithString: "\(percentage)%")
        label.font = .monospacedDigitSystemFont(ofSize: 11, weight: .medium)
        label.alignment = .right
        label.frame = NSRect(x: 136, y: 4, width: 34, height: 20)
        label.autoresizingMask = [.minYMargin, .maxYMargin]
        view.addSubview(label)

        let item = NSMenuItem()
        item.view = view
        return item
    }

    @objc private func menuVolumeChanged(_ sender: NSSlider) {
        wallpaperController?.volume = sender.floatValue
    }

    private func updateStatusButton(activeTitle: String?, isPaused: Bool) {
        guard let button = statusItem?.button else { return }

        if let activeTitle {
            button.image = NSImage(
                systemSymbolName: isPaused ? "pause.circle.fill" : "play.circle.fill",
                accessibilityDescription: AppConfiguration.appName
            )
            button.title = " \(activeTitle)"
        } else {
            button.image = NSImage(systemSymbolName: "play.rectangle.fill", accessibilityDescription: AppConfiguration.appName)
            button.title = " \(AppConfiguration.appName)"
        }
        button.imagePosition = .imageLeading
    }

    private func menuItem(_ title: String, action: Selector, keyEquivalent: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.target = self
        return item
    }

    @objc private func showMainWindowAction() {
        showMainWindow?()
    }

    @objc private func importVideosAction() {
        importVideos?()
    }

    @objc private func restoreBundledVideosAction() {
        restoreBundledVideos?()
    }

    @objc private func applySelectedWallpaperAction() {
        applySelectedWallpaper?()
    }

    @objc private func applyNextWallpaperAction() {
        applyNextWallpaper?()
    }

    @objc private func stopWallpaperAction() {
        stopWallpaper?()
    }

    @objc private func togglePauseAction() {
        togglePause?()
    }

    @objc private func toggleRestoreOnLaunchAction() {
        toggleRestoreOnLaunch?()
    }

    @objc private func toggleOpenAtLoginAction() {
        toggleOpenAtLogin?()
    }

    @objc private func togglePauseOnLowBatteryAction() {
        togglePauseOnLowBattery?()
    }

    @objc private func openWallpaperWebsiteAction() {
        openWallpaperWebsite?()
    }

    @objc private func openPreferencesAction() {
        openPreferences?()
    }

    @objc private func quitAction() {
        NSApp.terminate(nil)
    }
}
